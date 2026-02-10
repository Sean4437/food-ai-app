from fastapi import FastAPI, UploadFile, File, Query, Form, Request, Depends, HTTPException
from fastapi.responses import HTMLResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Dict, Optional, List
from dotenv import load_dotenv, dotenv_values
from pathlib import Path
from openai import OpenAI
import logging
import asyncio
import base64
import json
import os
import uuid
import hashlib
import time
from datetime import datetime, timezone, timedelta
import jwt
from jwt import PyJWKClient
import httpx

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
    macros: Dict[str, float]
    food_items: Optional[List[str]] = None
    judgement_tags: Optional[List[str]] = None
    dish_summary: Optional[str] = None
    suggestion: str
    tier: str
    source: str
    cost_estimate_usd: Optional[float] = None
    confidence: Optional[float] = None
    is_beverage: Optional[bool] = None
    is_food: Optional[bool] = None
    non_food_reason: Optional[str] = None
    debug_reason: Optional[str] = None
    reference_used: Optional[str] = None
    container_guess_type: Optional[str] = None
    container_guess_size: Optional[str] = None


class LabelResult(BaseModel):
    label_name: Optional[str] = None
    calorie_range: str
    macros: Dict[str, float]
    confidence: Optional[float] = None
    is_beverage: Optional[bool] = None
    debug_reason: Optional[str] = None


class MealSummaryInput(BaseModel):
    meal_type: str
    calorie_range: str
    dish_summaries: List[str]


class DaySummaryRequest(BaseModel):
    date: str
    meals: List[MealSummaryInput]
    day_calorie_range: Optional[str] = None
    day_meal_count: Optional[int] = None
    lang: Optional[str] = None
    profile: Optional[dict] = None
    previous_day_summary: Optional[str] = None
    previous_tomorrow_advice: Optional[str] = None
    today_consumed_kcal: Optional[int] = None
    today_remaining_kcal: Optional[int] = None


class DaySummaryResponse(BaseModel):
    day_summary: str
    tomorrow_advice: str
    source: str
    confidence: Optional[float] = None


class WeekSummaryInput(BaseModel):
    date: str
    calorie_range: str
    day_summary: str
    meal_count: int
    meal_entry_count: Optional[int] = None
    day_meal_summaries: Optional[List[str]] = None


class WeekSummaryRequest(BaseModel):
    week_start: str
    week_end: str
    days: List[WeekSummaryInput]
    lang: Optional[str] = None
    profile: Optional[dict] = None
    previous_week_summary: Optional[str] = None
    previous_next_week_advice: Optional[str] = None


class WeekSummaryResponse(BaseModel):
    week_summary: str
    next_week_advice: str
    source: str
    confidence: Optional[float] = None


class MealAdviceRequest(BaseModel):
    meal_type: str
    calorie_range: str
    dish_summaries: List[str]
    day_calorie_range: Optional[str] = None
    day_meal_count: Optional[int] = None
    day_meal_summaries: Optional[List[str]] = None
    today_consumed_kcal: Optional[int] = None
    today_remaining_kcal: Optional[int] = None
    today_macros: Optional[dict] = None
    last_meal_macros: Optional[dict] = None
    last_meal_time: Optional[str] = None
    fasting_hours: Optional[float] = None
    recent_advice: Optional[List[str]] = None
    lang: Optional[str] = None
    profile: Optional[dict] = None


class MealAdviceResponse(BaseModel):
    self_cook: str
    convenience: str
    bento: str
    other: str
    source: str
    confidence: Optional[float] = None


class ChatMessageInput(BaseModel):
    role: str
    content: str


class ChatRequest(BaseModel):
    messages: List[ChatMessageInput]
    summary: Optional[str] = None
    profile: Optional[dict] = None
    days: Optional[List[dict]] = None
    today_meals: Optional[List[dict]] = None
    context: Optional[dict] = None
    lang: Optional[str] = None


class ChatResponse(BaseModel):
    reply: str
    summary: str
    source: str
    confidence: Optional[float] = None


class NameAnalyzeRequest(BaseModel):
    food_name: str
    lang: Optional[str] = None
    profile: Optional[dict] = None
    note: Optional[str] = None
    context: Optional[str] = None
    meal_type: Optional[str] = None
    portion_percent: Optional[int] = None
    advice_mode: Optional[str] = None
    container_type: Optional[str] = None
    container_size: Optional[str] = None
    container_depth: Optional[str] = None
    container_diameter_cm: Optional[int] = None
    container_capacity_ml: Optional[int] = None

FREE_DAILY_LIMIT = int(os.getenv("FREE_DAILY_LIMIT", "1"))
CALL_REAL_AI = os.getenv("CALL_REAL_AI", "false").lower() == "true"
DEFAULT_LANG = os.getenv("DEFAULT_LANG", "zh-TW")
API_KEY = os.getenv("API_KEY", "")
OPENAI_MODEL = os.getenv("OPENAI_MODEL", "gpt-4o-mini")
PRICE_INPUT_PER_M = float(os.getenv("PRICE_INPUT_PER_M", "0.15"))
PRICE_OUTPUT_PER_M = float(os.getenv("PRICE_OUTPUT_PER_M", "0.60"))
RETURN_AI_ERROR = os.getenv("RETURN_AI_ERROR", "false").lower() == "true"
SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")
APP_DEEPLINK_URL = os.getenv("APP_DEEPLINK_URL", "foodieeye://")
TEST_BYPASS_EMAILS = {
    email.strip().lower()
    for email in os.getenv("TEST_BYPASS_EMAILS", "").split(",")
    if email.strip()
}
TRIAL_DAYS = int(os.getenv("TRIAL_DAYS", "2"))

_client = OpenAI(api_key=API_KEY) if API_KEY else None
logging.basicConfig(level=logging.INFO)
_last_ai_error: Optional[str] = None
_jwks_client: Optional[PyJWKClient] = None
_chat_rate_state: dict[str, list[float]] = {}
_chat_rate_limit = int(os.getenv("CHAT_RATE_LIMIT_PER_MIN", "5"))
_chat_rate_window_sec = int(os.getenv("CHAT_RATE_WINDOW_SEC", "60"))

_chat_blocklist = {
    "色情",
    "裸照",
    "約炮",
    "援交",
    "毒品",
    "自殺",
    "殺人",
    "炸彈",
    "詐騙",
    "賭博",
    "porn",
    "nude",
    "sex",
    "drugs",
    "suicide",
    "kill",
    "bomb",
    "scam",
    "gambling",
}


def _chat_ai_fallback_reply(lang: str) -> str:
    if lang == "zh-TW":
        return "喵嗚～我剛剛有點累，稍後再問我一次好嗎？"
    return "Meow~ I’m a bit tired right now. Please try again soon."

_usage_dir = _base_dir / "data"
_usage_dir.mkdir(exist_ok=True)
_usage_log_path = _usage_dir / "usage.jsonl"
_daily_count_path = _usage_dir / "daily_counts.json"
_analysis_cache_path = _usage_dir / "analysis_cache.json"

ANALYSIS_CACHE_TTL_DAYS = int(os.getenv("ANALYSIS_CACHE_TTL_DAYS", "30"))
ANALYSIS_CACHE_MAX = int(os.getenv("ANALYSIS_CACHE_MAX", "5000"))
USAGE_LOG_TTL_DAYS = int(os.getenv("USAGE_LOG_TTL_DAYS", "90"))
USAGE_LOG_MAX = int(os.getenv("USAGE_LOG_MAX", "10000"))

_supported_langs = {"zh-TW", "en"}



def _macro_level_to_percent(value: str) -> int:
    lower = value.lower()
    if value in ("低", "偏低") or "low" in lower:
        return 30
    if value in ("高", "偏高") or "high" in lower:
        return 80
    return 55


def _normalize_macro_value(value, key: str) -> float:
    if isinstance(value, (int, float)):
        return float(max(0, value))
    if isinstance(value, str):
        stripped = value.strip().lower()
        stripped = stripped.replace("公克", "g").replace("毫克", "mg")
        try:
            cleaned = stripped.replace("%", "").replace("kcal", "").strip()
            if "mg" in cleaned:
                num = float(cleaned.replace("mg", "").strip())
                return float(max(0, num))
            if cleaned.endswith("g"):
                num = float(cleaned.replace("g", "").strip())
                if key == "sodium":
                    return float(max(0, num * 1000))
                return float(max(0, num))
            num = float(cleaned)
            if key == "sodium" and "mg" in stripped:
                return float(max(0, num))
            return float(max(0, num))
        except Exception:
            return 0.0
    return 0.0


def _normalize_macros(data: dict, lang: str) -> dict:
    macros = data.get("macros") if isinstance(data, dict) else None
    if not isinstance(macros, dict):
        macros = {}
    macros = {
        "protein": _normalize_macro_value(macros.get("protein", 0), "protein"),
        "carbs": _normalize_macro_value(macros.get("carbs", 0), "carbs"),
        "fat": _normalize_macro_value(macros.get("fat", 0), "fat"),
        "sodium": _normalize_macro_value(macros.get("sodium", 0), "sodium"),
    }
    return macros


def _normalize_container_guess(data: dict | None) -> tuple[str, str]:
    if not isinstance(data, dict):
        return ("unknown", "none")
    raw_type = str(data.get("container_guess_type") or "").strip().lower()
    raw_size = str(data.get("container_guess_size") or "").strip().lower()
    type_map = {
        "碗": "bowl",
        "盤": "plate",
        "盤子": "plate",
        "便當盒": "box",
        "盒": "box",
        "杯": "cup",
        "飲料": "cup",
    }
    size_map = {
        "小": "small",
        "中": "medium",
        "大": "large",
        "標準": "none",
        "不分大小": "none",
        "無": "none",
        "none": "none",
    }
    if raw_type in type_map:
        raw_type = type_map[raw_type]
    if raw_size in size_map:
        raw_size = size_map[raw_size]
    valid_types = {"bowl", "plate", "box", "cup", "unknown"}
    valid_sizes = {"small", "medium", "large", "none"}
    if raw_type not in valid_types:
        raw_type = "unknown"
    if raw_size not in valid_sizes:
        raw_size = "none"
    if raw_type in {"plate", "box", "unknown"}:
        raw_size = "none"
    if raw_type in {"bowl", "cup"} and raw_size == "none":
        raw_size = "medium"
    return (raw_type, raw_size)


def _meal_type_label(meal_type: str | None, lang: str) -> str | None:
    if not meal_type:
        return None
    key = str(meal_type).strip().lower()
    if lang == "zh-TW":
        mapping = {
            "breakfast": "早餐",
            "brunch": "早午餐",
            "lunch": "午餐",
            "afternoon_tea": "下午茶",
            "dinner": "晚餐",
            "late_snack": "消夜",
            "other": "其他",
        }
        return mapping.get(key, meal_type)
    return meal_type


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


