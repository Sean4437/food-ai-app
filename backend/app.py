from fastapi import FastAPI, UploadFile, File, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Dict, Optional
from dotenv import load_dotenv
from openai import OpenAI
import asyncio
import base64
import json
import os
import random

load_dotenv()

app = FastAPI(title="Food AI MVP")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class AnalysisResult(BaseModel):
    food_name: str
    calorie_range: str
    macros: Dict[str, str]
    suggestion: str
    tier: str

FREE_DAILY_LIMIT = int(os.getenv("FREE_DAILY_LIMIT", "1"))
CALL_REAL_AI = os.getenv("CALL_REAL_AI", "false").lower() == "true"
DEFAULT_LANG = os.getenv("DEFAULT_LANG", "zh-TW")
API_KEY = os.getenv("API_KEY", "")
OPENAI_MODEL = os.getenv("OPENAI_MODEL", "gpt-4o-mini")

_client = OpenAI(api_key=API_KEY) if API_KEY else None

_fake_foods = {
    "zh-TW": [
        "烤雞沙拉",
        "牛肉蓋飯",
        "蔬菜炒食",
        "番茄義大利麵",
        "壽司組合",
    ],
    "en": [
        "Grilled Chicken Salad",
        "Beef Rice Bowl",
        "Vegetable Stir-fry",
        "Pasta with Tomato Sauce",
        "Sushi Combo",
    ],
}

_fake_suggestions = {
    "zh-TW": [
        "下一餐：多補蔬菜與水分，份量維持適中即可。",
        "明天：以均衡餐盤為主，晚間避免加餐。",
        "若稍後還想吃，優先選水果或優格。",
    ],
    "en": [
        "Next meal: add more vegetables and water, keep portions moderate.",
        "Tomorrow: aim for a balanced plate and avoid late-night snacks.",
        "If still hungry later, choose fruit or yogurt instead of sweets.",
    ],
}

_fake_macros = {
    "zh-TW": ["低", "中", "高"],
    "en": ["low", "medium", "high"],
}


def _parse_json(text: str) -> Optional[dict]:
    try:
        return json.loads(text)
    except Exception:
        pass

    try:
        start = text.find("{")
        end = text.rfind("}")
        if start == -1 or end == -1:
            return None
        return json.loads(text[start : end + 1])
    except Exception:
        return None


def _build_prompt(lang: str) -> str:
    if lang == "zh-TW":
        return (
            "你是營養分析助理。請根據照片判斷餐點內容，回傳 JSON。\n"
            "要求：\n"
            "- 僅回傳 JSON（不要多餘文字）\n"
            "- food_name: 中文餐點名稱\n"
            "- calorie_range: 例如 '450-600 kcal'\n"
            "- macros: protein/carbs/fat 的值只能是 低/中/高\n"
            "- suggestion: 溫和、非醫療的下一餐建議\n"
        )
    return (
        "You are a nutrition assistant. Analyze the meal image and return JSON.\n"
        "Requirements:\n"
        "- Return JSON only (no extra text)\n"
        "- food_name: English name\n"
        "- calorie_range: e.g. '450-600 kcal'\n"
        "- macros: protein/carbs/fat values must be low/medium/high\n"
        "- suggestion: gentle next-meal advice (non-medical)\n"
    )


def _analyze_with_openai(image_bytes: bytes, lang: str) -> Optional[dict]:
    if _client is None:
        return None

    prompt = _build_prompt(lang)
    image_b64 = base64.b64encode(image_bytes).decode("utf-8")
    response = _client.responses.create(
        model=OPENAI_MODEL,
        input=[
            {
                "role": "user",
                "content": [
                    {"type": "input_text", "text": prompt},
                    {"type": "input_image", "image_url": f"data:image/jpeg;base64,{image_b64}"},
                ],
            }
        ],
    )

    text = response.output_text or ""
    data = _parse_json(text)
    if not isinstance(data, dict):
        return None

    required = {"food_name", "calorie_range", "macros", "suggestion"}
    if not required.issubset(set(data.keys())):
        return None

    return data


@app.post("/analyze", response_model=AnalysisResult)
async def analyze_image(
    image: UploadFile = File(...),
    lang: str = Query(default=None, description="Language code, e.g. zh-TW, en"),
):
    image_bytes = await image.read()

    use_lang = lang or DEFAULT_LANG
    if use_lang not in _fake_foods:
        use_lang = "zh-TW"

    # MVP 假邏輯：免費額度內回傳 full。
    # 未來：可依使用者每日次數降級為 lite。
    tier = "full" if FREE_DAILY_LIMIT > 0 else "lite"

    if CALL_REAL_AI and _client is not None:
        try:
            data = await asyncio.to_thread(_analyze_with_openai, image_bytes, use_lang)
            if data:
                return AnalysisResult(
                    food_name=data["food_name"],
                    calorie_range=data["calorie_range"],
                    macros=data["macros"],
                    suggestion=data["suggestion"],
                    tier=tier,
                )
        except Exception:
            pass

    food_name = random.choice(_fake_foods[use_lang])
    calorie_range = random.choice(["350-450 kcal", "450-600 kcal", "600-800 kcal"])
    macros = {
        "protein": random.choice(_fake_macros[use_lang]),
        "carbs": random.choice(_fake_macros[use_lang]),
        "fat": random.choice(_fake_macros[use_lang]),
    }
    suggestion = random.choice(_fake_suggestions[use_lang])

    return AnalysisResult(
        food_name=food_name,
        calorie_range=calorie_range,
        macros=macros,
        suggestion=suggestion,
        tier=tier,
    )
