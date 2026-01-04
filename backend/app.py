from fastapi import FastAPI, UploadFile, File, Query, Form
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Dict, Optional
from dotenv import load_dotenv, dotenv_values
from pathlib import Path
from openai import OpenAI
import logging
import asyncio
import base64
import json
import os
import random
import uuid
import hashlib
from datetime import datetime, timezone

_base_dir = Path(__file__).resolve().parent
_env_path = _base_dir / ".env.runtime"
if not _env_path.exists():
    _env_path = _base_dir / ".env"
load_dotenv(dotenv_path=_env_path, override=True)

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
    source: str
    cost_estimate_usd: Optional[float] = None

FREE_DAILY_LIMIT = int(os.getenv("FREE_DAILY_LIMIT", "1"))
CALL_REAL_AI = os.getenv("CALL_REAL_AI", "false").lower() == "true"
DEFAULT_LANG = os.getenv("DEFAULT_LANG", "zh-TW")
API_KEY = os.getenv("API_KEY", "")
OPENAI_MODEL = os.getenv("OPENAI_MODEL", "gpt-4o-mini")
PRICE_INPUT_PER_M = float(os.getenv("PRICE_INPUT_PER_M", "0.15"))
PRICE_OUTPUT_PER_M = float(os.getenv("PRICE_OUTPUT_PER_M", "0.60"))

_client = OpenAI(api_key=API_KEY) if API_KEY else None
logging.basicConfig(level=logging.INFO)

_usage_dir = _base_dir / "data"
_usage_dir.mkdir(exist_ok=True)
_usage_log_path = _usage_dir / "usage.jsonl"
_daily_count_path = _usage_dir / "daily_counts.json"
_analysis_cache_path = _usage_dir / "analysis_cache.json"

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
        "下一餐建議：燙青菜＋雞胸/豆腐，主食半碗即可。",
        "下一餐建議：清湯＋蔬菜＋蛋白質（茶葉蛋/無糖豆漿）。",
        "下一餐建議：水果或無糖優格，搭配一份蔬菜沙拉。",
    ],
    "en": [
        "Next meal: vegetables + lean protein (e.g., chicken/tofu), smaller carbs.",
        "Next meal: clear soup + veggies + protein (egg, yogurt, or soy milk).",
        "Next meal: fruit or plain yogurt with a side salad.",
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
            "- macros: protein/carbs/fat/sodium 的值只能是 低/中/高\n"
            "- suggestion: 溫和、非醫療的下一餐建議，請給出具體食物類型\n"
        )
    return (
        "You are a nutrition assistant. Analyze the meal image and return JSON.\n"
        "Requirements:\n"
        "- Return JSON only (no extra text)\n"
        "- food_name: English name\n"
        "- calorie_range: e.g. '450-600 kcal'\n"
        "- macros: protein/carbs/fat/sodium values must be low/medium/high\n"
        "- suggestion: gentle next-meal advice (non-medical), include concrete food types\n"
    )


def _estimate_cost_usd(input_tokens: int, output_tokens: int) -> float:
    return round((input_tokens * PRICE_INPUT_PER_M + output_tokens * PRICE_OUTPUT_PER_M) / 1_000_000, 6)


def _append_usage(record: dict) -> None:
    line = json.dumps(record, ensure_ascii=True)
    with _usage_log_path.open("a", encoding="utf-8") as handle:
        handle.write(line + "\n")


def _load_daily_counts() -> dict:
    if not _daily_count_path.exists():
        return {}
    try:
        return json.loads(_daily_count_path.read_text(encoding="utf-8"))
    except Exception:
        return {}


def _save_daily_counts(data: dict) -> None:
    _daily_count_path.write_text(json.dumps(data, ensure_ascii=True), encoding="utf-8")


def _load_analysis_cache() -> dict:
    if not _analysis_cache_path.exists():
        return {}
    try:
        return json.loads(_analysis_cache_path.read_text(encoding="utf-8"))
    except Exception:
        return {}


def _save_analysis_cache(data: dict) -> None:
    _analysis_cache_path.write_text(json.dumps(data, ensure_ascii=True), encoding="utf-8")


def _hash_image(image_bytes: bytes) -> str:
    return hashlib.sha1(image_bytes).hexdigest()


def _should_use_ai() -> bool:
    if not CALL_REAL_AI:
        return False
    if FREE_DAILY_LIMIT <= 0:
        return True
    counts = _load_daily_counts()
    today = datetime.now(timezone.utc).date().isoformat()
    return int(counts.get(today, 0)) < FREE_DAILY_LIMIT


def _increment_daily_count() -> None:
    counts = _load_daily_counts()
    today = datetime.now(timezone.utc).date().isoformat()
    counts[today] = int(counts.get(today, 0)) + 1
    _save_daily_counts(counts)


def _analyze_with_openai(image_bytes: bytes, lang: str, food_name: str | None) -> Optional[dict]:
    if _client is None:
        return None

    prompt = _build_prompt(lang)
    if food_name:
        prompt += f"\nUser provided food name: {food_name}. Use this as the primary dish name."

    image_b64 = base64.b64encode(image_bytes).decode("utf-8")
    response = _client.chat.completions.create(
        model=OPENAI_MODEL,
        messages=[
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": prompt},
                    {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{image_b64}"}},
                ],
            }
        ],
        temperature=0.2,
    )

    text = response.choices[0].message.content or ""
    data = _parse_json(text)
    if not isinstance(data, dict):
        return None

    required = {"food_name", "calorie_range", "macros", "suggestion"}
    if not required.issubset(set(data.keys())):
        return None
    if isinstance(data.get("macros"), dict):
        data["macros"].setdefault("sodium", "中" if lang == "zh-TW" else "medium")

    usage = response.usage
    usage_data = None
    if usage is not None:
        usage_data = {
            "input_tokens": usage.prompt_tokens,
            "output_tokens": usage.completion_tokens,
            "total_tokens": usage.total_tokens,
        }
    return {"result": data, "usage": usage_data}