def _build_prompt(
    lang: str,
    profile: dict,
    note: str | None,
    portion_percent: int | None,
    meal_type: str | None,
    meal_photo_count: int | None,
    context: str | None,
    advice_mode: str | None,
    today_consumed_kcal: int | None,
    today_remaining_kcal: int | None,
    today_protein_g: int | None,
    label_context: str | None,
    reference_object: str | None,
    reference_length_cm: float | None,
    container_type: str | None,
    container_size: str | None,
    container_depth: str | None,
    container_diameter_cm: int | None,
    container_capacity_ml: int | None,
) -> str:
    profile_text = ""
    if profile:
        tone = str(profile.get("tone") or "").strip()
        persona = str(profile.get("persona") or "").strip()
        tone_line = f"Tone: {tone}\n" if tone else ""
        persona_line = f"Persona: {persona}\n" if persona else ""
        profile_text = (
            f"User profile (do not mention exact values): {json.dumps(profile, ensure_ascii=True)}\n"
            f"{persona_line}{tone_line}"
            "Use this only to adjust tone and suggestions. Never mention the profile values explicitly.\n"
        )
    note_text = ""
    if note:
        note_text += f"User note (do not quote directly): {note}\n"
    if portion_percent:
        note_text += f"Portion eaten: {portion_percent}% (use to scale calorie range)\n"
    context_text = ""
    if context:
        context_text = f"Recent context (use for suggestions): {context}\n"
    intake_text = ""
    if today_consumed_kcal is not None or today_remaining_kcal is not None or today_protein_g is not None:
        if lang == "zh-TW":
            parts = []
            if today_consumed_kcal is not None:
                parts.append(f"今日已吃熱量估計：{today_consumed_kcal} kcal")
            if today_remaining_kcal is not None:
                parts.append(f"今日剩餘熱量估計：{today_remaining_kcal} kcal")
            if today_protein_g is not None:
                parts.append(f"今日已吃蛋白質：{today_protein_g} g")
            intake_text = "今日累積資訊（用於調整建議，避免直接引用數字）：\n" + "；".join(parts) + "\n"
        else:
            parts = []
            if today_consumed_kcal is not None:
                parts.append(f"Today's consumed kcal: {today_consumed_kcal}")
            if today_remaining_kcal is not None:
                parts.append(f"Today's remaining kcal: {today_remaining_kcal}")
            if today_protein_g is not None:
                parts.append(f"Today's protein grams: {today_protein_g}")
            intake_text = "Today's intake (use to adjust suggestions; do not repeat exact numbers):\n" + "; ".join(parts) + "\n"
    label_text = ""
    if label_context:
        label_text = (
            f"Nutrition label info (must override calorie_range and macros if provided): {label_context}\n"
        )
    reference_text = ""
    if reference_length_cm:
        if lang == "zh-TW":
            reference_text = (
                f"參考長度（使用者量測）：{reference_length_cm} 公分。"
                "請用此長度估計份量大小。\n"
            )
        else:
            reference_text = (
                f"Reference length (user-measured): {reference_length_cm} cm. "
                "Use it to estimate portion size.\n"
            )
    elif reference_object:
        if lang == "zh-TW":
            ref_map = {
                "card": "信用卡（85.6×54 mm）",
                "coin_10": "10 元硬幣（直徑 26.5 mm）",
                "coin_5": "5 元硬幣（直徑 22 mm）",
            }
            ref_label = ref_map.get(reference_object, reference_object)
            reference_text = f"參考物：{ref_label}。請用其尺寸估計份量大小。\n"
        else:
            ref_map = {
                "card": "credit card (85.6×54 mm)",
                "coin_10": "coin 26.5 mm diameter",
                "coin_5": "coin 22 mm diameter",
            }
            ref_label = ref_map.get(reference_object, reference_object)
            reference_text = f"Reference object: {ref_label}. Use it to estimate portion size.\n"
    container_text = ""
    if (
        container_type
        or container_size
        or container_depth
        or container_diameter_cm
        or container_capacity_ml
    ):
        container_text = (
            "Container info (use to estimate portion size): "
            f"type={container_type or 'unknown'}, "
            f"size={container_size or 'unknown'}, "
            f"depth={container_depth or 'unknown'}, "
            f"diameter_cm={container_diameter_cm or 'unknown'}, "
            f"capacity_ml={container_capacity_ml or 'unknown'}\n"
        )
    meal_text = ""
    if meal_type:
        meal_key = str(meal_type).strip().lower()
        meal_label = _meal_type_label(meal_type, lang) or meal_type
        if lang == "zh-TW":
            meal_text = f"餐次：{meal_label}\n"
            if meal_key in ("dinner", "late_snack"):
                meal_text += "若為晚餐或消夜，建議提醒避免夜間加餐。\n"
        else:
            meal_text = f"Meal type: {meal_label}\n"
            if meal_key in ("dinner", "late_snack"):
                meal_text += "If this is dinner or a late-night snack, suggest avoiding additional late-night eating.\n"
    if meal_photo_count and meal_photo_count > 1:
        if lang == "zh-TW":
            meal_text += f"此餐共有 {meal_photo_count} 張照片，請以整餐為單位輸出結果。\n"
        else:
            meal_text += f"This meal has {meal_photo_count} photos; summarize at the whole-meal level.\n"
    if lang == "zh-TW":
        suggestion_rule = (
            "- suggestion: 針對下一餐的建議，輸出三行格式：搭配 / 不建議 / 建議份量\n"
            "- 需包含具體食物類型與份量描述（例：主食半碗、蛋白質一掌、蔬菜一碗）\n"
            "- 每行冒號後請直接給自然短句或片語，避免重複「可以/建議/避免/份量」字眼，避免以「搭配/避免/份量」開頭\n"
        )
        suggestion_example = (
            "  \"suggestion\": \"搭配：蔬菜多一點、清淡蛋白質\\n不建議：油炸或高糖飲品\\n建議份量：主食半碗、蛋白質一掌\",\n"
        )
        if advice_mode == "current_meal":
            suggestion_rule = (
                "- suggestion: 針對這一餐怎麼吃比較好，輸出三行格式：搭配 / 不建議 / 建議份量\n"
                "- 若 recent context 有上一餐資訊，請簡短提到；若沒有可省略\n"
                "- 每行冒號後請直接給自然短句或片語，避免重複「可以/建議/避免/份量」字眼，避免以「搭配/避免/份量」開頭\n"
            )
            suggestion_example = (
                "  \"suggestion\": \"搭配：蔬菜多一點，肉量減少\\n不建議：湯底與加工配料\\n建議份量：主食半碗、蛋白質一掌（上一餐偏油，所以這餐清淡一點）\",\n"
            )
        return (
            "你是營養分析助理。請根據照片判斷餐點內容，回傳 JSON。\n"
            "要求：\n"
            "- 僅回傳 JSON（不要多餘文字）\n"
            "- food_name: 中文餐點名稱\n"
            "- food_items: 1-5 個食物名稱（列出看得到的主要食物）\n"
            "- calorie_range: 例如 '450-600 kcal'（區間寬度控制在 120-200 kcal，飲料 <= 120）\n"
            "- macros: protein/carbs/fat 為克數(g)，sodium 為毫克(mg)，以此餐份量估算（不要用百分比）\n"
            "- judgement_tags: 從 [偏油, 清淡, 碳水偏多, 蛋白不足] 選 1-3 個\n"
            "- dish_summary: 20 字內一句話摘要\n"
            "- 規則：自然口語，不要專業營養名詞，不要出現數字/熱量/克數，不責備不命令\n"
            "- 描述整體負擔、口味或營養重點，留空間給下一餐建議\n"
            "- 結構參考：整體感受 + 一個主要特徵 + 輕微提醒\n"
            f"{suggestion_rule}"
            "- confidence: 0 到 1 的信心分數\n"
            "- is_beverage: 是否為飲料（true/false）\n"
            "- is_food: 是否為食物（true/false；若不是食物請填 false）\n"
            "- non_food_reason: 若不是食物，簡短原因\n"
            "- reference_used: 若照片中有可用參考物（信用卡/硬幣/手機/筷子/叉子/湯匙/手掌/鋁罐/寶特瓶等），請寫出你用來估算份量的參考物；若沒有請填「無」\n"
            "- 若提供參考長度，reference_used 請寫「測距 {公分}cm」\n"
            "- 若有多個參考物，請選最清楚且最接近食物的那一個\n"
            "- container_guess_type: 容器推測類型（bowl/plate/box/cup/unknown）\n"
            "- container_guess_size: 容器推測尺寸（small/medium/large/none）\n"
            "- 若為盤/盒/unknown，尺寸請用 none；若為飲料優先用 cup\n"
            "- 湯/粥/冰品/零食皆算食物\n"
            "- 酒精飲料（啤酒/紅酒/調酒）屬於飲料，也算食物\n"
            "- 保健品/藥品/維他命不算食物，is_food 請填 false\n"
            "- 醬料/抹醬/油脂若可食，需計入熱量\n"
            "- 飲料規則：若為飲料，protein/fat 請偏低（約 <= 3g），熱量偏低；含糖可提升 carbs\n"
            "- 若使用者提供 food_name，必須優先採用\n"
            "- 若提供 nutrition label info，必須使用其 calorie_range 與 macros\n"
            "- 避免醫療或診斷字眼；避免精準數值或克數，維持區間與語意描述\n"
            "- 若提供參考長度，優先使用；若畫面中有硬幣/信用卡等可辨識參考物，也可作為估算依據；無則使用一般估計\n"
            "JSON 範例：\n"
            "{\n"
            "  \"food_name\": \"牛肉便當\",\n"
            "  \"food_items\": [\"白飯\", \"牛肉\", \"青菜\"],\n"
            "  \"calorie_range\": \"650-850 kcal\",\n"
            "  \"macros\": {\"protein\": 35, \"carbs\": 90, \"fat\": 25, \"sodium\": 900},\n"
            "  \"judgement_tags\": [\"偏油\", \"蛋白不足\"],\n"
            "  \"dish_summary\": \"油脂偏多、蛋白足夠\",\n"
            f"{suggestion_example}"
            "  \"confidence\": 0.72,\n"
            "  \"is_beverage\": false,\n"
            "  \"is_food\": true,\n"
            "  \"non_food_reason\": \"\",\n"
            "  \"reference_used\": \"10 元硬幣\",\n"
            "  \"container_guess_type\": \"bowl\",\n"
            "  \"container_guess_size\": \"medium\"\n"
            "}\n"
        ) + profile_text + note_text + context_text + intake_text + label_text + reference_text + container_text + meal_text
    suggestion_rule = (
        "- suggestion: next meal guidance, formatted as three lines: Can eat / Avoid / Portion limit\n"
        "- Include concrete food types and portion guidance (e.g. half bowl carbs, palm-sized protein, one bowl veggies)\n"
        "- After each label, write a natural phrase that reads smoothly; do not repeat 'can/avoid/portion' or start with 'avoid/portion'\n"
    )
    suggestion_example = (
        "  \"suggestion\": \"Can eat: more veggies and lean protein\\nAvoid: fried foods or sugary drinks\\nPortion limit: half bowl carbs, palm-sized protein\",\n"
    )
    if advice_mode == "current_meal":
        suggestion_rule = (
            "- suggestion: guidance for how to eat this meal, formatted as three lines: Can eat / Avoid / Portion limit\n"
            "- If recent context includes previous meal info, mention it briefly; otherwise omit\n"
            "- After each label, write a natural phrase that reads smoothly; do not repeat 'can/avoid/portion' or start with 'avoid/portion'\n"
        )
        suggestion_example = (
            "  \"suggestion\": \"Can eat: more veggies and lean protein\\nAvoid: broth and processed sides\\nPortion limit: half bowl carbs, palm-sized protein (previous meal was heavier, so keep it light)\",\n"
        )
    return (
        "You are a nutrition assistant. Analyze the meal image and return JSON.\n"
        "Requirements:\n"
        "- Return JSON only (no extra text)\n"
        "- food_name: English name\n"
        "- food_items: 1-5 primary items visible in the meal\n"
        "- calorie_range: e.g. '450-600 kcal' (keep range width 120-200 kcal; beverage <= 120)\n"
        "- macros: protein/carbs/fat are grams (g), sodium is milligrams (mg) for this portion (no percentages)\n"
        "- judgement_tags: choose 1-3 from [Heavier oil, Light, Higher carbs, Low protein]\n"
        "- dish_summary: single-sentence summary (<= 20 words)\n"
        "- Rules: natural language, avoid technical nutrition terms, no numbers/calories/grams, no scolding or commands\n"
        "- Describe overall burden, taste, or a key nutrition cue, leaving room for next-meal advice\n"
        "- Structure hint: overall feel + one main trait + gentle reminder\n"
        f"{suggestion_rule}"
        "- confidence: 0 to 1 confidence score\n"
        "- is_beverage: true/false\n"
        "- is_food: true/false (set false if not food)\n"
        "- non_food_reason: brief reason if not food\n"
        "- reference_used: if a reference object is visible (credit card/coin/phone/chopsticks/fork/spoon/hand/can/bottle), state what you used to estimate portion size; otherwise use \"none\"\n"
        "- If reference length is provided, set reference_used to \"measured {cm}cm\"\n"
        "- If multiple reference objects appear, choose the clearest one closest to the food\n"
        "- container_guess_type: container type guess (bowl/plate/box/cup/unknown)\n"
        "- container_guess_size: container size guess (small/medium/large/none)\n"
        "- If plate/box/unknown, size must be none; if beverage, prefer cup\n"
        "- Soup/porridge/ice desserts/snacks are food\n"
        "- Alcoholic drinks (beer/wine/cocktails) are beverages and count as food\n"
        "- Supplements/medicine/vitamins are not food; set is_food=false\n"
        "- Edible sauces/spreads/oils should be counted toward calories\n"
        "- Beverage rule: if beverage, protein/fat should be low (around <= 3g); calories should be low; sugary drinks may increase carbs\n"
        "- If user provides food_name, it must be used as the primary name\n"
        "- If nutrition label info is provided, you must use its calorie_range and macros\n"
        "- Avoid medical/diagnosis language; avoid precise numbers/grams\n"
        "- If a reference length is provided, use it first; otherwise use any visible coin/credit card as a reference if clear\n"
        "JSON example:\n"
        "{\n"
        "  \"food_name\": \"beef bento\",\n"
        "  \"food_items\": [\"rice\", \"beef\", \"vegetables\"],\n"
        "  \"calorie_range\": \"650-850 kcal\",\n"
        "  \"macros\": {\"protein\": 35, \"carbs\": 90, \"fat\": 25, \"sodium\": 900},\n"
        "  \"judgement_tags\": [\"Heavier oil\", \"Low protein\"],\n"
        "  \"dish_summary\": \"Heavier oil, decent protein\",\n"
        f"{suggestion_example}"
        "  \"confidence\": 0.72,\n"
        "  \"is_beverage\": false,\n"
        "  \"is_food\": true,\n"
        "  \"non_food_reason\": \"\",\n"
        "  \"reference_used\": \"credit card\",\n"
        "  \"container_guess_type\": \"bowl\",\n"
        "  \"container_guess_size\": \"medium\"\n"
        "}\n"
    ) + profile_text + note_text + context_text + intake_text + label_text + reference_text + container_text + meal_text


def _build_name_prompt(
    lang: str,
    profile: dict,
    food_name: str,
    note: str | None,
    portion_percent: int | None,
    meal_type: str | None,
    context: str | None,
    advice_mode: str | None,
    container_type: str | None,
    container_size: str | None,
    container_depth: str | None,
    container_diameter_cm: int | None,
    container_capacity_ml: int | None,
) -> str:
    profile_text = ""
    if profile:
        tone = str(profile.get("tone") or "").strip()
        persona = str(profile.get("persona") or "").strip()
        tone_line = f"Tone: {tone}\n" if tone else ""
        persona_line = f"Persona: {persona}\n" if persona else ""
        profile_text = (
            f"User profile (do not mention exact values): {json.dumps(profile, ensure_ascii=True)}\n"
            f"{persona_line}{tone_line}"
            "Use this only to adjust tone and suggestions. Never mention the profile values explicitly.\n"
        )
    note_text = ""
    if note:
        note_text += f"User note (do not quote directly): {note}\n"
    if portion_percent:
        note_text += f"Portion eaten: {portion_percent}% (use to scale calorie range)\n"
    context_text = ""
    if context:
        context_text = f"Recent context (use for suggestions): {context}\n"
    container_text = ""
    if (
        container_type
        or container_size
        or container_depth
        or container_diameter_cm
        or container_capacity_ml
    ):
        container_text = (
            "Container info (use to estimate portion size): "
            f"type={container_type or 'unknown'}, "
            f"size={container_size or 'unknown'}, "
            f"depth={container_depth or 'unknown'}, "
            f"diameter_cm={container_diameter_cm or 'unknown'}, "
            f"capacity_ml={container_capacity_ml or 'unknown'}\n"
        )
    meal_text = ""
    if meal_type:
        meal_key = str(meal_type).strip().lower()
        meal_label = _meal_type_label(meal_type, lang) or meal_type
        if lang == "zh-TW":
            meal_text = f"餐次：{meal_label}\n"
            if meal_key in ("dinner", "late_snack"):
                meal_text += "若為晚餐或消夜，建議提醒避免夜間加餐。\n"
        else:
            meal_text = f"Meal type: {meal_label}\n"
            if meal_key in ("dinner", "late_snack"):
                meal_text += "If this is dinner or a late-night snack, suggest avoiding additional late-night eating.\n"
    if lang == "zh-TW":
        suggestion_rule = (
            "- suggestion: 針對這一餐怎麼吃比較好，輸出三行格式：搭配 / 不建議 / 建議份量\n"
            "- 若 recent context 有上一餐資訊，請簡短提到；若沒有可省略\n"
            "- 每行冒號後請直接給自然短句或片語，避免重複「可以/建議/避免/份量」字眼，避免以「搭配/避免/份量」開頭\n"
        )
        suggestion_example = (
            "  \"suggestion\": \"搭配：蔬菜多一點，肉量減少\\n不建議：湯底與加工配料\\n建議份量：主食半碗、蛋白質一掌（上一餐偏油，所以這餐清淡一點）\",\n"
        )
        if advice_mode != "current_meal":
            suggestion_rule = (
                "- suggestion: 針對下一餐的建議，輸出三行格式：搭配 / 不建議 / 建議份量\n"
                "- 需包含具體食物類型與份量描述（例：主食半碗、蛋白質一掌、蔬菜一碗）\n"
                "- 每行冒號後請直接給自然短句或片語，避免重複「可以/建議/避免/份量」字眼，避免以「搭配/避免/份量」開頭\n"
            )
            suggestion_example = (
                "  \"suggestion\": \"搭配：蔬菜多一點、清淡蛋白質\\n不建議：油炸或高糖飲品\\n建議份量：主食半碗、蛋白質一掌\",\n"
            )
        return (
            "你是營養分析助理。請根據食物名稱估算內容，回傳 JSON。\n"
            "注意：沒有照片，只能根據名稱估算。\n"
            "要求：\n"
            "- 僅回傳 JSON（不要多餘文字）\n"
            "- food_name: 中文餐點名稱（必須使用提供的名稱）\n"
            "- food_items: 1-5 個食物名稱（用名稱推測主要食物）\n"
            "- calorie_range: 例如 '450-600 kcal'（區間寬度控制在 120-200 kcal，飲料 <= 120）\n"
            "- macros: protein/carbs/fat 為克數(g)，sodium 為毫克(mg)，以此餐份量估算（不要用百分比）\n"
            "- judgement_tags: 從 [偏油, 清淡, 碳水偏多, 蛋白不足] 選 1-3 個\n"
            "- dish_summary: 20 字內一句話摘要\n"
            "- 規則：自然口語，不要專業營養名詞，不要出現數字/熱量/克數，不責備不命令\n"
            "- 描述整體負擔、口味或營養重點，留空間給下一餐建議\n"
            f"{suggestion_rule}"
            "- confidence: 0 到 1 的信心分數\n"
            "- is_beverage: 是否為飲料（true/false）\n"
            "- is_food: 是否為食物（true/false；若不是食物請填 false）\n"
            "- non_food_reason: 若不是食物，簡短原因\n"
            "- container_guess_type: 容器推測類型（bowl/plate/box/cup/unknown）\n"
            "- container_guess_size: 容器推測尺寸（small/medium/large/none）\n"
            "- 若為盤/盒/unknown，尺寸請用 none；若為飲料優先用 cup\n"
            "- 湯/粥/冰品/零食皆算食物\n"
            "- 酒精飲料（啤酒/紅酒/調酒）屬於飲料，也算食物\n"
            "- 保健品/藥品/維他命不算食物，is_food 請填 false\n"
            "- 醬料/抹醬/油脂若可食，需計入熱量\n"
            "- 飲料規則：若為飲料，protein/fat 請偏低（約 <= 3g），熱量偏低；含糖可提升 carbs\n"
            "JSON 範例：\n"
            "{\n"
            f"  \"food_name\": \"{food_name}\",\n"
            "  \"food_items\": [\"白飯\", \"牛肉\", \"青菜\"],\n"
            "  \"calorie_range\": \"650-850 kcal\",\n"
            "  \"macros\": {\"protein\": 35, \"carbs\": 90, \"fat\": 25, \"sodium\": 900},\n"
            "  \"judgement_tags\": [\"偏油\", \"蛋白不足\"],\n"
            "  \"dish_summary\": \"油脂偏多、蛋白足夠\",\n"
            f"{suggestion_example}"
            "  \"confidence\": 0.72,\n"
            "  \"is_beverage\": false,\n"
            "  \"is_food\": true,\n"
            "  \"non_food_reason\": \"\",\n"
            "  \"container_guess_type\": \"bowl\",\n"
            "  \"container_guess_size\": \"medium\"\n"
            "}\n"
        ) + profile_text + note_text + context_text + container_text + meal_text
    suggestion_rule = (
        "- suggestion: guidance for how to eat this meal, formatted as three lines: Can eat / Avoid / Portion limit\n"
        "- If recent context includes previous meal info, mention it briefly; otherwise omit\n"
        "- After each label, write a natural phrase that reads smoothly; do not repeat 'can/avoid/portion' or start with 'avoid/portion'\n"
    )
    suggestion_example = (
        "  \"suggestion\": \"Can eat: more veggies and lean protein\\nAvoid: broth and processed sides\\nPortion limit: half bowl carbs, palm-sized protein (previous meal was heavier, so keep it light)\",\n"
    )
    if advice_mode != "current_meal":
        suggestion_rule = (
            "- suggestion: next meal guidance, formatted as three lines: Can eat / Avoid / Portion limit\n"
            "- Include concrete food types and portion guidance (e.g. half bowl carbs, palm-sized protein, one bowl veggies)\n"
            "- After each label, write a natural phrase that reads smoothly; do not repeat 'can/avoid/portion' or start with 'avoid/portion'\n"
        )
        suggestion_example = (
            "  \"suggestion\": \"Can eat: more veggies and lean protein\\nAvoid: fried foods or sugary drinks\\nPortion limit: half bowl carbs, palm-sized protein\",\n"
        )
    return (
        "You are a nutrition assistant. Estimate based on food name and return JSON.\n"
        "Note: there is no photo, estimate from the name only.\n"
        "Requirements:\n"
        "- Return JSON only\n"
        f"- food_name: must use provided name ({food_name})\n"
        "- food_items: 1-5 primary items inferred from the name\n"
        "- calorie_range: e.g. '450-600 kcal' (keep range width 120-200 kcal; beverage <= 120)\n"
        "- macros: protein/carbs/fat are grams (g), sodium is milligrams (mg) for this portion (no percentages)\n"
        "- judgement_tags: choose 1-3 from [Heavier oil, Light, Higher carbs, Low protein]\n"
        "- dish_summary: single-sentence summary (<= 20 words)\n"
        "- Rules: natural language, avoid technical nutrition terms, no numbers/calories/grams, no scolding or commands\n"
        f"{suggestion_rule}"
        "- confidence: 0 to 1\n"
        "- is_beverage: true/false\n"
        "- is_food: true/false (set false if not food)\n"
        "- non_food_reason: brief reason if not food\n"
        "- container_guess_type: container type guess (bowl/plate/box/cup/unknown)\n"
        "- container_guess_size: container size guess (small/medium/large/none)\n"
        "- If plate/box/unknown, size must be none; if beverage, prefer cup\n"
        "- Soup/porridge/ice desserts/snacks are food\n"
        "- Alcoholic drinks (beer/wine/cocktails) are beverages and count as food\n"
        "- Supplements/medicine/vitamins are not food; set is_food=false\n"
        "- Edible sauces/spreads/oils should be counted toward calories\n"
        "- Beverage rule: if beverage, protein/fat should be low (around <= 3g); calories should be low; sugary drinks may increase carbs\n"
        "JSON example:\n"
        "{\n"
        f"  \"food_name\": \"{food_name}\",\n"
        "  \"food_items\": [\"rice\", \"beef\", \"vegetables\"],\n"
        "  \"calorie_range\": \"650-850 kcal\",\n"
        "  \"macros\": {\"protein\": 35, \"carbs\": 90, \"fat\": 25, \"sodium\": 900},\n"
        "  \"judgement_tags\": [\"Heavier oil\", \"Low protein\"],\n"
        "  \"dish_summary\": \"Heavier oil, decent protein\",\n"
        f"{suggestion_example}"
        "  \"confidence\": 0.72,\n"
        "  \"is_beverage\": false,\n"
        "  \"is_food\": true,\n"
        "  \"non_food_reason\": \"\",\n"
        "  \"container_guess_type\": \"bowl\",\n"
        "  \"container_guess_size\": \"medium\"\n"
        "}\n"
    ) + profile_text + note_text + context_text + container_text + meal_text




def _supabase_headers() -> dict:
    if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
        raise HTTPException(status_code=500, detail="supabase_not_configured")
    return {
        "apikey": SUPABASE_SERVICE_ROLE_KEY,
        "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
        "Content-Type": "application/json",
    }


def _get_jwks_client() -> PyJWKClient:
    global _jwks_client
    if _jwks_client is not None:
        return _jwks_client
    if not SUPABASE_URL:
        raise HTTPException(status_code=500, detail="supabase_not_configured")
    jwks_url = f"{SUPABASE_URL}/auth/v1/.well-known/jwks.json"
    _jwks_client = PyJWKClient(jwks_url)
    return _jwks_client


def _decode_bearer_token(token: str) -> dict:
    jwks_client = _get_jwks_client()
    signing_key = jwks_client.get_signing_key_from_jwt(token)
    header = jwt.get_unverified_header(token)
    alg = header.get("alg") or "RS256"
    allowed = {"RS256", "ES256"}
    if alg not in allowed:
        raise HTTPException(status_code=401, detail="invalid_token_alg")
    return jwt.decode(
        token,
        signing_key.key,
        algorithms=[alg],
        audience="authenticated",
        issuer=f"{SUPABASE_URL}/auth/v1",
    )


def _trial_start_from_profile(user_id: str) -> Optional[datetime]:
    headers = _supabase_headers()
    url = f"{SUPABASE_URL}/rest/v1/profiles?id=eq.{user_id}&select=trial_start"
    with httpx.Client(timeout=10) as client:
        resp = client.get(url, headers=headers)
    if resp.status_code >= 400:
        logging.error("Supabase profiles fetch failed: %s", resp.text)
        raise HTTPException(status_code=500, detail="profile_fetch_failed")
    data = resp.json()
    if not data:
        return None
    raw = data[0].get("trial_start")
    if not raw:
        return None
    try:
        return datetime.fromisoformat(raw.replace("Z", "+00:00"))
    except Exception:
        return None