@app.post("/analyze", response_model=AnalysisResult)
async def analyze_image(
    image: UploadFile = File(...),
    lang: str = Query(default=None, description="Language code, e.g. zh-TW, en"),
    food_name: str = Form(default=None),
):
    image_bytes = await image.read()
    image_hash = _hash_image(image_bytes)

    use_lang = lang or DEFAULT_LANG
    if use_lang not in _fake_foods:
        use_lang = "zh-TW"

    tier = "full"
    if food_name is None:
        cache = _load_analysis_cache()
        cached = cache.get(image_hash)
        if isinstance(cached, dict) and isinstance(cached.get("result"), dict):
            cached_result = cached["result"]
            return AnalysisResult(
                food_name=cached_result.get("food_name", ""),
                calorie_range=cached_result.get("calorie_range", ""),
                macros=cached_result.get("macros", {}),
                suggestion=cached_result.get("suggestion", ""),
                tier="cached",
                source="cache",
                cost_estimate_usd=None,
            )

    use_ai = _should_use_ai()
    if use_ai and _client is not None:
        try:
            payload = await asyncio.to_thread(_analyze_with_openai, image_bytes, use_lang, food_name)
            if payload and payload.get("result"):
                usage_data = payload.get("usage") or {}
                input_tokens = int(usage_data.get("input_tokens") or 0)
                output_tokens = int(usage_data.get("output_tokens") or 0)
                cost_estimate = _estimate_cost_usd(input_tokens, output_tokens) if usage_data else None
                _append_usage(
                    {
                        "id": str(uuid.uuid4()),
                        "created_at": datetime.now(timezone.utc).isoformat(),
                        "model": OPENAI_MODEL,
                        "lang": use_lang,
                        "source": "ai",
                        "input_tokens": input_tokens,
                        "output_tokens": output_tokens,
                        "total_tokens": int(usage_data.get("total_tokens") or 0),
                        "cost_estimate_usd": cost_estimate,
                        "image_bytes": len(image_bytes),
                    }
                )
                final_name = food_name or payload["result"]["food_name"]
                _increment_daily_count()
                cache = _load_analysis_cache()
                cache[image_hash] = {
                    "saved_at": datetime.now(timezone.utc).isoformat(),
                    "result": {
                        "food_name": final_name,
                        "calorie_range": payload["result"]["calorie_range"],
                        "macros": payload["result"]["macros"],
                        "suggestion": payload["result"]["suggestion"],
                    },
                }
                _save_analysis_cache(cache)
                return AnalysisResult(
                    food_name=final_name,
                    calorie_range=payload["result"]["calorie_range"],
                    macros=payload["result"]["macros"],
                    suggestion=payload["result"]["suggestion"],
                    tier=tier,
                    source="ai",
                    cost_estimate_usd=cost_estimate,
                )
        except Exception as exc:
            logging.exception("AI analyze failed: %s", exc)

    if CALL_REAL_AI and _client is None:
        logging.warning("CALL_REAL_AI is true but API_KEY is missing.")

    if CALL_REAL_AI and not use_ai:
        tier = "lite"

    chosen_name = food_name or random.choice(_fake_foods[use_lang])
    calorie_range = random.choice(["350-450 kcal", "450-600 kcal", "600-800 kcal"])
    macros = {
        "protein": random.choice(_fake_macros[use_lang]),
        "carbs": random.choice(_fake_macros[use_lang]),
        "fat": random.choice(_fake_macros[use_lang]),
        "sodium": random.choice(_fake_macros[use_lang]),
    }
    suggestion = random.choice(_fake_suggestions[use_lang])

    return AnalysisResult(
        food_name=chosen_name,
        calorie_range=calorie_range,
        macros=macros,
        suggestion=suggestion,
        tier=tier,
        source="mock",
    )


@app.get("/health")
def health():
    file_env = dotenv_values(_env_path)
    return {
        "call_real_ai": CALL_REAL_AI,
        "api_key_set": bool(API_KEY),
        "model": OPENAI_MODEL,
        "env_path": str(_env_path),
        "file_call_real_ai": file_env.get("CALL_REAL_AI"),
        "env_call_real_ai": os.getenv("CALL_REAL_AI"),
    }


def _read_usage_records(limit: int) -> list[dict]:
    if not _usage_log_path.exists():
        return []
    with _usage_log_path.open("r", encoding="utf-8") as handle:
        lines = handle.readlines()
    records = []
    for line in reversed(lines):
        line = line.strip()
        if not line:
            continue
        try:
            records.append(json.loads(line))
        except Exception:
            continue
        if len(records) >= limit:
            break
    return records


@app.get("/usage")
def usage(limit: int = 50):
    return {"records": _read_usage_records(limit)}


@app.get("/usage/summary")
def usage_summary():
    total_cost = 0.0
    total_input = 0
    total_output = 0
    count = 0
    if _usage_log_path.exists():
        with _usage_log_path.open("r", encoding="utf-8") as handle:
            for line in handle:
                line = line.strip()
                if not line:
                    continue
                try:
                    record = json.loads(line)
                except Exception:
                    continue
                count += 1
                total_cost += float(record.get("cost_estimate_usd") or 0)
                total_input += int(record.get("input_tokens") or 0)
                total_output += int(record.get("output_tokens") or 0)
    return {
        "count": count,
        "total_cost_usd": round(total_cost, 6),
        "total_input_tokens": total_input,
        "total_output_tokens": total_output,
    }