def _upsert_profile_trial(user_id: str, email: str, trial_start: datetime) -> None:
    headers = _supabase_headers()
    headers["Prefer"] = "resolution=merge-duplicates"
    payload = [{
        "id": user_id,
        "email": email,
        "trial_start": trial_start.isoformat(),
    }]
    url = f"{SUPABASE_URL}/rest/v1/profiles"
    with httpx.Client(timeout=10) as client:
        resp = client.post(url, headers=headers, json=payload)
    if resp.status_code >= 400:
        logging.error("Supabase profiles upsert failed: %s", resp.text)
        raise HTTPException(status_code=500, detail="profile_upsert_failed")


def _ensure_trial_start(user_id: str, email: str) -> datetime:
    trial_start = _trial_start_from_profile(user_id)
    if trial_start is None:
        trial_start = datetime.now(timezone.utc)
        _upsert_profile_trial(user_id, email, trial_start)
    return trial_start


def _is_whitelisted(email: str) -> bool:
    return email.strip().lower() in TEST_BYPASS_EMAILS


def _require_auth(request: Request) -> dict:
    auth_header = request.headers.get("authorization") or request.headers.get("Authorization")
    if not auth_header or not auth_header.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="missing_token")
    token = auth_header.split(" ", 1)[1].strip()
    if not token:
        raise HTTPException(status_code=401, detail="missing_token")
    try:
        payload = _decode_bearer_token(token)
    except Exception as exc:
        logging.exception("Token decode failed: %s", exc)
        raise HTTPException(status_code=401, detail="invalid_token")
    user_id = payload.get("sub") or ""
    email = payload.get("email") or ""
    if not user_id or not email:
        raise HTTPException(status_code=401, detail="invalid_token")
    if _is_whitelisted(email):
        return {"user_id": user_id, "email": email, "whitelisted": True}
    trial_start = _ensure_trial_start(user_id, email)
    if datetime.now(timezone.utc) - trial_start > timedelta(days=TRIAL_DAYS):
        raise HTTPException(status_code=402, detail="trial_expired")
    return {"user_id": user_id, "email": email, "whitelisted": False, "trial_start": trial_start}


def _build_day_prompt(
    lang: str,
    profile: dict | None,
    meals: List[MealSummaryInput],
    day_calorie_range: Optional[str],
    day_meal_count: Optional[int],
    previous_day_summary: Optional[str],
    previous_tomorrow_advice: Optional[str],
    today_consumed_kcal: Optional[int],
    today_remaining_kcal: Optional[int],
) -> str:
    profile_text = ""
    if profile:
        tone = str(profile.get("tone") or "").strip()
        persona = str(profile.get("persona") or "").strip()
        tone_line = f"Tone: {tone}\n" if tone else ""
        persona_line = f"Persona: {persona}\n" if persona else ""
        profile_text = (
            f"User profile (do not mention exact values): {json.dumps(profile, ensure_ascii=True)}\n"
            f"{persona_line}{tone_line}"
            "Use this only to adjust tone and suggestions. Never mention the profile values explicitly.\n"
        )
    meal_lines = []
    for meal in meals:
        label = _meal_type_label(meal.meal_type, lang) or meal.meal_type
        if lang == "zh-TW":
            summaries = "；".join(meal.dish_summaries) if meal.dish_summaries else "無摘要"
            meal_lines.append(f"- {label}：{meal.calorie_range}｜{summaries}")
        else:
            summaries = "; ".join(meal.dish_summaries) if meal.dish_summaries else "no summary"
            meal_lines.append(f"- {label}: {meal.calorie_range} | {summaries}")
    meal_block = "\n".join(meal_lines)
    day_intake_context = ''
    if today_consumed_kcal is not None or today_remaining_kcal is not None:
        day_intake_context = (
            f'今日已吃熱量估計：{today_consumed_kcal if today_consumed_kcal is not None else "未知"} kcal\n'
            f'今日剩餘熱量估計：{today_remaining_kcal if today_remaining_kcal is not None else "未知"} kcal\n'
        )
    history_lines = []
    if previous_day_summary:
        history_lines.append(f"Previous day summary: {previous_day_summary}")
    if previous_tomorrow_advice:
        history_lines.append(f"Previous tomorrow advice: {previous_tomorrow_advice}")
    history_block = "\n".join(history_lines)
    if lang == "zh-TW":
        return (
            "你是營養分析助理。請根據當日多餐摘要，輸出今日總結與明天建議，回傳 JSON。\n"
            "要求：\n"
            "- 僅回傳 JSON（不要多餘文字）\n"
            "- day_summary: 一句話總結（30 字內），描述「今天狀態」\n"
            "- tomorrow_advice: 一句話建議「下一餐/明天行動」\n"
            "- confidence: 0 到 1 的信心分數\n"
            "- 避免醫療或診斷字眼；避免精準數值或克數\n"
            "- day_summary 與 tomorrow_advice 不得重複詞句或同義改寫\n"
            "- 避免與「前一天 summary/advice」重複或高度相似\n- 若今日已超量（今日剩餘熱量 <= 0），tomorrow_advice 必須勸戒、避免再進食\n- 若今日晚餐已吃且已接近上限，tomorrow_advice 應以清淡/不吃宵夜為主\n"
            "- 避免重複句型與開頭（例如不要連續多天以「今日飲食…」開頭）\n"
            "- 句子要有變化：可交替使用「描述現況 / 點出缺口 / 給方向」等語氣\n"
            "JSON 範例：\n"
            "{\n"
            "  \"day_summary\": \"整體均衡，油脂略多\",\n"
            "  \"tomorrow_advice\": \"明天以清淡蛋白質與蔬菜為主\",\n"
            "  \"confidence\": 0.7\n"
            "}\n"
            f"今日累計熱量區間：{day_calorie_range or '未知'}\n"
            f"今日已記錄餐數：{day_meal_count or 0}\n"
            f"餐次摘要：\n{meal_block}\n"
            f"{day_intake_context}"
            f"{history_block}\n"
        ) + profile_text
    return (
        "You are a nutrition assistant. Based on day meal summaries, return JSON.\n"
        "Requirements:\n"
        "- Return JSON only\n"
        "- day_summary: one-sentence summary (<= 30 words) describing today's status\n"
        "- tomorrow_advice: one sentence guidance for the next meal/tomorrow action\n"
        "- confidence: 0 to 1\n"
        "- Avoid medical/diagnosis language; avoid precise numbers/grams\n"
        "- Do not repeat phrases between day_summary and tomorrow_advice\n"
        "- Avoid repeating or paraphrasing the previous day summary/advice\n- If today_remaining_kcal <= 0: tomorrow_advice must discourage further eating\n- If dinner already eaten and intake near limit, focus on light/no late snack\n"
        "- Avoid repeating the same sentence pattern or starting phrase across days\n"
        "- Vary tone/structure (status / gap / action) instead of one template\n"
        "JSON example:\n"
        "{\n"
        "  \"day_summary\": \"Overall balanced, slightly higher fat\",\n"
        "  \"tomorrow_advice\": \"Aim for lean protein and more vegetables\",\n"
        "  \"confidence\": 0.7\n"
        "}\n"
        f"Today total range: {day_calorie_range or 'unknown'}\n"
        f"Meals today: {day_meal_count or 0}\n"
        f"Meal summaries:\n{meal_block}\n"
        f"{day_intake_context}"
        f"{history_block}\n"
    ) + profile_text


def _build_week_prompt(
    lang: str,
    profile: dict | None,
    days: List[WeekSummaryInput],
    week_start: str,
    week_end: str,
    previous_week_summary: Optional[str],
    previous_next_week_advice: Optional[str],
) -> str:
    profile_text = ""
    if profile:
        tone = str(profile.get("tone") or "").strip()
        persona = str(profile.get("persona") or "").strip()
        tone_line = f"Tone: {tone}\n" if tone else ""
        persona_line = f"Persona: {persona}\n" if persona else ""
        profile_text = (
            f"User profile (do not mention exact values): {json.dumps(profile, ensure_ascii=True)}\n"
            f"{persona_line}{tone_line}"
            "Use this only to adjust tone and suggestions. Never mention the profile values explicitly.\n"
        )
    day_lines = []
    for day in days:
        summary = day.day_summary or ("無摘要" if lang == "zh-TW" else "no summary")
        entry_count = day.meal_entry_count or day.meal_count
        if lang == "zh-TW":
            line = f"- {day.date}: {day.calorie_range} | {summary} | 餐數={day.meal_count}，記錄={entry_count}"
        else:
            line = f"- {day.date}: {day.calorie_range} | {summary} | meals={day.meal_count}, entries={entry_count}"
        if day.day_meal_summaries:
            meal_text = "；".join([s for s in day.day_meal_summaries if s]) if lang == "zh-TW" else "; ".join([s for s in day.day_meal_summaries if s])
            if meal_text:
                line += f" | 餐次細節：{meal_text}" if lang == "zh-TW" else f" | details: {meal_text}"
        day_lines.append(line)
    day_block = "\n".join(day_lines)
    history_lines = []
    if previous_week_summary:
        history_lines.append(f"Previous week summary: {previous_week_summary}")
    if previous_next_week_advice:
        history_lines.append(f"Previous next week advice: {previous_next_week_advice}")
    history_block = "\n".join(history_lines)
    if lang == "zh-TW":
        return (
            "你是營養分析助理。請根據一週摘要，輸出週總結與下週建議，回傳 JSON。\n"
            "要求：\n"
            "- 僅回傳 JSON（不要多餘文字）\n"
            "- week_summary: 一句話總結（40 字內），描述「本週狀態」\n"
            "- next_week_advice: 一句話建議「下週行動方向」\n"
            "- confidence: 0 到 1 的信心分數\n"
            "- 避免醫療或診斷字眼；避免精準數值或克數\n"
            "- week_summary 與 next_week_advice 不得重複詞句或同義改寫\n"
            "- 避免與「上一週 summary/advice」重複或高度相似\n"
            "- 避免與前週使用相同開頭或句型\n"
            "JSON 範例：\n"
            "{\n"
            "  \"week_summary\": \"整體均衡但油脂偏高，注意蔬菜比例\",\n"
            "  \"next_week_advice\": \"下週以清淡蛋白質與蔬菜為主\",\n"
            "  \"confidence\": 0.7\n"
            "}\n"
            f"週期：{week_start} ~ {week_end}\n"
            f"每日摘要：\n{day_block}\n"
            f"{history_block}\n"
        ) + profile_text
    return (
        "You are a nutrition assistant. Based on weekly summaries, return JSON.\n"
        "Requirements:\n"
        "- Return JSON only\n"
        "- week_summary: one-sentence summary (<= 40 words) describing this week\n"
        "- next_week_advice: one sentence guidance for next week actions\n"
        "- confidence: 0 to 1\n"
        "- Avoid medical/diagnosis language; avoid precise numbers/grams\n"
        "- Do not repeat phrases between week_summary and next_week_advice\n"
        "- Avoid repeating or paraphrasing the previous week summary/advice\n"
        "- Avoid reusing the same opening or sentence structure as last week\n"
        "JSON example:\n"
        "{\n"
        "  \"week_summary\": \"Overall balanced, but fat intake is slightly high\",\n"
        "  \"next_week_advice\": \"Next week: more veggies and lean protein\",\n"
        "  \"confidence\": 0.7\n"
        "}\n"
        f"Week: {week_start} ~ {week_end}\n"
        f"Daily summaries:\n{day_block}\n"
        f"{history_block}\n"
    ) + profile_text


def _fallback_week_summary(lang: str, days: List[WeekSummaryInput]) -> dict:
    raise RuntimeError("fallback_disabled")

def _build_meal_advice_prompt(lang: str, profile: dict | None, meal: MealAdviceRequest) -> str:
    profile_text = ""
    if profile:
        tone = str(profile.get("tone") or "").strip()
        persona = str(profile.get("persona") or "").strip()
        tone_line = f"Tone: {tone}\n" if tone else ""
        persona_line = f"Persona: {persona}\n" if persona else ""
        profile_text = (
            f"User profile (do not mention exact values): {json.dumps(profile, ensure_ascii=True)}\n"
            f"{persona_line}{tone_line}"
            "Use this only to adjust tone and suggestions. Never mention the profile values explicitly.\n"
        )
    summaries = (
        "；".join(meal.dish_summaries) if meal.dish_summaries else ("無摘要" if lang == "zh-TW" else "no summary")
    )
    day_summaries = ""
    if meal.day_meal_summaries:
        day_summaries = "\n".join([f"- {item}" for item in meal.day_meal_summaries if item])
    day_context = ""
    if meal.day_calorie_range or meal.day_meal_count or day_summaries:
        day_context = (
            f"今日累計熱量區間：{meal.day_calorie_range or '未知'}\n"
            f"今日已記錄餐數：{meal.day_meal_count or 0}\n"
            f"今日餐點摘要：\n{day_summaries or '- 無'}\n"
        )
    intake_context = ""
    if meal.today_consumed_kcal is not None or meal.today_remaining_kcal is not None or meal.today_macros:
        intake_context = (
            f"今日已吃熱量估計：{meal.today_consumed_kcal if meal.today_consumed_kcal is not None else '未知'} kcal\n"
            f"今日剩餘熱量估計：{meal.today_remaining_kcal if meal.today_remaining_kcal is not None else '未知'} kcal\n"
            f"今日宏量累計：{meal.today_macros or '未知'}\n"
        )
    last_meal_context = ""
    fasting_context = ''
    if meal.last_meal_time or meal.fasting_hours is not None:
        fasting_context = (
            f'前一餐時間：{meal.last_meal_time or "未知"}\n'
            f'空腹多久：{meal.fasting_hours if meal.fasting_hours is not None else "未知"} 小時\n'
        )
    if meal.last_meal_macros:
        last_meal_context = f"上一餐宏量：{meal.last_meal_macros}\n"
    recent_advice_context = ""
    if meal.recent_advice:
        recent = "\n".join([f"- {item}" for item in meal.recent_advice if item])
        recent_advice_context = f"最近 7 天建議（避免重複食物與句型）：\n{recent}\n"
    diet_context = ""
    if profile:
        diet_type = str(profile.get("diet_type") or "").strip()
        diet_note = str(profile.get("diet_note") or "").strip()
        if diet_type or diet_note:
            diet_context = (
                f"飲食偏好：{diet_type or '未指定'}\n"
                f"偏好補充：{diet_note or '無'}\n"
            )
    container_context = ""
    if profile:
        ctype = str(profile.get("container_type") or "").strip()
        csize = str(profile.get("container_size") or "").strip()
        cdepth = str(profile.get("container_depth") or "").strip()
        cdiam = profile.get("container_diameter_cm")
        ccap = profile.get("container_capacity_ml")
        if ctype or csize or cdepth or cdiam or ccap:
            container_context = (
                f"常用容器：{ctype or 'unknown'} / {csize or 'unknown'} / {cdepth or 'unknown'}\n"
                f"直徑(cm)：{cdiam or 'unknown'} | 容量(ml)：{ccap or 'unknown'}\n"
            )
    if lang == "zh-TW":
        return (
            "你是營養分析助理。請根據本餐摘要，給出下一餐建議，回傳 JSON。\n"
            "要求：\n"
            "- 僅回傳 JSON（不要多餘文字）\n"
            "- self_cook / convenience / bento / other：各 1 句建議\n"
            "- 每句需包含具體食物方向 + 份量描述（例：主食半碗、蛋白質一掌、蔬菜一碗）\n"
            "- 避免醫療或診斷字眼；避免精準數值或克數\n"
            "- 需提到上一餐摘要的影響（例如偏油、偏鹹）\n"
            "- 需考量今日累計與已吃內容，避免重複負擔\n"
            "- 若為晚餐或消夜，建議更清淡、避免夜間加餐或高糖高油\n- 節奏規則：\n  * 早餐：若空腹很久→溫和好消化；若前一餐很晚→更清淡\n  * 午餐：依早餐量調整；早餐偏多→午餐清淡；早餐偏少→午餐補足\n  * 下午茶：若距晚餐 <= 2 小時→提醒不一定需要或少量；若吃了→提醒晚餐減量或取消\n  * 晚餐：依早/午/下午茶調整；吃多→減量清淡；吃少→正常補足\n  * 消夜：若早/中/晚都有吃→勸戒不建議；若缺餐→可輕量\n- 若今日剩餘熱量 <= 0：必須勸戒停止進食，不提供進食方案\n"
            "- 若有飲食偏好/禁忌，必須遵守並避免推薦衝突食物\n"
            "JSON 範例：\n"
            "{\n"
            "  \"self_cook\": \"清炒蔬菜＋蒸魚，主食半碗即可\",\n"
            "  \"convenience\": \"沙拉＋無糖豆漿，主食半碗\",\n"
            "  \"bento\": \"少飯、加青菜、選清淡蛋白\",\n"
            "  \"other\": \"清湯＋蔬菜＋瘦肉，避免油炸\",\n"
            "  \"confidence\": 0.7\n"
            "}\n"
            f"本餐：{_meal_type_label(meal.meal_type, lang) or meal.meal_type} | {meal.calorie_range}\n"
            f"本餐摘要：{summaries}\n"
            f"{day_context}{intake_context}{last_meal_context}{fasting_context}{diet_context}{container_context}{recent_advice_context}"
        ) + profile_text
    return (
        "You are a nutrition assistant. Based on the meal summary, return JSON advice for the next meal.\n"
        "Requirements:\n"
        "- Return JSON only\n"
        "- self_cook / convenience / bento / other: one sentence each\n"
        "- Each sentence must include food direction + portion guidance (e.g., half bowl carbs, palm-sized protein, one bowl veggies)\n"
        "- Avoid medical/diagnosis language; avoid precise numbers/grams\n"
        "- Mention the influence of the previous meal summary\n"
        "- Consider today’s cumulative intake and foods already eaten\n"
        "- If this is dinner or late-night snack, keep it lighter and avoid late-night extra eating\n- Rhythm rules:\n  * Breakfast: long fasting -> gentle/easy; late last meal -> lighter\n  * Lunch: adjust by breakfast; heavy breakfast -> lighter lunch; light breakfast -> normal\n  * Afternoon snack: if <= 2h to dinner -> suggest skipping or tiny; if eaten -> warn to reduce dinner\n  * Dinner: adjust by earlier meals; heavy day -> light dinner; light day -> normal dinner\n  * Late snack: if already had all meals -> discourage; if skipped meals -> light option\n- If today_remaining_kcal <= 0: must discourage further eating, no meal suggestions\n"
        "- Respect dietary preferences or restrictions when present\n"
        "- Avoid repeating foods or phrasing from the recent advice list if provided\n"
        "JSON example:\n"
        "{\n"
        "  \"self_cook\": \"Steamed fish + veggies, half bowl carbs\",\n"
        "  \"convenience\": \"Salad + unsweetened soy milk, half bowl carbs\",\n"
        "  \"bento\": \"Less rice, more veggies, lean protein\",\n"
        "  \"other\": \"Clear soup + veggies + lean protein\",\n"
        "  \"confidence\": 0.7\n"
        "}\n"
        f"Meal: {_meal_type_label(meal.meal_type, lang) or meal.meal_type} | {meal.calorie_range}\n"
        f"Meal summary: {summaries}\n"
        f"Today total range: {meal.day_calorie_range or 'unknown'}\n"
        f"Meals today: {meal.day_meal_count or 0}\n"
        f"Meal summaries today:\n{day_summaries or '- none'}\n"
        f"{intake_context}{last_meal_context}{diet_context}{container_context}{recent_advice_context}"
    ) + profile_text


def _fallback_meal_advice(lang: str) -> dict:
    raise RuntimeError("fallback_disabled")

def _build_label_prompt(lang: str) -> str:
    if lang == "zh-TW":
        return (
            "你是營養標示讀取助手。請根據包裝/營養標示圖片回傳 JSON。\n"
            "要求：\n"
            "- 僅回傳 JSON（不要多餘文字）\n"
            "- label_name: 產品或品名（若看不到可留空）\n"
            "- calorie_range: 若有熱量數字，請輸出區間或單一值（例：200 kcal 或 180-220 kcal）\n"
            "- macros: protein/carbs/fat 為克數(g)，sodium 為毫克(mg)（不要用百分比）\n"
            "- confidence: 0 到 1 的信心分數\n"
            "- is_beverage: 是否為飲料（true/false）\n"
            "- 飲料規則：若為飲料，protein/fat 請偏低（約 <= 3g）\n"
            "JSON 範例：\n"
            "{\n"
            "  \"label_name\": \"無糖茶\",\n"
            "  \"calorie_range\": \"0-10 kcal\",\n"
            "  \"macros\": {\"protein\": 0, \"carbs\": 2, \"fat\": 0, \"sodium\": 15},\n"
            "  \"confidence\": 0.7,\n"
            "  \"is_beverage\": true\n"
            "}\n"
        )
    return (
        "You are a nutrition label reader. Return JSON from the package label image.\n"
        "Requirements:\n"
        "- Return JSON only\n"
        "- label_name: product name (empty if not visible)\n"
        "- calorie_range: range or single value (e.g., 200 kcal or 180-220 kcal)\n"
        "- macros: protein/carbs/fat in grams (g), sodium in milligrams (mg) (no percentages)\n"
        "- confidence: 0 to 1\n"
        "- is_beverage: true/false\n"
        "- Beverage rule: if beverage, protein/fat should be low (around <= 3g)\n"
        "JSON example:\n"
        "{\n"
        "  \"label_name\": \"unsweetened tea\",\n"
        "  \"calorie_range\": \"0-10 kcal\",\n"
        "  \"macros\": {\"protein\": 0, \"carbs\": 2, \"fat\": 0, \"sodium\": 15},\n"
        "  \"confidence\": 0.7,\n"
        "  \"is_beverage\": true\n"
        "}\n"
    )


def _fallback_day_summary(lang: str, meals: List[MealSummaryInput]) -> dict:
    raise RuntimeError("fallback_disabled")


def _estimate_cost_usd(input_tokens: int, output_tokens: int) -> float:
    return round((input_tokens * PRICE_INPUT_PER_M + output_tokens * PRICE_OUTPUT_PER_M) / 1_000_000, 6)


def _parse_iso(ts: str) -> Optional[datetime]:
    try:
        return datetime.fromisoformat(ts.replace("Z", "+00:00"))
    except Exception:
        return None


def _prune_usage_log() -> None:
    if not _usage_log_path.exists():
        return
    try:
        lines = _usage_log_path.read_text(encoding="utf-8").splitlines()
    except Exception:
        return
    if not lines:
        return
    cutoff = datetime.now(timezone.utc) - timedelta(days=USAGE_LOG_TTL_DAYS)
    entries = []
    for line in lines:
        try:
            record = json.loads(line)
        except Exception:
            continue
        created_at = _parse_iso(str(record.get("created_at", "")))
        if created_at and created_at < cutoff:
            continue
        entries.append(record)
    if not entries:
        _usage_log_path.write_text("", encoding="utf-8")
        return
    entries.sort(key=lambda item: _parse_iso(str(item.get("created_at", ""))) or datetime.min.replace(tzinfo=timezone.utc))
    if len(entries) > USAGE_LOG_MAX:
        entries = entries[-USAGE_LOG_MAX:]
    content = "\n".join(json.dumps(item, ensure_ascii=True) for item in entries)
    _usage_log_path.write_text(content + "\n", encoding="utf-8")


def _prune_analysis_cache(data: dict) -> dict:
    if not data:
        return {}
    cutoff = datetime.now(timezone.utc) - timedelta(days=ANALYSIS_CACHE_TTL_DAYS)
    items = []
    for key, value in data.items():
        if not isinstance(value, dict):
            continue
        saved_at = _parse_iso(str(value.get("saved_at", "")))
        if saved_at and saved_at < cutoff:
            continue
        items.append((key, value, saved_at))
    if not items:
        return {}
    items.sort(key=lambda item: item[2] or datetime.min.replace(tzinfo=timezone.utc))
    if len(items) > ANALYSIS_CACHE_MAX:
        items = items[-ANALYSIS_CACHE_MAX:]
    return {key: value for key, value, _ in items}


def _append_usage(record: dict) -> None:
    line = json.dumps(record, ensure_ascii=True)
    with _usage_log_path.open("a", encoding="utf-8") as handle:
        handle.write(line + "\n")
    _prune_usage_log()


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
        data = json.loads(_analysis_cache_path.read_text(encoding="utf-8"))
        if not isinstance(data, dict):
            return {}
        pruned = _prune_analysis_cache(data)
        if len(pruned) != len(data):
            _analysis_cache_path.write_text(json.dumps(pruned, ensure_ascii=True), encoding="utf-8")
        return pruned
    except Exception:
        return {}


def _save_analysis_cache(data: dict) -> None:
    pruned = _prune_analysis_cache(data)
    _analysis_cache_path.write_text(json.dumps(pruned, ensure_ascii=True), encoding="utf-8")


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


def _ensure_ai_available() -> None:
    if not CALL_REAL_AI:
        raise HTTPException(status_code=503, detail="ai_disabled")
    if _client is None:
        raise HTTPException(status_code=503, detail="ai_not_configured")
    if not _should_use_ai():
        raise HTTPException(status_code=429, detail="ai_quota_exceeded")


def _increment_daily_count() -> None:
    counts = _load_daily_counts()
    today = datetime.now(timezone.utc).date().isoformat()
    counts[today] = int(counts.get(today, 0)) + 1
    _save_daily_counts(counts)


def _chat_rate_allowed(user_id: str) -> bool:
    if _chat_rate_limit <= 0:
        return True
    now = time.time()
    window = _chat_rate_window_sec
    entries = _chat_rate_state.get(user_id, [])
    entries = [t for t in entries if now - t <= window]
    if len(entries) >= _chat_rate_limit:
        _chat_rate_state[user_id] = entries
        return False
    entries.append(now)
    _chat_rate_state[user_id] = entries
    return True


def _find_latest_user_message(messages: List[ChatMessageInput]) -> str:
    for msg in reversed(messages):
        if (msg.role or "").lower() == "user":
            return (msg.content or "").strip()
    return ""


def _chat_is_blocked(text: str) -> bool:
    if not text:
        return False
    lower = text.lower()
    return any(term in lower for term in _chat_blocklist)


def _chat_blocked_reply(lang: str) -> str:
    if lang == "zh-TW":
        return "喵～我只聊飲食與健康相關問題喔！可以問我今天要吃什麼或怎麼搭配～"
    return "Meow~ I can only help with food and health topics. Ask me about meals or nutrition!"


def _chat_rate_reply(lang: str) -> str:
    if lang == "zh-TW":
        return "喵嗚～先慢一點點，我剛剛回覆太頻繁了，稍後再問我喔！"
    return "Meow~ a little too fast. Please wait a moment and try again!"


def _build_chat_prompt(
    lang: str,
    profile: dict | None,
    days: Optional[List[dict]],
    today_meals: Optional[List[dict]],
    summary: Optional[str],
    context: Optional[dict],
) -> str:
    assistant_name = ""
    if profile:
        assistant_name = str(
            profile.get("assistant_name")
            or profile.get("chat_assistant_name")
            or profile.get("assistantName")
            or ""
        ).strip()
    if not assistant_name:
        assistant_name = "咚咚" if lang == "zh-TW" else "Dongdong"
    profile_text = ""
    if profile:
        tone = str(profile.get("tone") or "").strip()
        persona = str(profile.get("persona") or "").strip()
        tone_line = f"Tone: {tone}\n" if tone else ""
        persona_line = f"Persona: {persona}\n" if persona else ""
        profile_text = (
            f"User profile (do not mention exact values): {json.dumps(profile, ensure_ascii=True)}\n"
            f"{persona_line}{tone_line}"
            "Use this only to adjust tone and suggestions. Never mention the profile values explicitly.\n"
        )
    day_lines = []
    for day in days or []:
        date = str(day.get("date") or "")
        has_data = bool(day.get("has_data"))
        if not has_data:
            line = f"- {date}: 無紀錄" if lang == "zh-TW" else f"- {date}: no records"
            day_lines.append(line)
            continue
        meal_count = day.get("meal_count") or 0
        labels = str(day.get("meal_labels") or "").strip()
        calorie_range = str(day.get("calorie_range") or "").strip()
        summary_text = str(day.get("summary") or "").strip()
        consumed = day.get("consumed_kcal")
        remaining = day.get("remaining_kcal")
        extras = []
        if consumed is not None:
            extras.append(f"已吃 {consumed} kcal" if lang == "zh-TW" else f"consumed {consumed} kcal")
        if remaining is not None:
            extras.append(f"剩餘 {remaining} kcal" if lang == "zh-TW" else f"remaining {remaining} kcal")
        extra_text = f"（{'，'.join(extras)}）" if extras and lang == "zh-TW" else (f" ({', '.join(extras)})" if extras else "")
        if lang == "zh-TW":
            label_text = f"{labels}，" if labels else ""
            range_text = f"熱量 {calorie_range}" if calorie_range else "熱量未知"
            summary_block = f"；摘要：{summary_text}" if summary_text else ""
            day_lines.append(f"- {date}：餐數 {meal_count}，{label_text}{range_text}{extra_text}{summary_block}")
        else:
            label_text = f"{labels}, " if labels else ""
            range_text = f"calories {calorie_range}" if calorie_range else "calories unknown"
            summary_block = f"; summary: {summary_text}" if summary_text else ""
            day_lines.append(f"- {date}: meals {meal_count}, {label_text}{range_text}{extra_text}{summary_block}")
    days_block = "\n".join(day_lines) if day_lines else ("- 無紀錄" if lang == "zh-TW" else "- no records")
    summary_block = summary.strip() if summary else ""
    today_meals_block = ""
    if today_meals:
        try:
            today_meals_block = json.dumps(today_meals, ensure_ascii=True)
        except Exception:
            today_meals_block = str(today_meals)

    now_text = ""
    if context:
        now_raw = str(context.get("now") or "").strip()
        last_meal = str(context.get("last_meal_time") or "").strip()
        fasting_hours = context.get("fasting_hours")
        fasting_text = ""
        if fasting_hours is not None:
            try:
                fasting_text = f"{float(fasting_hours):.1f} 小時" if lang == "zh-TW" else f"{float(fasting_hours):.1f} hours"
            except Exception:
                fasting_text = ""
        if lang == "zh-TW":
            now_text = (
                f"現在時間：{now_raw or '未知'}\n"
                f"最近一餐時間：{last_meal or '未知'}\n"
                f"空腹時間：約 {fasting_text or '未知'}\n"
            )
        else:
            now_text = (
                f"Current time: {now_raw or 'unknown'}\n"
                f"Last meal time: {last_meal or 'unknown'}\n"
                f"Fasting duration: ~{fasting_text or 'unknown'}\n"
            )

    if lang == "zh-TW":
        return (
            f"你是{assistant_name}，風格可愛親切但專業。請根據使用者最近 7 天紀錄與對話摘要回答問題。\n"
            "要求：\n"
            "- 僅回傳 JSON（不要多餘文字）\n"
            "- reply：回答使用者問題（1-4 句），避免醫療/診斷語氣\n"
            "- summary：濃縮對話記憶（120 字內），保留使用者偏好/目標/禁忌\n"
            "- 若資料不足，先追問 1-2 個必要問題\n"
            "- 若今天剩餘熱量 <= 0，且使用者想吃/要建議，必須勸戒不要再吃\n"
            "- 口癖：可用「喵～」或「喵嗚」點綴，但每次回覆最多出現 1 次，且隨機低頻（約 3-5 次回覆出現 1 次）\n"
            "- 若問題與飲食/健康無關，請簡短婉拒並引導回飲食主題\n"
            "JSON 範例：\n"
            "{\n  \"reply\": \"今天晚餐建議清淡些…\",\n  \"summary\": \"使用者偏好清淡、避免油炸…\"\n}\n"
            f"最近 7 天紀錄：\n{days_block}\n"
            f"今日餐點明細（JSON）：{today_meals_block or '無'}\n"
            f"{now_text}"
            f"對話摘要：{summary_block or '無'}\n"
        ) + profile_text
    return (
        f"You are {assistant_name}, a friendly nutrition assistant. Answer based on the last 7 days and the conversation summary.\n"
        "Requirements:\n"
        "- Return JSON only\n"
        "- reply: answer in 1-4 sentences, avoid medical/diagnosis language\n"
        "- summary: compact memory (<= 120 words), keep user preferences/goals\n"
        "- Ask 1-2 clarifying questions if data is insufficient\n"
        "- If today's remaining_kcal <= 0 and user asks for food suggestions, discourage further eating\n"
        "- If the question is unrelated to food/health, politely decline and redirect to diet topics\n"
        "JSON example:\n"
        "{\n  \"reply\": \"Keep dinner light...\",\n  \"summary\": \"User prefers light meals...\"\n}\n"
        f"Last 7 days:\n{days_block}\n"
        f"Today's meals (JSON): {today_meals_block or 'none'}\n"
        f"{now_text}"
        f"Conversation summary: {summary_block or 'none'}\n"
    ) + profile_text


def _analyze_with_openai(
    image_bytes: bytes,
    lang: str,
    food_name: str | None,
    profile: dict,
    note: str | None,
    portion_percent: int | None,
    meal_type: str | None,
    meal_photo_count: int | None,
    context: str | None,
    advice_mode: str | None,
    today_consumed_kcal: int | None,
    today_remaining_kcal: int | None,
    today_protein_g: int | None,
    label_context: str | None,
    reference_object: str | None,
    reference_length_cm: float | None,
    container_type: str | None,
    container_size: str | None,
    container_depth: str | None,
    container_diameter_cm: int | None,
    container_capacity_ml: int | None,
) -> Optional[dict]:
    if _client is None:
        return None

    prompt = _build_prompt(
        lang,
        profile,
        note,
        portion_percent,
        meal_type,
        meal_photo_count,
        context,
        advice_mode,
        today_consumed_kcal,
        today_remaining_kcal,
        today_protein_g,
        label_context,
        reference_object,
        reference_length_cm,
        container_type,
        container_size,
        container_depth,
        container_diameter_cm,
        container_capacity_ml,
    )
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
    is_beverage, is_food = _coerce_food_flags(data)
    data["macros"] = _normalize_macros(data, lang)
    data["calorie_range"] = _normalize_calorie_range(
        data.get("calorie_range", ""),
        is_beverage=is_beverage,
        tighten=label_context is None,
    )
    ref_used = str(data.get("reference_used") or "").strip()
    if reference_length_cm and reference_length_cm > 0:
        if lang == "zh-TW":
            data["reference_used"] = f"測距 {reference_length_cm}cm"
        else:
            data["reference_used"] = f"measured {reference_length_cm}cm"
    elif ref_used:
        data["reference_used"] = ref_used
    else:
        data["reference_used"] = "無" if lang == "zh-TW" else "none"
    data.setdefault("confidence", 0.6)
    data.setdefault("dish_summary", "")
    data.setdefault("food_items", [])
    data.setdefault("judgement_tags", [])

    usage = response.usage
    usage_data = None
    if usage is not None:
        usage_data = {
            "input_tokens": usage.prompt_tokens,
            "output_tokens": usage.completion_tokens,
            "total_tokens": usage.total_tokens,
        }
    return {"result": data, "usage": usage_data}


def _parse_calorie_range(value: str) -> Optional[tuple[int, int]]:
    if not value:
        return None
    match = [int(s) for s in value.replace(",", "").split() if s.isdigit()]
    if len(match) >= 2:
        low, high = match[0], match[1]
        if low > high:
            low, high = high, low
        return low, high
    if len(match) == 1:
        return match[0], match[0]
    return None


def _normalize_calorie_range(value: str, is_beverage: bool, tighten: bool = True) -> str:
    parsed = _parse_calorie_range(value)
    if parsed is None:
        return value
    low, high = parsed
    if tighten:
        max_width = 120 if is_beverage else 200
        width = max(0, high - low)
        if width > max_width:
            mid = int(round((low + high) / 2))
            half = max_width // 2
            low = max(0, mid - half)
            high = low + max_width
    return f"{low}-{high} kcal"


def _parse_is_beverage(data: dict) -> bool:
    if not isinstance(data, dict):
        return False
    raw_flag = data.get("is_beverage")
    if isinstance(raw_flag, bool):
        return raw_flag
    if isinstance(raw_flag, str):
        return raw_flag.strip().lower() == "true"
    return False


def _parse_is_food(data: dict) -> bool:
    raw = data.get("is_food")
    if isinstance(raw, bool):
        return raw
    if isinstance(raw, str):
        lower = raw.strip().lower()
        if lower in ("true", "yes", "y", "1"):
            return True
        if lower in ("false", "no", "n", "0"):
            return False
    return True


def _coerce_food_flags(data: dict) -> tuple[bool, bool]:
    if not isinstance(data, dict):
        return False, True
    is_beverage = _parse_is_beverage(data)
    is_food = _parse_is_food(data)
    non_food_reason = str(data.get("non_food_reason") or "").strip()
    name_hint = f"{data.get('food_name') or ''} {data.get('label_name') or ''}".strip()
    name_lower = name_hint.lower()
    name_has = lambda token: token in name_hint or token in name_lower
    if not is_beverage and not is_food and non_food_reason:
        lower = non_food_reason.lower()
        if (
            "飲" in non_food_reason
            or "酒" in non_food_reason
            or "drink" in lower
            or "beverage" in lower
            or "alcohol" in lower
            or "beer" in lower
            or "wine" in lower
            or "cocktail" in lower
        ):
            is_beverage = True
    if not is_food and not is_beverage and (
        name_has("湯")
        or name_has("粥")
        or name_has("冰")
        or name_has("雪糕")
        or name_has("冰淇淋")
        or name_has("刨冰")
        or name_has("零食")
        or name_has("餅乾")
        or name_has("點心")
        or name_has("snack")
        or name_has("soup")
        or name_has("porridge")
        or name_has("congee")
        or name_has("ice cream")
    ):
        is_food = True
    if is_beverage:
        is_food = True
        non_food_reason = ""
    elif is_food:
        non_food_reason = ""
    data["is_beverage"] = is_beverage
    data["is_food"] = is_food
    data["non_food_reason"] = non_food_reason
    return is_beverage, is_food


def _analyze_label_with_openai(image_bytes: bytes, lang: str) -> Optional[dict]:
    if _client is None:
        return None
    prompt = _build_label_prompt(lang)
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
    required = {"calorie_range", "macros"}
    if not required.issubset(set(data.keys())):
        return None
    is_beverage = _parse_is_beverage(data)
    data["is_beverage"] = is_beverage
    data["macros"] = _normalize_macros(data, lang)
    data["calorie_range"] = _normalize_calorie_range(
        data.get("calorie_range", ""),
        is_beverage=is_beverage,
        tighten=False,
    )
    data.setdefault("confidence", 0.6)
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
    _auth: dict = Depends(_require_auth),
    image: UploadFile = File(...),
    lang: str = Query(default=None, description="Language code, e.g. zh-TW, en"),
    food_name: str = Form(default=None),
    note: Optional[str] = Form(default=None),
    context: Optional[str] = Form(default=None),
    portion_percent: Optional[int] = Form(default=None),
    container_type: Optional[str] = Form(default=None),
    container_size: Optional[str] = Form(default=None),
    container_depth: Optional[str] = Form(default=None),
    container_diameter_cm: Optional[int] = Form(default=None),
    container_capacity_ml: Optional[int] = Form(default=None),
    height_cm: Optional[int] = Form(default=None),
    weight_kg: Optional[int] = Form(default=None),
    age: Optional[int] = Form(default=None),
    gender: Optional[str] = Form(default=None),
    tone: Optional[str] = Form(default=None),
    persona: Optional[str] = Form(default=None),
    activity_level: Optional[str] = Form(default=None),
    target_calorie_range: Optional[str] = Form(default=None),
    goal: Optional[str] = Form(default=None),
    plan_speed: Optional[str] = Form(default=None),
    today_consumed_kcal: Optional[int] = Form(default=None),
    today_remaining_kcal: Optional[int] = Form(default=None),
    today_protein_g: Optional[int] = Form(default=None),
    meal_type: Optional[str] = Form(default=None),
    meal_photo_count: Optional[int] = Form(default=None),
    advice_mode: Optional[str] = Form(default=None),
    force_reanalyze: Optional[str] = Form(default=None),
    label_context: Optional[str] = Form(default=None),
    reference_object: Optional[str] = Form(default=None),
    reference_length_cm: Optional[float] = Form(default=None),
    analyze_reason: Optional[str] = Form(default=None),
):
    image_bytes = await image.read()
    image_hash = _hash_image(image_bytes)

    use_lang = lang or DEFAULT_LANG
    if use_lang not in _supported_langs:
        use_lang = "zh-TW"

    force_reanalyze_flag = False
    if isinstance(force_reanalyze, str):
        force_reanalyze_flag = force_reanalyze.strip().lower() == "true"

    logging.info(
        "Analyze request reason=%s meal_type=%s advice_mode=%s lang=%s force=%s",
        analyze_reason,
        meal_type,
        advice_mode,
        use_lang,
        force_reanalyze_flag,
    )

    tier = "full"
    portion_is_default = portion_percent in (None, 100)
    if (
        not force_reanalyze_flag
        and advice_mode != "current_meal"
        and food_name is None
        and note is None
        and context is None
        and portion_is_default
        and advice_mode is None
        and label_context is None
        and reference_object is None
        and reference_length_cm is None
        and container_type is None
        and container_size is None
        and container_depth is None
        and container_diameter_cm is None
        and container_capacity_ml is None
        and today_consumed_kcal is None
        and today_remaining_kcal is None
        and today_protein_g is None
    ):
        cache = _load_analysis_cache()
        cached = cache.get(image_hash)
        if isinstance(cached, dict) and isinstance(cached.get("result"), dict):
            logging.info("Analyze cache hit reason=%s hash=%s", analyze_reason, image_hash[:8])
            cached_result = cached["result"]
            is_beverage, is_food = _coerce_food_flags(cached_result)
            container_guess_type, container_guess_size = _normalize_container_guess(cached_result)
            return AnalysisResult(
                food_name=cached_result.get("food_name", ""),
                calorie_range=cached_result.get("calorie_range", ""),
                macros=_normalize_macros(cached_result, use_lang),
                food_items=cached_result.get("food_items") or [],
                judgement_tags=cached_result.get("judgement_tags") or [],
                dish_summary=cached_result.get("dish_summary", ""),
                suggestion=cached_result.get("suggestion", ""),
                tier="cached",
                source="cache",
                cost_estimate_usd=None,
                is_beverage=is_beverage,
                is_food=is_food,
                non_food_reason=cached_result.get("non_food_reason"),
                reference_used=cached_result.get("reference_used"),
                container_guess_type=container_guess_type,
                container_guess_size=container_guess_size,
            )

    _ensure_ai_available()
    profile = {
        "height_cm": height_cm,
        "weight_kg": weight_kg,
        "age": age,
        "gender": gender,
        "tone": tone,
        "persona": persona,
        "activity_level": activity_level,
        "target_calorie_range": target_calorie_range,
        "goal": goal,
        "plan_speed": plan_speed,
    }
    profile = {k: v for k, v in profile.items() if v not in (None, "", 0)}

    try:
        payload = await asyncio.to_thread(
            _analyze_with_openai,
            image_bytes,
            use_lang,
            food_name,
            profile,
            note,
            portion_percent,
            meal_type,
            meal_photo_count,
            context,
            advice_mode,
            today_consumed_kcal,
            today_remaining_kcal,
            today_protein_g,
            label_context,
            reference_object,
            reference_length_cm,
            container_type,
            container_size,
            container_depth,
            container_diameter_cm,
            container_capacity_ml,
        )
        if not payload or not payload.get("result"):
            raise HTTPException(status_code=502, detail="ai_invalid_response")
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
        is_beverage, is_food = _coerce_food_flags(payload["result"])
        normalized_macros = _normalize_macros(payload["result"], use_lang)
        container_guess_type, container_guess_size = _normalize_container_guess(payload["result"])
        cache[image_hash] = {
            "saved_at": datetime.now(timezone.utc).isoformat(),
            "result": {
                "food_name": final_name,
                "calorie_range": payload["result"]["calorie_range"],
                "macros": normalized_macros,
                "food_items": payload["result"].get("food_items") or [],
                "judgement_tags": payload["result"].get("judgement_tags") or [],
                "dish_summary": payload["result"].get("dish_summary", ""),
                "suggestion": payload["result"]["suggestion"],
                "is_beverage": payload["result"].get("is_beverage"),
                "is_food": payload["result"].get("is_food", True),
                "non_food_reason": payload["result"].get("non_food_reason"),
                "reference_used": payload["result"].get("reference_used"),
                "container_guess_type": container_guess_type,
                "container_guess_size": container_guess_size,
            },
        }
        _save_analysis_cache(cache)
        return AnalysisResult(
            food_name=final_name,
            calorie_range=payload["result"]["calorie_range"],
            macros=normalized_macros,
            food_items=payload["result"].get("food_items") or [],
            judgement_tags=payload["result"].get("judgement_tags") or [],
            dish_summary=payload["result"].get("dish_summary", ""),
            suggestion=payload["result"]["suggestion"],
            tier=tier,
            source="ai",
            cost_estimate_usd=cost_estimate,
            confidence=payload["result"].get("confidence"),
            is_beverage=is_beverage,
            is_food=is_food,
            non_food_reason=payload["result"].get("non_food_reason"),
            reference_used=payload["result"].get("reference_used"),
            container_guess_type=container_guess_type,
            container_guess_size=container_guess_size,
            debug_reason=None,
        )
    except HTTPException:
        raise
    except Exception as exc:
        global _last_ai_error
        _last_ai_error = str(exc)
        logging.exception("AI analyze failed: %s", exc)
        raise HTTPException(status_code=502, detail="ai_failed")


@app.post("/analyze_name", response_model=AnalysisResult)
async def analyze_name(
    payload: NameAnalyzeRequest,
    _auth: dict = Depends(_require_auth),
):
    raw_name = (payload.food_name or "").strip()
    if not raw_name:
        raise HTTPException(status_code=400, detail="missing_food_name")

    use_lang = payload.lang or DEFAULT_LANG
    if use_lang not in _supported_langs:
        use_lang = "zh-TW"

    _ensure_ai_available()
    profile = payload.profile or {}
    try:
        prompt = _build_name_prompt(
            use_lang,
            profile,
            raw_name,
            payload.note,
            payload.portion_percent,
            payload.meal_type,
            payload.context,
            payload.advice_mode,
            payload.container_type,
            payload.container_size,
            payload.container_depth,
            payload.container_diameter_cm,
            payload.container_capacity_ml,
        )
        response = _client.chat.completions.create(
            model=OPENAI_MODEL,
            messages=[{"role": "user", "content": prompt}],
            temperature=0.2,
        )
        text = response.choices[0].message.content or ""
        data = _parse_json(text)
        if not isinstance(data, dict) or "food_name" not in data or "calorie_range" not in data:
            raise HTTPException(status_code=502, detail="ai_invalid_response")
        usage = response.usage
        usage_data = None
        if usage is not None:
            usage_data = {
                "input_tokens": usage.prompt_tokens,
                "output_tokens": usage.completion_tokens,
                "total_tokens": usage.total_tokens,
            }
        cost_estimate = None
        if usage_data is not None:
            cost_estimate = _estimate_cost_usd(
                int(usage_data.get("input_tokens") or 0),
                int(usage_data.get("output_tokens") or 0),
            )
        _append_usage(
            {
                "id": str(uuid.uuid4()),
                "created_at": datetime.now(timezone.utc).isoformat(),
                "model": OPENAI_MODEL,
                "lang": use_lang,
                "source": "name",
                "input_tokens": int(usage_data.get("input_tokens") or 0) if usage_data else 0,
                "output_tokens": int(usage_data.get("output_tokens") or 0) if usage_data else 0,
                "total_tokens": int(usage_data.get("total_tokens") or 0) if usage_data else 0,
                "cost_estimate_usd": cost_estimate,
            }
        )
        _increment_daily_count()
        is_beverage, is_food = _coerce_food_flags(data)
        normalized_macros = _normalize_macros(data, use_lang)
        calorie_range = _normalize_calorie_range(
            data.get("calorie_range", ""),
            is_beverage=is_beverage,
            tighten=False,
        )
        container_guess_type, container_guess_size = _normalize_container_guess(data)
        return AnalysisResult(
            food_name=raw_name or data.get("food_name", ""),
            calorie_range=calorie_range,
            macros=normalized_macros,
            food_items=data.get("food_items") or [],
            judgement_tags=data.get("judgement_tags") or [],
            dish_summary=data.get("dish_summary", ""),
            suggestion=data.get("suggestion", ""),
            tier="name",
            source="ai",
            cost_estimate_usd=cost_estimate,
            confidence=data.get("confidence"),
            is_beverage=is_beverage,
            is_food=data.get("is_food", True),
            non_food_reason=data.get("non_food_reason"),
            reference_used="無" if use_lang == "zh-TW" else "none",
            container_guess_type=container_guess_type,
            container_guess_size=container_guess_size,
            debug_reason=None,
        )
    except HTTPException:
        raise
    except Exception as exc:
        global _last_ai_error
        _last_ai_error = str(exc)
        logging.exception("Name analyze failed: %s", exc)
        raise HTTPException(status_code=502, detail="ai_failed")


@app.post("/analyze_label", response_model=LabelResult)
async def analyze_label(
    _auth: dict = Depends(_require_auth),
    image: UploadFile = File(...),
    lang: str = Query(default=None, description="Language code, e.g. zh-TW, en"),
):
    image_bytes = await image.read()

    use_lang = lang or DEFAULT_LANG
    if use_lang not in _supported_langs:
        use_lang = "zh-TW"

    _ensure_ai_available()
    try:
        payload = await asyncio.to_thread(_analyze_label_with_openai, image_bytes, use_lang)
        if not payload or not payload.get("result"):
            raise HTTPException(status_code=502, detail="ai_invalid_response")
        usage_data = payload.get("usage") or {}
        input_tokens = int(usage_data.get("input_tokens") or 0)
        output_tokens = int(usage_data.get("output_tokens") or 0)
        cost_estimate = _estimate_cost_usd(input_tokens, output_tokens) if usage_data else None
        logging.info(
            "Analyze label result tokens=%s cost=%s",
            int(usage_data.get("total_tokens") or 0),
            cost_estimate,
        )
        _append_usage(
            {
                "id": str(uuid.uuid4()),
                "created_at": datetime.now(timezone.utc).isoformat(),
                "model": OPENAI_MODEL,
                "lang": use_lang,
                "source": "label",
                "input_tokens": input_tokens,
                "output_tokens": output_tokens,
                "total_tokens": int(usage_data.get("total_tokens") or 0),
                "cost_estimate_usd": cost_estimate,
                "image_bytes": len(image_bytes),
            }
        )
        _increment_daily_count()
        return LabelResult(
            label_name=payload["result"].get("label_name"),
            calorie_range=payload["result"].get("calorie_range", ""),
            macros=_normalize_macros(payload["result"], use_lang),
            confidence=payload["result"].get("confidence"),
            is_beverage=payload["result"].get("is_beverage"),
        )
    except HTTPException:
        raise
    except Exception as exc:
        global _last_ai_error
        _last_ai_error = str(exc)
        logging.exception("Label analyze failed: %s", exc)
        raise HTTPException(status_code=502, detail="ai_failed")


@app.post("/summarize_day", response_model=DaySummaryResponse)
async def summarize_day(
    payload: DaySummaryRequest,
    _auth: dict = Depends(_require_auth),
):
    use_lang = payload.lang or DEFAULT_LANG
    if use_lang not in _supported_langs:
        use_lang = "zh-TW"
    _ensure_ai_available()
    try:
        prompt = _build_day_prompt(
            use_lang,
            payload.profile or {},
            payload.meals,
            payload.day_calorie_range,
            payload.day_meal_count,
            payload.previous_day_summary,
            payload.previous_tomorrow_advice,
            payload.today_consumed_kcal,
            payload.today_remaining_kcal,
        )
        response = _client.chat.completions.create(
            model=OPENAI_MODEL,
            messages=[{"role": "user", "content": prompt}],
            temperature=0.2,
        )
        text = response.choices[0].message.content or ""
        data = _parse_json(text)
        if not isinstance(data, dict) or "day_summary" not in data or "tomorrow_advice" not in data:
            raise HTTPException(status_code=502, detail="ai_invalid_response")
        return DaySummaryResponse(
            day_summary=data.get("day_summary", ""),
            tomorrow_advice=data.get("tomorrow_advice", ""),
            source="ai",
            confidence=(data.get("confidence") or 0.6),
        )
    except HTTPException:
        raise
    except Exception as exc:
        global _last_ai_error
        _last_ai_error = str(exc)
        logging.exception("Day summary failed: %s", exc)
        raise HTTPException(status_code=502, detail="ai_failed")


@app.post("/summarize_week", response_model=WeekSummaryResponse)
async def summarize_week(
    payload: WeekSummaryRequest,
    _auth: dict = Depends(_require_auth),
):
    use_lang = payload.lang or DEFAULT_LANG
    if use_lang not in _supported_langs:
        use_lang = "zh-TW"
    _ensure_ai_available()
    try:
        prompt = _build_week_prompt(
            use_lang,
            payload.profile or {},
            payload.days,
            payload.week_start,
            payload.week_end,
            payload.previous_week_summary,
            payload.previous_next_week_advice,
        )
        response = _client.chat.completions.create(
            model=OPENAI_MODEL,
            messages=[{"role": "user", "content": prompt}],
            temperature=0.2,
        )
        text = response.choices[0].message.content or ""
        data = _parse_json(text)
        if not isinstance(data, dict) or "week_summary" not in data or "next_week_advice" not in data:
            raise HTTPException(status_code=502, detail="ai_invalid_response")
        return WeekSummaryResponse(
            week_summary=data.get("week_summary", ""),
            next_week_advice=data.get("next_week_advice", ""),
            source="ai",
            confidence=(data.get("confidence") or 0.6),
        )
    except HTTPException:
        raise
    except Exception as exc:
        global _last_ai_error
        _last_ai_error = str(exc)
        logging.exception("Week summary failed: %s", exc)
        raise HTTPException(status_code=502, detail="ai_failed")


@app.post("/suggest_meal", response_model=MealAdviceResponse)
async def suggest_meal(
    payload: MealAdviceRequest,
    _auth: dict = Depends(_require_auth),
):
    use_lang = payload.lang or DEFAULT_LANG
    if use_lang not in _supported_langs:
        use_lang = "zh-TW"
    profile = payload.profile or {}
    _ensure_ai_available()
    try:
        prompt = _build_meal_advice_prompt(use_lang, profile, payload)
        response = _client.chat.completions.create(
            model=OPENAI_MODEL,
            messages=[{"role": "user", "content": prompt}],
            temperature=0.2,
        )
        text = response.choices[0].message.content or ""
        data = _parse_json(text)
        required = {"self_cook", "convenience", "bento", "other"}
        if not isinstance(data, dict) or not required.issubset(set(data.keys())):
            raise HTTPException(status_code=502, detail="ai_invalid_response")
        usage = response.usage
        usage_data = None
        if usage is not None:
            usage_data = {
                "input_tokens": usage.prompt_tokens,
                "output_tokens": usage.completion_tokens,
                "total_tokens": usage.total_tokens,
            }
        cost_estimate = None
        if usage_data is not None:
            cost_estimate = _estimate_cost_usd(
                int(usage_data.get("input_tokens") or 0),
                int(usage_data.get("output_tokens") or 0),
            )
        _append_usage(
            {
                "id": str(uuid.uuid4()),
                "created_at": datetime.now(timezone.utc).isoformat(),
                "model": OPENAI_MODEL,
                "lang": use_lang,
                "source": "ai",
                "input_tokens": int(usage_data.get("input_tokens") or 0) if usage_data else 0,
                "output_tokens": int(usage_data.get("output_tokens") or 0) if usage_data else 0,
                "total_tokens": int(usage_data.get("total_tokens") or 0) if usage_data else 0,
                "cost_estimate_usd": cost_estimate,
            }
        )
        _increment_daily_count()
        return MealAdviceResponse(
            self_cook=str(data.get("self_cook", "")).strip(),
            convenience=str(data.get("convenience", "")).strip(),
            bento=str(data.get("bento", "")).strip(),
            other=str(data.get("other", "")).strip(),
            source="ai",
            confidence=data.get("confidence"),
        )
    except HTTPException:
        raise
    except Exception as exc:
        global _last_ai_error
        _last_ai_error = str(exc)
        logging.exception("Meal advice failed: %s", exc)
        raise HTTPException(status_code=502, detail="ai_failed")





@app.post("/chat", response_model=ChatResponse)
async def chat(
    payload: ChatRequest,
    _auth: dict = Depends(_require_auth),
):
    use_lang = payload.lang or DEFAULT_LANG
    if use_lang not in _supported_langs:
        use_lang = "zh-TW"
    user_id = _auth.get("user_id", "")
    latest_user = _find_latest_user_message(payload.messages or [])
    if _chat_is_blocked(latest_user):
        logging.warning("Chat blocked: user=%s text=%s", user_id or "-", latest_user[:200])
        return ChatResponse(
            reply=_chat_blocked_reply(use_lang),
            summary=payload.summary or "",
            source="rule",
            confidence=1.0,
        )
    if user_id and not _chat_rate_allowed(user_id):
        logging.warning("Chat rate limited: user=%s", user_id or "-")
        return ChatResponse(
            reply=_chat_rate_reply(use_lang),
            summary=payload.summary or "",
            source="rate_limit",
            confidence=1.0,
        )
    try:
        _ensure_ai_available()
    except HTTPException as exc:
        if exc.detail in {"ai_disabled", "ai_not_configured", "ai_quota_exceeded"}:
            logging.warning("Chat AI unavailable: user=%s reason=%s", user_id or "-", exc.detail)
            return ChatResponse(
                reply=_chat_ai_fallback_reply(use_lang),
                summary=payload.summary or "",
                source="fallback",
                confidence=0.0,
            )
        raise
    try:
        prompt = _build_chat_prompt(
            use_lang,
            payload.profile or {},
            payload.days or [],
            payload.today_meals or [],
            payload.summary,
            payload.context,
        )
        messages = [{"role": "system", "content": prompt}]
        for msg in payload.messages:
            role = msg.role if msg.role in {"user", "assistant"} else "user"
            messages.append({"role": role, "content": msg.content})
        response = _client.chat.completions.create(
            model=OPENAI_MODEL,
            messages=messages,
            temperature=0.4,
        )
        text = response.choices[0].message.content or ""
        data = _parse_json(text)
        if not isinstance(data, dict) or "reply" not in data:
            # Fallback: treat raw text as reply, allow empty summary
            data = {
                "reply": text.strip(),
                "summary": payload.summary or "",
            }
        elif "summary" not in data:
            data["summary"] = payload.summary or ""
        usage = response.usage
        usage_data = None
        if usage is not None:
            usage_data = {
                "input_tokens": usage.prompt_tokens,
                "output_tokens": usage.completion_tokens,
                "total_tokens": usage.total_tokens,
            }
        cost_estimate = None
        if usage_data is not None:
            cost_estimate = _estimate_cost_usd(
                int(usage_data.get("input_tokens") or 0),
                int(usage_data.get("output_tokens") or 0),
            )
        _append_usage(
            {
                "id": str(uuid.uuid4()),
                "created_at": datetime.now(timezone.utc).isoformat(),
                "model": OPENAI_MODEL,
                "lang": use_lang,
                "source": "chat",
                "input_tokens": int(usage_data.get("input_tokens") or 0) if usage_data else 0,
                "output_tokens": int(usage_data.get("output_tokens") or 0) if usage_data else 0,
                "total_tokens": int(usage_data.get("total_tokens") or 0) if usage_data else 0,
                "cost_estimate_usd": cost_estimate,
            }
        )
        _increment_daily_count()
        return ChatResponse(
            reply=str(data.get("reply", "")).strip(),
            summary=str(data.get("summary", "")).strip(),
            source="ai",
            confidence=data.get("confidence"),
        )
    except HTTPException as exc:
        if exc.detail in {"ai_failed", "ai_invalid_response"}:
            logging.warning("Chat AI error: user=%s reason=%s", user_id or "-", exc.detail)
            return ChatResponse(
                reply=_chat_ai_fallback_reply(use_lang),
                summary=payload.summary or "",
                source="fallback",
                confidence=0.0,
            )
        raise
    except Exception as exc:
        global _last_ai_error
        _last_ai_error = str(exc)
        logging.exception("Chat failed: %s", exc)
        raise HTTPException(status_code=502, detail="ai_failed")

@app.get("/access_status")
def access_status(_auth: dict = Depends(_require_auth)):
    if _auth.get("whitelisted"):
        return {
            "trial_active": True,
            "trial_start": None,
            "trial_end": None,
            "whitelisted": True,
        }
    trial_start = _auth.get("trial_start")
    if trial_start is None:
        trial_start = datetime.now(timezone.utc)
    trial_end = trial_start + timedelta(days=TRIAL_DAYS)
    return {
        "trial_active": datetime.now(timezone.utc) <= trial_end,
        "trial_start": trial_start.isoformat(),
        "trial_end": trial_end.isoformat(),
        "whitelisted": False,
    }



@app.get("/", response_class=HTMLResponse)
def root():
    deep_link = APP_DEEPLINK_URL
    return f"""<!doctype html>
<html lang="zh-Hant">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Food AI</title>
    <style>
      :root {{ color-scheme: light; }}
      body {{ margin:0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Noto Sans', sans-serif; background: #f6fbf8; color:#1f2a24; }}
      .wrap {{ max-width: 680px; margin: 0 auto; padding: 48px 24px; }}
      .card {{ background: #ffffff; border-radius: 20px; box-shadow: 0 10px 30px rgba(26,64,38,0.08); padding: 28px; }}
      .title {{ font-size: 28px; font-weight: 700; margin: 0 0 8px; }}
      .subtitle {{ font-size: 16px; color: #4c5d52; margin: 0 0 18px; }}
      .badge {{ display:inline-flex; align-items:center; gap:8px; padding: 8px 12px; background:#eaf6ef; border-radius: 999px; font-size: 14px; color:#2f5f41; }}
      .btn {{ display:inline-block; margin-top:18px; padding: 12px 18px; background:#2db26b; color:white; text-decoration:none; border-radius: 12px; font-weight:600; }}
      .hint {{ margin-top: 10px; font-size: 13px; color:#6b7b72; }}
      .emoji {{ font-size: 30px; }}
    </style>
  </head>
  <body>
    <div class="wrap">
      <div class="card">
        <div class="badge"><span class="emoji">🍽️</span> Food AI</div>
        <h1 class="title">嗨，這裡是 Food AI 服務頁</h1>
        <p class="subtitle">如果你是要回到 App，點下面按鈕就能回去啦！</p>
        <a class="btn" href="{deep_link}">回到 App</a>
        <div class="hint">若沒有自動打開 App，請確認已安裝或使用 iOS 開啟。</div>
      </div>
    </div>
  </body>
</html>"""

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
        "last_ai_error": _last_ai_error if RETURN_AI_ERROR else None,
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

