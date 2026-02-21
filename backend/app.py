from fastapi import FastAPI, UploadFile, File, Query, Form, Request, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Any, Dict, Optional, List
from dotenv import load_dotenv, dotenv_values
from pathlib import Path
from openai import OpenAI
import logging
import asyncio
import base64
import json
import os
import re
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

def _parse_origins(value: str | None) -> list[str]:
    if not value:
        return []
    parts = [v.strip() for v in value.split(",")]
    return [p for p in parts if p]


_default_origins = {
    "https://sean4437.github.io",
    "capacitor://localhost",
    "http://localhost",
    "http://localhost:3000",
    "http://127.0.0.1:3000",
}

ALLOWED_ORIGINS = set(_parse_origins(os.getenv("ALLOWED_ORIGINS"))) or _default_origins

app.add_middleware(
    CORSMiddleware,
    allow_origins=list(ALLOWED_ORIGINS),
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


class FoodSearchItem(BaseModel):
    food_id: str
    food_name: str
    alias: Optional[str] = None
    lang: Optional[str] = None
    calorie_range: str
    macros: Dict[str, float]
    food_items: Optional[List[str]] = None
    judgement_tags: Optional[List[str]] = None
    dish_summary: Optional[str] = None
    suggestion: str
    source: str = "catalog"
    nutrition_source: str = "catalog"
    reference_used: Optional[str] = None
    image_url: Optional[str] = None
    thumb_url: Optional[str] = None
    image_source: Optional[str] = None
    image_license: Optional[str] = None
    is_beverage: Optional[bool] = None
    is_food: Optional[bool] = True
    match_score: Optional[float] = None


class FoodSearchResponse(BaseModel):
    items: List[FoodSearchItem]


class FoodSearchMissRequest(BaseModel):
    query: str
    lang: Optional[str] = None
    source: Optional[str] = None


class FoodSearchMissTopItem(BaseModel):
    query_norm: str
    sample_query: str
    lang: str
    miss_count: int
    last_seen_at: Optional[str] = None


class FoodSearchMissTopResponse(BaseModel):
    days: int
    items: List[FoodSearchMissTopItem]

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
TEST_BYPASS_EMAILS = {
    email.strip().lower()
    for email in os.getenv("TEST_BYPASS_EMAILS", "").split(",")
    if email.strip()
}
TRIAL_DAYS = int(os.getenv("TRIAL_DAYS", "2"))
ADMIN_API_KEY = os.getenv("ADMIN_API_KEY", "")
_AI_ENTITLEMENTS = (
    "ai_analyze",
    "ai_chat",
    "ai_summary",
    "ai_suggest",
)

_client = OpenAI(api_key=API_KEY) if API_KEY else None
logging.basicConfig(level=logging.INFO)
_last_ai_error: Optional[str] = None
_jwks_client: Optional[PyJWKClient] = None
_supabase_http_client: Optional[httpx.Client] = None
_catalog_lang_active_filter_supported: Optional[bool] = None
_chat_rate_state: dict[str, list[float]] = {}
_chat_rate_limit = int(os.getenv("CHAT_RATE_LIMIT_PER_MIN", "5"))
_chat_rate_window_sec = int(os.getenv("CHAT_RATE_WINDOW_SEC", "60"))
_analysis_rate_state: dict[str, list[float]] = {}
_analysis_rate_limit = int(os.getenv("ANALYZE_RATE_LIMIT_PER_MIN", "6"))
_analysis_rate_window_sec = int(os.getenv("ANALYZE_RATE_WINDOW_SEC", "60"))


@app.on_event("shutdown")
def _shutdown_clients() -> None:
    global _supabase_http_client
    if _supabase_http_client is not None:
        try:
            _supabase_http_client.close()
        except Exception:
            pass
        _supabase_http_client = None


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
            "- 單位食物規則：水餃/煎餃/鍋貼/湯包/小籠包/餛飩要以顆數估算，不要把 1 顆當整份；若看得到顆數請用顆數，否則用常見份量（約 8-12 顆）\n"
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
        "- Unit-food rule: for dumplings/potstickers/xiao long bao/wonton, estimate by piece count (not as a single full serving); if count is unclear, assume a typical 8-12 pieces\n"
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
            "- 單位食物規則：水餃/煎餃/鍋貼/湯包/小籠包/餛飩要以顆數估算，不要把 1 顆當整份；若名稱含顆數請套用，否則用常見份量（約 8-12 顆）\n"
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
        "- Unit-food rule: for dumplings/potstickers/xiao long bao/wonton, estimate by piece count (not one whole serving per piece); if count is missing, assume a typical 8-12 pieces\n"
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


def _get_supabase_http_client() -> httpx.Client:
    global _supabase_http_client
    if _supabase_http_client is None:
        _supabase_http_client = httpx.Client(timeout=10)
    return _supabase_http_client


def _normalize_food_query(value: str) -> str:
    return " ".join((value or "").strip().lower().split())


_BEVERAGE_HINT_TOKENS = (
    "茶",
    "咖啡",
    "豆漿",
    "豆漿紅茶",
    "豆漿奶茶",
    "豆奶",
    "豆乳",
    "奶茶",
    "鮮奶茶",
    "烏龍奶",
    "鮮奶綠",
    "鮮奶紅",
    "果茶",
    "蜂蜜",
    "檸檬",
    "百香",
    "芭樂",
    "葡萄柚",
    "紅柚",
    "楊枝",
    "荔枝",
    "柳橙",
    "金桔",
    "梅綠",
    "青梅",
    "冬瓜檸檬",
    "多多綠",
    "拿鐵",
    "美式",
    "冷萃",
    "卡布",
    "卡布奇諾",
    "摩卡",
    "瑪奇朵",
    "馥列白",
    "西西里",
    "可可",
    "果汁",
    "飲料",
    "飲",
    "milk tea",
    "latte",
    "americano",
    "espresso",
    "cappuccino",
    "flat white",
    "macchiato",
    "mocha",
    "cold brew",
    "coldbrew",
    "tea",
    "coffee",
    "juice",
    "drink",
    "beverage",
    "boba",
    "smoothie",
    "50嵐",
    "五十嵐",
    "清心",
    "可不可",
    "麻古",
    "迷客夏",
    "茶湯會",
    "五桐號",
    "龜記",
    "得正",
    "萬波",
    "一沐日",
    "再睡5分鐘",
    "老賴",
    "大苑子",
    "珍煮丹",
    "上宇林",
    "鶴茶樓",
    "先喝道",
    "日出茶太",
    "茶聚",
    "樂法",
    "喫茶小舖",
    "春水堂",
    "龍角",
    "茶魔",
    "coco",
    "comebuy",
    "50lan",
    "kebuke",
    "milksha",
    "tp tea",
    "woo tea",
    "wanpo",
    "nap tea",
    "chatime",
    "dayungs",
    "jenjudan",
    "kung fu tea",
)

_BEVERAGE_TOPPINGS = (
    {
        "tokens": ("珍珠", "小珍珠", "白玉", "黑糖珍珠", "波霸", "粉圓", "pearl", "boba", "tapioca"),
        "zh": "珍珠",
        "en": "boba",
        "protein": 0.0,
        "carbs": 35.0,
        "fat": 0.0,
        "sodium": 25.0,
    },
    {
        "tokens": ("粉角", "small boba", "mini boba"),
        "zh": "粉角",
        "en": "mini boba",
        "protein": 0.0,
        "carbs": 24.0,
        "fat": 0.0,
        "sodium": 12.0,
    },
    {
        "tokens": ("粉條", "rice noodle jelly", "rice noodles"),
        "zh": "粉條",
        "en": "rice noodle jelly",
        "protein": 0.0,
        "carbs": 21.0,
        "fat": 0.0,
        "sodium": 10.0,
    },
    {
        "tokens": ("椰果", "coconut jelly"),
        "zh": "椰果",
        "en": "coconut jelly",
        "protein": 0.0,
        "carbs": 17.0,
        "fat": 0.0,
        "sodium": 8.0,
    },
    {
        "tokens": ("布丁", "pudding"),
        "zh": "布丁",
        "en": "pudding",
        "protein": 2.0,
        "carbs": 18.0,
        "fat": 3.0,
        "sodium": 70.0,
    },
    {
        "tokens": ("仙草", "grass jelly"),
        "zh": "仙草",
        "en": "grass jelly",
        "protein": 0.0,
        "carbs": 8.0,
        "fat": 0.0,
        "sodium": 8.0,
    },
    {
        "tokens": ("奶蓋", "奶霜", "芝士奶蓋", "cheese foam", "milk foam", "foam"),
        "zh": "奶蓋",
        "en": "cheese foam",
        "protein": 2.0,
        "carbs": 6.0,
        "fat": 8.0,
        "sodium": 90.0,
    },
    {
        "tokens": ("愛玉", "aiyu"),
        "zh": "愛玉",
        "en": "aiyu jelly",
        "protein": 0.0,
        "carbs": 6.0,
        "fat": 0.0,
        "sodium": 5.0,
    },
    {
        "tokens": ("寒天", "寒天晶球", "agar", "konjac", "蒟蒻"),
        "zh": "寒天",
        "en": "agar jelly",
        "protein": 0.0,
        "carbs": 4.0,
        "fat": 0.0,
        "sodium": 6.0,
    },
    {
        "tokens": ("蒟蒻", "konjac"),
        "zh": "蒟蒻",
        "en": "konjac jelly",
        "protein": 0.0,
        "carbs": 5.0,
        "fat": 0.0,
        "sodium": 6.0,
    },
    {
        "tokens": ("紅豆", "red bean"),
        "zh": "紅豆",
        "en": "red bean",
        "protein": 2.0,
        "carbs": 24.0,
        "fat": 0.5,
        "sodium": 5.0,
    },
    {
        "tokens": ("綠豆", "mung bean", "green bean"),
        "zh": "綠豆",
        "en": "mung bean",
        "protein": 3.0,
        "carbs": 22.0,
        "fat": 0.5,
        "sodium": 5.0,
    },
    {
        "tokens": ("芋圓", "taro ball", "taro balls"),
        "zh": "芋圓",
        "en": "taro balls",
        "protein": 1.0,
        "carbs": 20.0,
        "fat": 0.8,
        "sodium": 8.0,
    },
    {
        "tokens": ("地瓜圓", "sweet potato ball", "sweet potato balls"),
        "zh": "地瓜圓",
        "en": "sweet potato balls",
        "protein": 1.0,
        "carbs": 20.0,
        "fat": 0.5,
        "sodium": 8.0,
    },
    {
        "tokens": ("粉粿", "fen guo", "rice jelly"),
        "zh": "粉粿",
        "en": "rice jelly",
        "protein": 0.0,
        "carbs": 24.0,
        "fat": 0.0,
        "sodium": 10.0,
    },
    {
        "tokens": ("蘆薈", "aloe"),
        "zh": "蘆薈",
        "en": "aloe",
        "protein": 0.0,
        "carbs": 8.0,
        "fat": 0.0,
        "sodium": 5.0,
    },
    {
        "tokens": ("西米露", "sago"),
        "zh": "西米露",
        "en": "sago pearls",
        "protein": 0.5,
        "carbs": 22.0,
        "fat": 0.0,
        "sodium": 5.0,
    },
    {
        "tokens": ("茶凍", "tea jelly"),
        "zh": "茶凍",
        "en": "tea jelly",
        "protein": 0.0,
        "carbs": 8.0,
        "fat": 0.0,
        "sodium": 6.0,
    },
    {
        "tokens": ("咖啡凍", "coffee jelly"),
        "zh": "咖啡凍",
        "en": "coffee jelly",
        "protein": 0.0,
        "carbs": 9.0,
        "fat": 0.0,
        "sodium": 6.0,
    },
    {
        "tokens": ("綠茶凍", "green tea jelly"),
        "zh": "綠茶凍",
        "en": "green tea jelly",
        "protein": 0.0,
        "carbs": 8.0,
        "fat": 0.0,
        "sodium": 6.0,
    },
    {
        "tokens": ("蜜香凍", "honey jelly"),
        "zh": "蜜香凍",
        "en": "honey jelly",
        "protein": 0.0,
        "carbs": 11.0,
        "fat": 0.0,
        "sodium": 6.0,
    },
    {
        "tokens": ("荔枝凍", "lychee jelly"),
        "zh": "荔枝凍",
        "en": "lychee jelly",
        "protein": 0.0,
        "carbs": 12.0,
        "fat": 0.0,
        "sodium": 6.0,
    },
    {
        "tokens": ("黑糖凍", "brown sugar jelly"),
        "zh": "黑糖凍",
        "en": "brown sugar jelly",
        "protein": 0.0,
        "carbs": 12.0,
        "fat": 0.0,
        "sodium": 8.0,
    },
    {
        "tokens": ("桂花凍", "osmanthus jelly"),
        "zh": "桂花凍",
        "en": "osmanthus jelly",
        "protein": 0.0,
        "carbs": 10.0,
        "fat": 0.0,
        "sodium": 8.0,
    },
    {
        "tokens": ("杏仁凍", "almond jelly"),
        "zh": "杏仁凍",
        "en": "almond jelly",
        "protein": 1.0,
        "carbs": 9.0,
        "fat": 1.0,
        "sodium": 8.0,
    },
    {
        "tokens": ("奶酪", "panna cotta"),
        "zh": "奶酪",
        "en": "panna cotta",
        "protein": 2.0,
        "carbs": 12.0,
        "fat": 4.0,
        "sodium": 30.0,
    },
    {
        "tokens": ("芋泥", "taro paste"),
        "zh": "芋泥",
        "en": "taro paste",
        "protein": 1.5,
        "carbs": 20.0,
        "fat": 1.0,
        "sodium": 12.0,
    },
    {
        "tokens": ("奇亞籽", "chia seeds"),
        "zh": "奇亞籽",
        "en": "chia seeds",
        "protein": 1.5,
        "carbs": 5.0,
        "fat": 2.0,
        "sodium": 2.0,
    },
    {
        "tokens": ("葡萄柚果粒", "grapefruit pulp"),
        "zh": "葡萄柚果粒",
        "en": "grapefruit pulp",
        "protein": 0.5,
        "carbs": 9.0,
        "fat": 0.0,
        "sodium": 2.0,
    },
    {
        "tokens": ("爆爆珠", "啵啵珠", "popping boba"),
        "zh": "爆爆珠",
        "en": "popping boba",
        "protein": 0.0,
        "carbs": 18.0,
        "fat": 0.0,
        "sodium": 12.0,
    },
)

_ZH_NUMERIC_MAP = {
    "零": 0,
    "一": 1,
    "二": 2,
    "兩": 2,
    "三": 3,
    "四": 4,
    "五": 5,
    "六": 6,
    "七": 7,
    "八": 8,
    "九": 9,
    "十": 10,
}

_BEVERAGE_BASE_CANDIDATES = (
    (("檸檬綠茶", "lemon green tea", "lemon tea"), "檸檬綠茶"),
    (("檸檬紅茶",), "紅茶"),
    (("豆漿紅茶", "豆乳紅茶", "soy black tea"), "無糖豆漿"),
    (("豆漿奶茶", "豆乳奶茶", "soy milk tea"), "無糖豆漿"),
    (("豆漿", "soy milk", "soymilk"), "無糖豆漿"),
    (("鮮奶茶", "fresh milk tea"), "奶茶"),
    (("鮮奶綠",), "綠茶"),
    (("鮮奶紅",), "紅茶"),
    (("奶茶", "milk tea"), "奶茶"),
    (("烏龍奶", "烏龍奶茶"), "奶茶"),
    (("拿鐵", "latte"), "拿鐵"),
    (("燕麥拿鐵", "oat latte", "oatmilk latte"), "拿鐵"),
    (("美式咖啡", "americano"), "美式咖啡"),
    (("冷萃咖啡", "cold brew", "coldbrew"), "美式咖啡"),
    (("義式濃縮", "濃縮咖啡", "espresso"), "美式咖啡"),
    (("卡布奇諾", "卡布", "cappuccino"), "拿鐵"),
    (("馥列白", "flat white"), "拿鐵"),
    (("摩卡", "mocha"), "拿鐵"),
    (("焦糖瑪奇朵", "瑪奇朵", "macchiato", "caramel macchiato"), "拿鐵"),
    (("西西里咖啡", "西西里", "sicilian coffee"), "美式咖啡"),
    (("抹茶拿鐵", "matcha latte"), "拿鐵"),
    (("焙茶拿鐵", "hojicha latte"), "拿鐵"),
    (("黑糖鮮奶",), "奶茶"),
    (("黑糖珍珠鮮奶",), "奶茶"),
    (("可可鮮奶", "cocoa milk"), "奶茶"),
    (("熟成紅茶", "大正紅茶", "老實人紅茶"), "紅茶"),
    (("伯爵紅茶",), "紅茶"),
    (("阿薩姆紅茶",), "紅茶"),
    (("蜜香紅茶",), "紅茶"),
    (("英式紅茶",), "紅茶"),
    (("多多綠", "yakult green tea"), "綠茶"),
    (("翡翠檸檬",), "檸檬綠茶"),
    (("海神",), "烏龍茶"),
    (("雙q",), "奶茶"),
    (("碧螺春",), "綠茶"),
    (("金萱", "jin xuan", "jinxuan"), "烏龍茶"),
    (("觀音", "tieguanyin"), "烏龍茶"),
    (("雪花冷露",), "奶茶"),
    (("百香", "passion fruit"), "綠茶"),
    (("蜂蜜檸檬",), "檸檬綠茶"),
    (("蜂蜜綠茶",), "綠茶"),
    (("蜂蜜青茶",), "青茶"),
    (("紅柚", "grapefruit"), "綠茶"),
    (("葡萄柚綠茶",), "綠茶"),
    (("柳橙綠茶",), "綠茶"),
    (("金桔檸檬",), "檸檬綠茶"),
    (("金桔綠茶",), "綠茶"),
    (("冬瓜青茶",), "青茶"),
    (("楊枝甘露", "mango pomelo sago"), "奶茶"),
    (("百香雙響炮",), "綠茶"),
    (("水果茶", "綜合果茶"), "綠茶"),
    (("洛神花茶",), "綠茶"),
    (("烏梅汁", "酸梅汁"), "綠茶"),
    (("麥香紅茶",), "紅茶"),
    (("麥茶",), "綠茶"),
    (("蘋果紅萱", "蘋果紅茶"), "紅茶"),
    (("鳳梨青茶",), "青茶"),
    (("西瓜青茶",), "青茶"),
    (("四季春",), "青茶"),
    (("春芽",), "綠茶"),
    (("冬瓜檸檬",), "檸檬綠茶"),
    (("青茶", "green tea"), "青茶"),
    (("紅茶", "black tea"), "紅茶"),
    (("綠茶",), "綠茶"),
    (("烏龍", "oolong"), "烏龍茶"),
    (("冬瓜", "winter melon"), "冬瓜茶"),
    (("咖啡", "coffee", "americano"), "美式咖啡"),
)

_FRUIT_HINT_TOKENS = (
    "檸檬",
    "百香",
    "葡萄柚",
    "紅柚",
    "芭樂",
    "芒果",
    "鳳梨",
    "蘋果",
    "白桃",
    "荔枝",
    "柳橙",
    "金桔",
    "桑葚",
    "梅子",
    "烏梅",
    "水蜜桃",
    "楊枝",
    "果茶",
)


def _contains_any_token(text: str, tokens: tuple[str, ...]) -> bool:
    return any(token in text for token in tokens)


def _is_probably_beverage_text(text: str) -> bool:
    normalized = _normalize_food_query(text)
    if not normalized:
        return False
    return _contains_any_token(normalized, _BEVERAGE_HINT_TOKENS)


def _strip_beverage_modifiers(text: str) -> str:
    value = _normalize_food_query(text)
    if not value:
        return ""

    patterns = [
        r"(特大杯|超大杯|大杯|中杯|小杯|x-large|xlarge|large|medium|small|xl|lg|md|sm)",
        r"(\d{2,4}\s*(ml|cc))",
        r"(無糖|微糖|少糖|半糖|全糖|正常糖|去糖|減糖|不加糖|sugar[\s\-]*free|no sugar|light sugar|less sugar|half sugar|full sugar|regular sugar|unsweetened)",
        r"([一二兩三四五六七八九十\d]{1,3}\s*分糖)",
        r"(\d{1,3}\s*%?\s*(糖|sugar))",
        r"(去冰|少冰|微冰|正常冰|常溫|溫|熱飲|熱的|熱|no ice|less ice|light ice|regular ice|room temperature|warm|hot)",
        r"(加珍珠|加小珍珠|加白玉|加波霸|加粉圓|加粉角|加粉條|加椰果|加布丁|加仙草|加奶蓋|加奶霜|加芝士奶蓋|加愛玉|加寒天|加蒟蒻|加紅豆|加綠豆|加芋圓|加地瓜圓|加粉粿|加蘆薈|加西米露|加茶凍|加咖啡凍|加綠茶凍|加蜜香凍|加荔枝凍|加黑糖凍|加桂花凍|加杏仁凍|加奶酪|加芋泥|加奇亞籽|加葡萄柚果粒|加爆爆珠|加啵啵珠|with\s+boba|with\s+mini boba|with\s+pearls?|with\s+coconut jelly|with\s+pudding|with\s+grass jelly|with\s+foam|with\s+milk foam|with\s+aiyu|with\s+agar|with\s+konjac|with\s+red bean|with\s+mung bean|with\s+taro balls?|with\s+aloe|with\s+sago|with\s+tea jelly|with\s+coffee jelly|with\s+green tea jelly|with\s+honey jelly|with\s+lychee jelly|with\s+brown sugar jelly|with\s+osmanthus jelly|with\s+almond jelly|with\s+panna cotta|with\s+taro paste|with\s+chia seeds|with\s+grapefruit pulp|with\s+popping boba)",
        r"(50嵐|五十嵐|清心福全|清心|可不可熟成紅茶|可不可|麻古茶坊|麻古|迷客夏|茶湯會|五桐號|龜記|得正|萬波|一沐日|再睡5分鐘|老賴茶棧|老賴|大苑子|珍煮丹|上宇林|鶴茶樓|先喝道|日出茶太|茶聚|樂法|喫茶小舖|春水堂|龍角|茶魔|coco都可|coco|comebuy|50lan|chingshin|kebuke|macu|milksha|tp\s*tea|woo\s*tea|wanpo|nap\s*tea|laolai|dayungs|jenjudan|chatime|kung\s*fu\s*tea)",
    ]
    for pattern in patterns:
        value = re.sub(pattern, " ", value)

    value = re.sub(r"[\s,;:+/_\-]+", " ", value)
    return value.strip()


def _extract_beverage_base_candidates(text: str) -> list[str]:
    normalized = _normalize_food_query(text)
    if not normalized:
        return []
    candidates: list[str] = []
    seen: set[str] = set()

    def add(value: str) -> None:
        token = _normalize_food_query(value)
        if not token or token in seen:
            return
        seen.add(token)
        candidates.append(token)

    for tokens, canonical in _BEVERAGE_BASE_CANDIDATES:
        if any(token in normalized for token in tokens):
            add(canonical)

    if any(token in normalized for token in _FRUIT_HINT_TOKENS):
        if "青茶" in normalized or "四季春" in normalized:
            add("青茶")
        elif "紅茶" in normalized:
            add("紅茶")
        elif "烏龍" in normalized or "金萱" in normalized or "觀音" in normalized:
            add("烏龍茶")
        else:
            add("綠茶")

    if "豆漿" in normalized or "豆乳" in normalized or "soy" in normalized:
        add("無糖豆漿")
    if "奶茶" in normalized or "鮮奶" in normalized or "milk tea" in normalized:
        add("奶茶")
    if any(
        token in normalized
        for token in (
            "拿鐵",
            "latte",
            "卡布",
            "卡布奇諾",
            "cappuccino",
            "馥列白",
            "flat white",
            "瑪奇朵",
            "macchiato",
            "摩卡",
            "mocha",
            "燕麥拿鐵",
            "oat latte",
            "oatmilk latte",
        )
    ):
        add("拿鐵")
    if any(
        token in normalized
        for token in (
            "美式",
            "咖啡",
            "coffee",
            "americano",
            "冷萃",
            "cold brew",
            "coldbrew",
            "濃縮",
            "espresso",
            "西西里",
        )
    ):
        add("美式咖啡")
    if "紅茶" in normalized or "black tea" in normalized:
        add("紅茶")
    if "綠茶" in normalized or "green tea" in normalized:
        add("綠茶")

    # Weak fallback for brand menu item names that still contain generic tea words.
    if "茶" in normalized and not candidates:
        add("青茶")

    return candidates[:8]


def _food_search_query_candidates(raw_query: str) -> list[str]:
    normalized = _normalize_food_query(raw_query)
    if not normalized:
        return []
    candidates: list[str] = []
    seen: set[str] = set()

    def add(value: str) -> None:
        token = _normalize_food_query(value)
        if not token or token in seen:
            return
        seen.add(token)
        candidates.append(token)

    add(normalized)
    add(normalized.replace(" ", ""))

    if _is_probably_beverage_text(normalized):
        stripped = _strip_beverage_modifiers(normalized)
        add(stripped)
        add(stripped.replace(" ", ""))
        for inferred in _extract_beverage_base_candidates(normalized):
            add(inferred)
        for inferred in _extract_beverage_base_candidates(stripped):
            add(inferred)

    return candidates[:6]


def _parse_zh_numeric_token(token: str) -> Optional[int]:
    text = token.strip()
    if not text:
        return None
    if text.isdigit():
        return int(text)
    if text == "十":
        return 10
    if len(text) == 2 and text[0] == "十" and text[1] in _ZH_NUMERIC_MAP:
        return 10 + int(_ZH_NUMERIC_MAP[text[1]])
    if len(text) == 2 and text[1] == "十" and text[0] in _ZH_NUMERIC_MAP:
        return int(_ZH_NUMERIC_MAP[text[0]]) * 10
    if len(text) == 3 and text[1] == "十" and text[0] in _ZH_NUMERIC_MAP and text[2] in _ZH_NUMERIC_MAP:
        return (int(_ZH_NUMERIC_MAP[text[0]]) * 10) + int(_ZH_NUMERIC_MAP[text[2]])
    if len(text) == 1 and text in _ZH_NUMERIC_MAP:
        return int(_ZH_NUMERIC_MAP[text])
    return None


def _beverage_profile_defaults(food_name_norm: str) -> dict[str, Any]:
    if any(token in food_name_norm for token in ("果汁", "juice")):
        return {
            "base_ml": 500.0,
            "default_sugar_ratio": 1.0,
            "full_sugar_carbs": 0.0,
            "sugar_adjustable": False,
        }
    if any(token in food_name_norm for token in ("豆漿", "soy milk", "soymilk")):
        return {
            "base_ml": 500.0,
            "default_sugar_ratio": 0.4,
            "full_sugar_carbs": 16.0,
            "sugar_adjustable": True,
        }
    if any(token in food_name_norm for token in ("奶茶", "milk tea")):
        return {
            "base_ml": 500.0,
            "default_sugar_ratio": 1.0,
            "full_sugar_carbs": 28.0,
            "sugar_adjustable": True,
        }
    if any(token in food_name_norm for token in ("摩卡", "mocha")):
        return {
            "base_ml": 500.0,
            "default_sugar_ratio": 0.6,
            "full_sugar_carbs": 28.0,
            "sugar_adjustable": True,
        }
    if any(
        token in food_name_norm
        for token in (
            "拿鐵",
            "latte",
            "卡布",
            "卡布奇諾",
            "cappuccino",
            "馥列白",
            "flat white",
            "瑪奇朵",
            "macchiato",
            "燕麥拿鐵",
            "oat latte",
            "oatmilk latte",
        )
    ):
        return {
            "base_ml": 500.0,
            "default_sugar_ratio": 0.2,
            "full_sugar_carbs": 20.0,
            "sugar_adjustable": True,
        }
    if any(token in food_name_norm for token in ("可可", "cocoa", "chocolate")):
        return {
            "base_ml": 500.0,
            "default_sugar_ratio": 1.0,
            "full_sugar_carbs": 0.0,
            "sugar_adjustable": False,
        }
    if any(
        token in food_name_norm
        for token in (
            "咖啡",
            "coffee",
            "americano",
            "美式",
            "冷萃",
            "cold brew",
            "coldbrew",
            "濃縮",
            "espresso",
            "西西里",
        )
    ):
        return {
            "base_ml": 500.0,
            "default_sugar_ratio": 0.0,
            "full_sugar_carbs": 24.0,
            "sugar_adjustable": True,
        }
    if any(token in food_name_norm for token in ("茶",)):
        return {
            "base_ml": 500.0,
            "default_sugar_ratio": 0.0,
            "full_sugar_carbs": 35.0,
            "sugar_adjustable": True,
        }
    return {
        "base_ml": 500.0,
        "default_sugar_ratio": 0.5,
        "full_sugar_carbs": 24.0,
        "sugar_adjustable": True,
    }


def _pick_bool(value: Any, fallback: bool) -> bool:
    if isinstance(value, bool):
        return value
    if isinstance(value, str):
        normalized = value.strip().lower()
        if normalized in {"true", "1", "yes", "on"}:
            return True
        if normalized in {"false", "0", "no", "off"}:
            return False
    return fallback


def _pick_float(value: Any, fallback: float) -> float:
    parsed = _safe_float(value)
    if parsed is None:
        return fallback
    return parsed


def _parse_beverage_size(query_norm: str, base_ml: float, lang: str) -> tuple[float, str, bool]:
    ml_match = re.search(r"(\d{2,4})\s*(ml|cc)", query_norm)
    if ml_match is not None:
        amount = int(ml_match.group(1))
        if 120 <= amount <= 1200 and base_ml > 0:
            factor = amount / base_ml
            label = f"{amount} ml"
            return factor, label, True

    rules = (
        (("特大杯", "超大杯", "x-large", "xlarge", "xl"), 1.45, "特大杯", "x-large"),
        (("大杯", "large", "lg"), 1.25, "大杯", "large"),
        (("中杯", "medium", "md"), 1.0, "中杯", "medium"),
        (("小杯", "small", "sm"), 0.8, "小杯", "small"),
    )
    for tokens, factor, zh_label, en_label in rules:
        if any(token in query_norm for token in tokens):
            return factor, (zh_label if lang == "zh-TW" else en_label), True

    default_label = "中杯" if lang == "zh-TW" else "medium"
    return 1.0, default_label, False


def _parse_beverage_sugar(query_norm: str, default_ratio: float, lang: str) -> tuple[float, str, bool]:
    explicit = False
    ratio = max(0.0, min(default_ratio, 1.0))

    if any(token in query_norm for token in ("無糖", "不加糖", "去糖", "no sugar", "sugar-free", "sugar free", "unsweetened")):
        ratio = 0.0
        explicit = True
    elif any(token in query_norm for token in ("微糖", "light sugar")):
        ratio = 0.25
        explicit = True
    elif any(token in query_norm for token in ("少糖", "less sugar")):
        ratio = 0.3
        explicit = True
    elif any(token in query_norm for token in ("半糖", "half sugar")):
        ratio = 0.5
        explicit = True
    elif any(token in query_norm for token in ("七分糖",)):
        ratio = 0.7
        explicit = True
    elif any(token in query_norm for token in ("全糖", "正常糖", "full sugar", "regular sugar")):
        ratio = 1.0
        explicit = True

    if not explicit:
        zh_fraction = re.search(r"([一二兩三四五六七八九十\d]{1,3})\s*分糖", query_norm)
        if zh_fraction is not None:
            number = _parse_zh_numeric_token(zh_fraction.group(1))
            if number is not None:
                ratio = max(0.0, min(number / 10.0, 1.0))
                explicit = True

    if not explicit:
        percent_match = re.search(r"(\d{1,3})\s*%?\s*(糖|sugar)", query_norm)
        if percent_match is not None:
            number = int(percent_match.group(1))
            ratio = max(0.0, min(number / 100.0, 1.0))
            explicit = True

    percent = int(round(max(0.0, min(ratio, 1.0)) * 100))
    label = f"{percent}%糖" if lang == "zh-TW" else f"{percent}% sugar"
    return ratio, label, explicit


def _parse_beverage_ice(query_norm: str, lang: str) -> tuple[str, bool]:
    rules = (
        (("去冰", "no ice"), "去冰", "no ice"),
        (("少冰", "less ice"), "少冰", "less ice"),
        (("微冰", "light ice"), "微冰", "light ice"),
        (("正常冰", "regular ice"), "正常冰", "regular ice"),
        (("常溫", "room temperature"), "常溫", "room temperature"),
        (("熱飲", "熱的", "熱", "hot", "warm"), "熱飲", "hot"),
    )
    for tokens, zh_label, en_label in rules:
        if any(token in query_norm for token in tokens):
            return (zh_label if lang == "zh-TW" else en_label), True
    return "", False


def _parse_beverage_toppings(query_norm: str, lang: str) -> list[dict[str, Any]]:
    matched: list[dict[str, Any]] = []
    seen: set[str] = set()
    for topping in _BEVERAGE_TOPPINGS:
        key = str(topping.get("zh") or topping.get("en") or "")
        if not key:
            continue
        if key in seen:
            continue
        tokens = tuple(str(token) for token in topping.get("tokens") or [])
        if any(token in query_norm for token in tokens):
            seen.add(key)
            matched.append(
                {
                    "name": topping.get("zh") if lang == "zh-TW" else topping.get("en"),
                    "protein": float(topping.get("protein") or 0.0),
                    "carbs": float(topping.get("carbs") or 0.0),
                    "fat": float(topping.get("fat") or 0.0),
                    "sodium": float(topping.get("sodium") or 0.0),
                }
            )
    return matched


def _beverage_calorie_range_from_macros(macros: dict[str, float]) -> str:
    protein = max(0.0, _safe_float(macros.get("protein")) or 0.0)
    carbs = max(0.0, _safe_float(macros.get("carbs")) or 0.0)
    fat = max(0.0, _safe_float(macros.get("fat")) or 0.0)
    kcal = (protein * 4.0) + (carbs * 4.0) + (fat * 9.0)
    if kcal <= 0:
        return "0-20 kcal"
    low = max(0, int(round(kcal * 0.9)))
    high = max(low + 10, int(round(kcal * 1.1)))
    return f"{low}-{high} kcal"


def _build_beverage_formula_summary(
    base_name: str,
    size_label: str,
    sugar_label: str,
    ice_label: str,
    topping_names: list[str],
    lang: str,
) -> str:
    if lang == "zh-TW":
        parts = [f"飲料參數：{base_name}", size_label, sugar_label]
        if topping_names:
            parts.append(f"加料 {', '.join(topping_names)}")
        return "、".join(parts)
    parts = [f"Beverage options: {base_name}", size_label, sugar_label]
    if topping_names:
        parts.append(f"toppings {', '.join(topping_names)}")
    return ", ".join(parts)


def _build_beverage_formula_suggestion(
    carbs: float,
    sugar_ratio: float,
    toppings: list[dict[str, Any]],
    lang: str,
) -> str:
    if lang == "zh-TW":
        if sugar_ratio >= 0.7 or carbs >= 45:
            return "本杯糖量偏高，建議下次改半糖以下，並減少甜點搭配。"
        if toppings:
            return "主要熱量來自加料，若想控熱量可先拿掉加料。"
        return "可優先選低糖與中杯，讓全天熱量更穩定。"
    if sugar_ratio >= 0.7 or carbs >= 45:
        return "Sugar load is high. Next time choose half sugar or less."
    if toppings:
        return "Most extra calories are from toppings. Remove toppings when cutting."
    return "Prefer lower sugar and medium size for steadier daily intake."


def _apply_beverage_formula(
    raw_query: str,
    catalog_row: dict,
    macros: dict[str, float],
    use_lang: str,
) -> Optional[dict[str, Any]]:
    is_beverage = catalog_row.get("is_beverage") if isinstance(catalog_row.get("is_beverage"), bool) else False
    if not is_beverage:
        return None
    query_norm = _normalize_food_query(raw_query)
    if not query_norm or not _is_probably_beverage_text(query_norm):
        return None

    row_profile_raw = catalog_row.get("beverage_profile")
    row_profile: dict[str, Any] = row_profile_raw if isinstance(row_profile_raw, dict) else {}
    name_norm = _normalize_food_query(str(catalog_row.get("food_name") or catalog_row.get("canonical_name") or ""))
    defaults = _beverage_profile_defaults(name_norm)

    base_ml = _pick_float(
        row_profile.get("base_ml", catalog_row.get("beverage_base_ml")),
        float(defaults.get("base_ml", 500.0)),
    )
    if base_ml <= 0:
        base_ml = 500.0
    default_sugar_ratio = max(
        0.0,
        min(
            1.0,
            _pick_float(
                row_profile.get("default_sugar_ratio", catalog_row.get("beverage_default_sugar_ratio")),
                float(defaults.get("default_sugar_ratio", 0.5)),
            ),
        ),
    )
    full_sugar_carbs = max(
        0.0,
        _pick_float(
            row_profile.get("full_sugar_carbs", catalog_row.get("beverage_full_sugar_carbs")),
            float(defaults.get("full_sugar_carbs", 24.0)),
        ),
    )
    sugar_adjustable = _pick_bool(
        row_profile.get("sugar_adjustable", catalog_row.get("beverage_sugar_adjustable")),
        bool(defaults.get("sugar_adjustable", True)),
    )

    size_factor, size_label, has_size = _parse_beverage_size(query_norm, base_ml, use_lang)
    sugar_ratio, sugar_label, has_sugar = _parse_beverage_sugar(query_norm, default_sugar_ratio, use_lang)
    ice_label = ""
    toppings = _parse_beverage_toppings(query_norm, use_lang)
    has_modifier = has_size or has_sugar or bool(toppings)
    if not has_modifier:
        return None

    protein = max(0.0, (_safe_float(macros.get("protein")) or 0.0) * size_factor)
    carbs = max(0.0, (_safe_float(macros.get("carbs")) or 0.0) * size_factor)
    fat = max(0.0, (_safe_float(macros.get("fat")) or 0.0) * size_factor)
    sodium = max(0.0, (_safe_float(macros.get("sodium")) or 0.0) * size_factor)

    if sugar_adjustable and has_sugar and full_sugar_carbs > 0:
        carbs += (sugar_ratio - default_sugar_ratio) * full_sugar_carbs * size_factor
        carbs = max(0.0, carbs)

    topping_names: list[str] = []
    for topping in toppings:
        topping_names.append(str(topping.get("name") or "").strip())
        protein += max(0.0, _safe_float(topping.get("protein")) or 0.0)
        carbs += max(0.0, _safe_float(topping.get("carbs")) or 0.0)
        fat += max(0.0, _safe_float(topping.get("fat")) or 0.0)
        sodium += max(0.0, _safe_float(topping.get("sodium")) or 0.0)

    adjusted_macros = {
        "protein": round(protein, 1),
        "carbs": round(carbs, 1),
        "fat": round(fat, 1),
        "sodium": round(sodium, 1),
    }
    base_name = str(catalog_row.get("food_name") or catalog_row.get("canonical_name") or "").strip()
    if not base_name:
        base_name = raw_query.strip()
    adjusted_items = _catalog_food_items(catalog_row, base_name)
    for topping_name in topping_names:
        if topping_name and topping_name not in adjusted_items:
            adjusted_items.append(topping_name)

    summary = _build_beverage_formula_summary(
        base_name=base_name,
        size_label=size_label,
        sugar_label=sugar_label,
        ice_label=ice_label,
        topping_names=[name for name in topping_names if name],
        lang=use_lang,
    )
    suggestion = _build_beverage_formula_suggestion(
        carbs=adjusted_macros["carbs"],
        sugar_ratio=sugar_ratio,
        toppings=toppings,
        lang=use_lang,
    )

    return {
        "food_name": raw_query.strip() or base_name,
        "calorie_range": _beverage_calorie_range_from_macros(adjusted_macros),
        "macros": adjusted_macros,
        "food_items": adjusted_items[:6],
        "dish_summary": summary,
        "suggestion": suggestion,
    }


def _safe_float(value: Any) -> Optional[float]:
    if isinstance(value, (int, float)):
        return float(value)
    if isinstance(value, str):
        try:
            return float(value.strip())
        except Exception:
            return None
    return None


def _catalog_default_summary(food_name: str, lang: str) -> str:
    if lang == "zh-TW":
        return f"{food_name}（資料庫）"
    return f"{food_name} (catalog)"


def _catalog_default_suggestion(lang: str) -> str:
    if lang == "zh-TW":
        return "來自資料庫估算，可再補充份量或品牌讓結果更準確。"
    return "Estimated from the food catalog. Add portion or brand details for better accuracy."


def _catalog_calorie_range(row: dict) -> str:
    raw = str(row.get("calorie_range") or "").strip()
    if raw:
        return raw
    kcal = _safe_float(row.get("kcal_100g"))
    if kcal is None or kcal <= 0:
        return "0-0 kcal"
    low = max(1, int(round(kcal * 0.9)))
    high = max(low, int(round(kcal * 1.1)))
    return f"{low}-{high} kcal"


def _catalog_macros(row: dict) -> dict[str, float]:
    raw = row.get("macros")
    parsed: dict[str, float] = {}
    if isinstance(raw, dict):
        for key, value in raw.items():
            parsed[str(key)] = _normalize_macro_value(value, str(key))
    if parsed:
        return parsed
    protein = _safe_float(row.get("protein_100g"))
    carbs = _safe_float(row.get("carbs_100g"))
    fat = _safe_float(row.get("fat_100g"))
    sodium = _safe_float(row.get("sodium_mg_100g"))
    return {
        "protein": max(0.0, protein or 0.0),
        "carbs": max(0.0, carbs or 0.0),
        "fat": max(0.0, fat or 0.0),
        "sodium": max(0.0, sodium or 0.0),
    }


def _to_string_list(value: Any) -> list[str]:
    if isinstance(value, list):
        result: list[str] = []
        for item in value:
            text = str(item).strip()
            if text and text not in result:
                result.append(text)
        return result
    if isinstance(value, str):
        text = value.strip()
        if not text:
            return []
        if text.startswith("[") and text.endswith("]"):
            try:
                return _to_string_list(json.loads(text))
            except Exception:
                pass
        normalized = (
            text.replace("，", ",")
            .replace("、", ",")
            .replace("；", ",")
            .replace(";", ",")
        )
        result: list[str] = []
        for part in normalized.split(","):
            item = part.strip()
            if item and item not in result:
                result.append(item)
        return result
    return []


def _catalog_food_items(row: dict, food_name: str) -> list[str]:
    items = _to_string_list(row.get("food_items"))
    if not items:
        items = _to_string_list(row.get("ingredients"))
    if items:
        return items[:5]
    if food_name:
        return [food_name]
    return []


def _catalog_judgement_tags(
    row: dict,
    macros: dict[str, float],
    calorie_range: str,
    lang: str,
) -> list[str]:
    raw_tags = _to_string_list(row.get("judgement_tags"))
    if not raw_tags:
        raw_tags = _to_string_list(row.get("summary_tags"))
    if raw_tags:
        return raw_tags[:3]

    protein = max(0.0, _safe_float(macros.get("protein")) or 0.0)
    carbs = max(0.0, _safe_float(macros.get("carbs")) or 0.0)
    fat = max(0.0, _safe_float(macros.get("fat")) or 0.0)

    calorie_mid = 0.0
    parsed = _parse_calorie_range(calorie_range)
    if parsed is not None:
        calorie_mid = max(0.0, (parsed[0] + parsed[1]) / 2)
    if calorie_mid <= 0:
        calorie_mid = (protein * 4) + (carbs * 4) + (fat * 9)

    fat_pct = 0.0
    carb_pct = 0.0
    protein_pct = 0.0
    if calorie_mid > 0:
        fat_pct = (fat * 9 / calorie_mid) * 100
        carb_pct = (carbs * 4 / calorie_mid) * 100
        protein_pct = (protein * 4 / calorie_mid) * 100

    if lang == "zh-TW":
        tag_fat = "偏油"
        tag_carb = "碳水偏多"
        tag_protein_low = "蛋白不足"
        tag_light = "清淡"
    else:
        tag_fat = "Heavier oil"
        tag_carb = "Higher carbs"
        tag_protein_low = "Low protein"
        tag_light = "Light"

    tags: list[str] = []
    if fat_pct >= 35:
        tags.append(tag_fat)
    if carb_pct >= 55:
        tags.append(tag_carb)
    if protein_pct > 0 and protein_pct < 16:
        tags.append(tag_protein_low)
    elif protein_pct == 0 and protein < 12:
        tags.append(tag_protein_low)

    if not tags:
        tags.append(tag_light)
    return tags[:3]


def _catalog_reference_used(lang: str) -> str:
    if lang == "zh-TW":
        return "資料庫"
    return "catalog"


def _parse_json_response_utf8(resp: httpx.Response) -> Any:
    # Supabase JSON may be returned without explicit charset. Force UTF-8 first
    # to avoid mojibake on Traditional Chinese text.
    raw = resp.content
    if isinstance(raw, (bytes, bytearray)):
        try:
            return json.loads(raw.decode("utf-8"))
        except Exception:
            pass
    try:
        return resp.json()
    except Exception:
        return None


def _contains_cjk(text: str) -> bool:
    for ch in text:
        code = ord(ch)
        if 0x3400 <= code <= 0x9FFF:
            return True
    return False


def _fix_mojibake_value(value: Any) -> Any:
    if isinstance(value, str):
        text = value
        if not text or _contains_cjk(text):
            return text
        # Common UTF-8-as-latin1 mojibake signatures.
        has_latin1 = any(0x00C0 <= ord(ch) <= 0x00FF for ch in text)
        if not has_latin1:
            return text
        try:
            repaired = text.encode("latin1").decode("utf-8")
        except Exception:
            return text
        if repaired and _contains_cjk(repaired):
            return repaired
        return text
    if isinstance(value, list):
        return [_fix_mojibake_value(item) for item in value]
    if isinstance(value, dict):
        return {str(k): _fix_mojibake_value(v) for k, v in value.items()}
    return value


def _supabase_rest_list(table: str, params: list[tuple[str, str]]) -> list[dict]:
    try:
        headers = _supabase_headers()
    except HTTPException:
        return []
    url = f"{SUPABASE_URL}/rest/v1/{table}"
    try:
        client = _get_supabase_http_client()
        resp = client.get(url, headers=headers, params=params)
    except Exception as exc:
        logging.warning("Supabase %s query error: %s", table, exc)
        return []
    if resp.status_code >= 400:
        logging.warning("Supabase %s query failed (%s): %s", table, resp.status_code, resp.text)
        return []
    data = _parse_json_response_utf8(resp)
    if data is None:
        return []
    if not isinstance(data, list):
        return []
    normalized: list[dict] = []
    for row in data:
        if isinstance(row, dict):
            normalized.append({str(k): _fix_mojibake_value(v) for k, v in row.items()})
    return normalized


def _supabase_rest_insert(table: str, payload: dict) -> bool:
    try:
        headers = _supabase_headers()
    except HTTPException:
        return False
    headers["Prefer"] = "return=minimal"
    url = f"{SUPABASE_URL}/rest/v1/{table}"
    body = {str(k): v for k, v in payload.items()}
    try:
        client = _get_supabase_http_client()
        resp = client.post(url, headers=headers, json=body)
    except Exception as exc:
        logging.warning("Supabase %s insert error: %s", table, exc)
        return False
    if resp.status_code >= 400:
        logging.warning("Supabase %s insert failed (%s): %s", table, resp.status_code, resp.text)
        return False
    return True


def _supports_catalog_lang_active_filters() -> bool:
    global _catalog_lang_active_filter_supported
    if _catalog_lang_active_filter_supported is not None:
        return _catalog_lang_active_filter_supported
    try:
        headers = _supabase_headers()
    except HTTPException:
        _catalog_lang_active_filter_supported = False
        return False
    url = f"{SUPABASE_URL}/rest/v1/food_catalog"
    try:
        client = _get_supabase_http_client()
        resp = client.get(
            url,
            headers=headers,
            params=[("select", "id,lang,is_active"), ("limit", "1")],
        )
        _catalog_lang_active_filter_supported = resp.status_code < 400
    except Exception:
        _catalog_lang_active_filter_supported = False
    return bool(_catalog_lang_active_filter_supported)


def _food_match_score(query_norm: str, alias_row: dict, catalog_row: dict, lang: str) -> float:
    alias = str(alias_row.get("alias") or "").strip()
    alias_norm = _normalize_food_query(alias)
    food_name = str(catalog_row.get("food_name") or catalog_row.get("canonical_name") or "").strip()
    food_norm = _normalize_food_query(food_name)
    alias_lang = str(alias_row.get("lang") or "").strip()

    score = 0.0
    if alias_lang and alias_lang == lang:
        score += 0.8
    if alias_norm == query_norm:
        score += 4.0
    elif alias_norm.startswith(query_norm):
        score += 3.0
    elif query_norm in alias_norm:
        score += 2.0
    if food_norm == query_norm:
        score += 1.5
    elif food_norm.startswith(query_norm):
        score += 1.0
    elif query_norm in food_norm:
        score += 0.7
    verified = _safe_float(catalog_row.get("verified_level"))
    if verified is not None and verified > 0:
        score += min(verified, 5.0) / 10.0
    return score


def _direct_food_match_score(query_norm: str, catalog_row: dict) -> float:
    food_name = str(catalog_row.get("food_name") or "").strip()
    canonical_name = str(catalog_row.get("canonical_name") or "").strip()
    food_norm = _normalize_food_query(food_name)
    canonical_norm = _normalize_food_query(canonical_name)

    score = 0.0
    if food_norm == query_norm:
        score += 4.0
    elif food_norm.startswith(query_norm):
        score += 3.2
    elif query_norm in food_norm:
        score += 2.0

    if canonical_norm == query_norm:
        score += 3.2
    elif canonical_norm.startswith(query_norm):
        score += 2.4
    elif query_norm in canonical_norm:
        score += 1.6

    verified = _safe_float(catalog_row.get("verified_level"))
    if verified is not None and verified > 0:
        score += min(verified, 5.0) / 10.0
    return score


def _build_food_search_item(
    query_norm: str,
    catalog_row: dict,
    use_lang: str,
    alias_row: Optional[dict] = None,
    score: Optional[float] = None,
    raw_query: Optional[str] = None,
) -> Optional[FoodSearchItem]:
    food_id = str(catalog_row.get("id") or "").strip()
    if not food_id:
        return None
    food_name = str(catalog_row.get("food_name") or catalog_row.get("canonical_name") or "").strip()
    if not food_name:
        return None

    calorie_range = _catalog_calorie_range(catalog_row)
    macros = _catalog_macros(catalog_row)
    food_items = _catalog_food_items(catalog_row, food_name)
    suggestion = str(catalog_row.get("suggestion") or "").strip() or _catalog_default_suggestion(use_lang)
    dish_summary = (
        str(catalog_row.get("dish_summary") or "").strip()
        or _catalog_default_summary(food_name, use_lang)
    )
    nutrition_source = "catalog"
    reference_used = str(catalog_row.get("reference_used") or "").strip() or _catalog_reference_used(use_lang)

    if raw_query:
        beverage_result = _apply_beverage_formula(
            raw_query=raw_query,
            catalog_row=catalog_row,
            macros=macros,
            use_lang=use_lang,
        )
        if beverage_result is not None:
            food_name = str(beverage_result.get("food_name") or food_name).strip() or food_name
            calorie_range = str(beverage_result.get("calorie_range") or calorie_range).strip() or calorie_range
            adjusted_macros = beverage_result.get("macros")
            if isinstance(adjusted_macros, dict):
                macros = {
                    "protein": max(0.0, _safe_float(adjusted_macros.get("protein")) or 0.0),
                    "carbs": max(0.0, _safe_float(adjusted_macros.get("carbs")) or 0.0),
                    "fat": max(0.0, _safe_float(adjusted_macros.get("fat")) or 0.0),
                    "sodium": max(0.0, _safe_float(adjusted_macros.get("sodium")) or 0.0),
                }
            adjusted_items = beverage_result.get("food_items")
            if isinstance(adjusted_items, list):
                food_items = _to_string_list(adjusted_items)
            suggestion = (
                str(beverage_result.get("suggestion") or "").strip()
                or suggestion
            )
            dish_summary = (
                str(beverage_result.get("dish_summary") or "").strip()
                or dish_summary
            )
            nutrition_source = "catalog_formula"
            if use_lang == "zh-TW":
                reference_used = "資料庫 + 飲料參數公式"
            else:
                reference_used = "catalog + beverage formula"

    judgement_tags = _catalog_judgement_tags(catalog_row, macros, calorie_range, use_lang)

    if score is None:
        if alias_row is None:
            score = _direct_food_match_score(query_norm, catalog_row)
        else:
            score = _food_match_score(query_norm, alias_row, catalog_row, use_lang)

    alias = None
    alias_lang = None
    if alias_row is not None:
        alias = str(alias_row.get("alias") or "").strip() or None
        alias_lang = str(alias_row.get("lang") or "").strip() or None

    return FoodSearchItem(
        food_id=food_id,
        food_name=food_name,
        alias=alias or food_name,
        lang=alias_lang or use_lang,
        calorie_range=calorie_range,
        macros=macros,
        food_items=food_items,
        judgement_tags=judgement_tags,
        dish_summary=dish_summary,
        suggestion=suggestion,
        source=str(catalog_row.get("source") or "catalog").strip() or "catalog",
        nutrition_source=nutrition_source,
        reference_used=reference_used,
        image_url=str(catalog_row.get("image_url") or "").strip() or None,
        thumb_url=str(catalog_row.get("thumb_url") or "").strip() or None,
        image_source=str(catalog_row.get("image_source") or "").strip() or None,
        image_license=str(catalog_row.get("image_license") or "").strip() or None,
        is_beverage=catalog_row.get("is_beverage")
        if isinstance(catalog_row.get("is_beverage"), bool)
        else None,
        is_food=catalog_row.get("is_food")
        if isinstance(catalog_row.get("is_food"), bool)
        else True,
        match_score=score,
    )


def _require_admin(request: Request) -> None:
    if ADMIN_API_KEY:
        provided = request.headers.get("x-admin-key") or request.headers.get("X-Admin-Key")
        if not provided or provided.strip() != ADMIN_API_KEY:
            raise HTTPException(status_code=401, detail="admin_required")
        return
    client_host = request.client.host if request.client else ""
    if client_host not in {"127.0.0.1", "::1", "localhost"}:
        raise HTTPException(status_code=401, detail="admin_required")


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
    try:
        with httpx.Client(timeout=10) as client:
            resp = client.get(url, headers=headers)
    except Exception as exc:
        logging.warning("Supabase profiles fetch error (fallback to local): %s", exc)
        return None
    if resp.status_code >= 400:
        logging.warning("Supabase profiles fetch failed (%s), fallback to local", resp.status_code)
        return None
    data = _parse_json_response_utf8(resp)
    if data is None:
        logging.warning("Supabase profiles parse failed, fallback to local")
        return None
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
    try:
        with httpx.Client(timeout=10) as client:
            resp = client.post(url, headers=headers, json=payload)
        if resp.status_code >= 400:
            logging.warning("Supabase profiles upsert failed (%s): %s", resp.status_code, resp.text)
    except Exception as exc:
        logging.warning("Supabase profiles upsert error (ignored): %s", exc)


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
        return {"user_id": user_id, "email": email, "whitelisted": True, "trial_start": None}
    trial_start = _ensure_trial_start(user_id, email)
    return {"user_id": user_id, "email": email, "whitelisted": False, "trial_start": trial_start}


def _build_access_status(auth: dict) -> dict:
    now = datetime.now(timezone.utc)
    if auth.get("whitelisted"):
        return {
            "plan": "whitelisted",
            "trial_active": True,
            "trial_start": None,
            "trial_end": None,
            "whitelisted": True,
            "entitlements": list(_AI_ENTITLEMENTS),
        }
    trial_start = auth.get("trial_start")
    if trial_start is None:
        trial_start = now
    trial_end = trial_start + timedelta(days=TRIAL_DAYS)
    trial_active = now <= trial_end
    return {
        "plan": "trial" if trial_active else "free",
        "trial_active": trial_active,
        "trial_start": trial_start.isoformat(),
        "trial_end": trial_end.isoformat(),
        "whitelisted": False,
        "entitlements": list(_AI_ENTITLEMENTS) if trial_active else [],
    }


def _require_entitlement(auth: dict, entitlement: str) -> dict:
    access = _build_access_status(auth)
    entitlements = set(access.get("entitlements") or [])
    if entitlement not in entitlements:
        raise HTTPException(status_code=402, detail="subscription_required")
    return access


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


def _should_use_ai(user_id: str | None) -> bool:
    if not CALL_REAL_AI:
        return False
    if FREE_DAILY_LIMIT <= 0:
        return True
    counts = _load_daily_counts()
    today = datetime.now(timezone.utc).date().isoformat()
    today_counts = counts.get(today, {})
    if isinstance(today_counts, dict):
        current = int(today_counts.get(user_id or "_global", 0))
    else:
        current = int(today_counts or 0)
    return current < FREE_DAILY_LIMIT


def _ensure_ai_available(user_id: str | None) -> None:
    if not CALL_REAL_AI:
        raise HTTPException(status_code=503, detail="ai_disabled")
    if _client is None:
        raise HTTPException(status_code=503, detail="ai_not_configured")
    if not _should_use_ai(user_id):
        raise HTTPException(status_code=429, detail="ai_quota_exceeded")


def _increment_daily_count(user_id: str | None) -> None:
    counts = _load_daily_counts()
    today = datetime.now(timezone.utc).date().isoformat()
    today_counts = counts.get(today)
    if not isinstance(today_counts, dict):
        today_counts = {}
    key = user_id or "_global"
    today_counts[key] = int(today_counts.get(key, 0)) + 1
    counts[today] = today_counts
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


def _analysis_rate_allowed(user_id: str) -> bool:
    if _analysis_rate_limit <= 0:
        return True
    now = time.time()
    window = _analysis_rate_window_sec
    entries = _analysis_rate_state.get(user_id, [])
    entries = [t for t in entries if now - t <= window]
    if len(entries) >= _analysis_rate_limit:
        _analysis_rate_state[user_id] = entries
        return False
    entries.append(now)
    _analysis_rate_state[user_id] = entries
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
    _require_entitlement(_auth, "ai_analyze")
    user_id = _auth.get("user_id", "")
    if user_id and not _analysis_rate_allowed(user_id):
        raise HTTPException(status_code=429, detail="analyze_rate_limited")
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

    _ensure_ai_available(_auth.get("user_id"))
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
        _increment_daily_count(_auth.get("user_id"))
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
    _require_entitlement(_auth, "ai_analyze")
    user_id = _auth.get("user_id", "")
    if user_id and not _analysis_rate_allowed(user_id):
        raise HTTPException(status_code=429, detail="analyze_rate_limited")
    raw_name = (payload.food_name or "").strip()
    if not raw_name:
        raise HTTPException(status_code=400, detail="missing_food_name")

    use_lang = payload.lang or DEFAULT_LANG
    if use_lang not in _supported_langs:
        use_lang = "zh-TW"

    _ensure_ai_available(_auth.get("user_id"))
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
        _increment_daily_count(_auth.get("user_id"))
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


@app.get("/foods/search", response_model=FoodSearchResponse)
def foods_search(
    q: str = Query(..., min_length=1, max_length=80),
    lang: str = Query(default=None),
    limit: int = Query(default=8, ge=1, le=20),
):
    query_candidates = _food_search_query_candidates(q)
    if not query_candidates:
        return FoodSearchResponse(items=[])

    use_lang = lang or DEFAULT_LANG
    if use_lang not in _supported_langs:
        use_lang = "zh-TW"
    supports_lang_active = _supports_catalog_lang_active_filters()

    # Use "*" so optional columns (e.g. food_items/judgement_tags) do not break older schemas.
    catalog_select = "*"
    query_limit = min(60, max(20, limit * 3))

    alias_candidates: list[tuple[str, dict]] = []
    direct_by_id: dict[str, dict] = {}
    direct_best_score: dict[str, float] = {}
    direct_best_query: dict[str, str] = {}
    for query_norm in query_candidates:
        alias_rows = _supabase_rest_list(
            "food_aliases",
            [
                ("select", "food_id,alias,lang"),
                ("alias", f"ilike.*{query_norm}*"),
                *((("lang", f"eq.{use_lang}"),) if supports_lang_active else ()),
                ("limit", str(query_limit)),
            ],
        )
        for row in alias_rows:
            alias_candidates.append((query_norm, row))

        direct_rows = _supabase_rest_list(
            "food_catalog",
            [
                ("select", catalog_select),
                ("or", f"food_name.ilike.*{query_norm}*,canonical_name.ilike.*{query_norm}*"),
                *((("lang", f"eq.{use_lang}"), ("is_active", "eq.true")) if supports_lang_active else ()),
                ("limit", str(query_limit)),
            ],
        )
        for row in direct_rows:
            food_id = str(row.get("id") or "").strip()
            if not food_id:
                continue
            score = _direct_food_match_score(query_norm, row)
            previous = direct_best_score.get(food_id, -1.0)
            if score > previous:
                direct_best_score[food_id] = score
                direct_best_query[food_id] = query_norm
                direct_by_id[food_id] = row

    alias_food_ids: list[str] = []
    for _, row in alias_candidates:
        food_id = str(row.get("food_id") or "").strip()
        if food_id and food_id not in alias_food_ids:
            alias_food_ids.append(food_id)

    alias_needed_ids = [food_id for food_id in alias_food_ids if food_id not in direct_by_id]
    if alias_needed_ids:
        fetched_alias_rows = _supabase_rest_list(
            "food_catalog",
            [
                ("select", catalog_select),
                ("id", f"in.({','.join(alias_needed_ids)})"),
                *((("lang", f"eq.{use_lang}"), ("is_active", "eq.true")) if supports_lang_active else ()),
                ("limit", str(len(alias_needed_ids))),
            ],
        )
        for row in fetched_alias_rows:
            food_id = str(row.get("id") or "").strip()
            if food_id and food_id not in direct_by_id:
                direct_by_id[food_id] = row

    if not alias_candidates and not direct_by_id:
        return FoodSearchResponse(items=[])

    best_items: dict[str, FoodSearchItem] = {}

    # Candidate set A: direct match from food_name/canonical_name.
    for food_id, catalog_row in direct_by_id.items():
        candidate_query = direct_best_query.get(food_id) or query_candidates[0]
        candidate = _build_food_search_item(
            query_norm=candidate_query,
            catalog_row=catalog_row,
            use_lang=use_lang,
            alias_row=None,
            score=direct_best_score.get(food_id),
            raw_query=q,
        )
        if candidate is None:
            continue
        best_items[food_id] = candidate

    # Candidate set B: alias match (can outrank direct match).
    for query_norm, alias_row in alias_candidates:
        food_id = str(alias_row.get("food_id") or "").strip()
        if not food_id:
            continue
        catalog_row = direct_by_id.get(food_id)
        if catalog_row is None:
            continue
        candidate = _build_food_search_item(
            query_norm=query_norm,
            catalog_row=catalog_row,
            use_lang=use_lang,
            alias_row=alias_row,
            raw_query=q,
        )
        if candidate is None:
            continue
        existing = best_items.get(food_id)
        if existing is None or (candidate.match_score or 0.0) > (existing.match_score or 0.0):
            best_items[food_id] = candidate

    items = list(best_items.values())
    items.sort(key=lambda item: item.match_score or 0.0, reverse=True)
    return FoodSearchResponse(items=items[:limit])


@app.post("/foods/search_miss")
def foods_search_miss(payload: FoodSearchMissRequest, request: Request):
    raw_query = (payload.query or "").strip()
    if not raw_query:
        raise HTTPException(status_code=400, detail="missing_query")
    query_norm = _normalize_food_query(raw_query)
    if not query_norm:
        raise HTTPException(status_code=400, detail="missing_query")
    use_lang = (payload.lang or DEFAULT_LANG).strip()
    if use_lang not in _supported_langs:
        use_lang = "zh-TW"
    source = (payload.source or "name_input").strip().lower()
    if not source:
        source = "name_input"
    if len(source) > 40:
        source = source[:40]

    user_id: Optional[str] = None
    auth_header = request.headers.get("authorization") or request.headers.get("Authorization")
    if auth_header and auth_header.lower().startswith("bearer "):
        token = auth_header.split(" ", 1)[1].strip()
        if token:
            try:
                token_payload = _decode_bearer_token(token)
                candidate = str(token_payload.get("sub") or "").strip()
                if candidate:
                    user_id = candidate
            except Exception:
                user_id = None

    meta = {
        "user_agent": str(request.headers.get("user-agent") or "")[:160],
        "referer": str(request.headers.get("referer") or "")[:240],
    }
    inserted = _supabase_rest_insert(
        "food_search_miss",
        {
            "query": raw_query[:80],
            "query_norm": query_norm[:80],
            "lang": use_lang,
            "source": source,
            "user_id": user_id,
            "meta": meta,
        },
    )
    return {"ok": inserted}


@app.get("/foods/miss_top", response_model=FoodSearchMissTopResponse)
def foods_miss_top(
    days: int = Query(default=30, ge=1, le=365),
    limit: int = Query(default=50, ge=1, le=500),
    lang: Optional[str] = Query(default=None),
    _admin: None = Depends(_require_admin),
):
    use_lang = (lang or "").strip()
    cutoff = (datetime.now(timezone.utc) - timedelta(days=days)).isoformat()
    rows = _supabase_rest_list(
        "food_search_miss",
        [
            ("select", "query_norm,query,lang,created_at"),
            ("created_at", f"gte.{cutoff}"),
            ("order", "created_at.desc"),
            ("limit", "5000"),
        ],
    )

    aggregate: dict[tuple[str, str], dict[str, Any]] = {}
    for row in rows:
        query_norm = str(row.get("query_norm") or "").strip()
        sample_query = str(row.get("query") or "").strip()
        row_lang = str(row.get("lang") or "").strip() or DEFAULT_LANG
        created_at = str(row.get("created_at") or "").strip()
        if not query_norm:
            continue
        if use_lang and row_lang != use_lang:
            continue
        key = (query_norm, row_lang)
        existing = aggregate.get(key)
        if existing is None:
            aggregate[key] = {
                "query_norm": query_norm,
                "sample_query": sample_query or query_norm,
                "lang": row_lang,
                "miss_count": 1,
                "last_seen_at": created_at or None,
            }
            continue
        existing["miss_count"] = int(existing.get("miss_count") or 0) + 1
        if created_at and str(existing.get("last_seen_at") or "") < created_at:
            existing["last_seen_at"] = created_at
            if sample_query:
                existing["sample_query"] = sample_query

    items = [
        FoodSearchMissTopItem(
            query_norm=str(item.get("query_norm") or ""),
            sample_query=str(item.get("sample_query") or ""),
            lang=str(item.get("lang") or DEFAULT_LANG),
            miss_count=int(item.get("miss_count") or 0),
            last_seen_at=str(item.get("last_seen_at") or "") or None,
        )
        for item in aggregate.values()
        if str(item.get("query_norm") or "")
    ]
    items.sort(
        key=lambda item: (
            -(item.miss_count or 0),
            item.last_seen_at or "",
            item.query_norm,
        )
    )
    return FoodSearchMissTopResponse(days=days, items=items[:limit])


@app.post("/analyze_label", response_model=LabelResult)
async def analyze_label(
    _auth: dict = Depends(_require_auth),
    image: UploadFile = File(...),
    lang: str = Query(default=None, description="Language code, e.g. zh-TW, en"),
):
    _require_entitlement(_auth, "ai_analyze")
    user_id = _auth.get("user_id", "")
    if user_id and not _analysis_rate_allowed(user_id):
        raise HTTPException(status_code=429, detail="analyze_rate_limited")
    image_bytes = await image.read()

    use_lang = lang or DEFAULT_LANG
    if use_lang not in _supported_langs:
        use_lang = "zh-TW"

    _ensure_ai_available(_auth.get("user_id"))
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
        _increment_daily_count(_auth.get("user_id"))
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
    _require_entitlement(_auth, "ai_summary")
    use_lang = payload.lang or DEFAULT_LANG
    if use_lang not in _supported_langs:
        use_lang = "zh-TW"
    _ensure_ai_available(_auth.get("user_id"))
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
    _require_entitlement(_auth, "ai_summary")
    use_lang = payload.lang or DEFAULT_LANG
    if use_lang not in _supported_langs:
        use_lang = "zh-TW"
    _ensure_ai_available(_auth.get("user_id"))
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
    _require_entitlement(_auth, "ai_suggest")
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
        _increment_daily_count(_auth.get("user_id"))
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
    _require_entitlement(_auth, "ai_chat")
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
        _ensure_ai_available(_auth.get("user_id"))
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
        _increment_daily_count(_auth.get("user_id"))
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
    return _build_access_status(_auth)



@app.get("/")
def root():
    raise HTTPException(status_code=404, detail="not_found")

@app.get("/health")
def health(_admin: None = Depends(_require_admin)):
    file_env = dotenv_values(_env_path)
    return {
        "call_real_ai": CALL_REAL_AI,
        "api_key_set": bool(API_KEY),
        "model": OPENAI_MODEL,
        "env_path": str(_env_path),
        "file_call_real_ai": file_env.get("CALL_REAL_AI"),
        "env_call_real_ai": os.getenv("CALL_REAL_AI"),
        "last_ai_error": _last_ai_error if RETURN_AI_ERROR else None,
        "supabase_catalog_probe": _probe_supabase_catalog(),
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


def _supabase_key_kind(key: str) -> str:
    raw = (key or "").strip()
    if not raw:
        return "missing"
    if raw.startswith("sb_publishable_"):
        return "publishable"
    if raw.startswith("sb_secret_"):
        return "secret"
    if raw.startswith("eyJ"):
        return "jwt"
    return "unknown"


def _probe_supabase_catalog() -> dict:
    key_kind = _supabase_key_kind(SUPABASE_SERVICE_ROLE_KEY)
    if not SUPABASE_URL:
        return {"ok": False, "reason": "missing_supabase_url", "key_kind": key_kind}
    if not SUPABASE_SERVICE_ROLE_KEY:
        return {"ok": False, "reason": "missing_service_role_key", "key_kind": key_kind}
    try:
        headers = _supabase_headers()
    except HTTPException as exc:
        return {"ok": False, "reason": str(exc.detail), "key_kind": key_kind}

    probe_url = f"{SUPABASE_URL}/rest/v1/food_catalog"
    try:
        with httpx.Client(timeout=10) as client:
            probe_resp = client.get(
                probe_url,
                headers=headers,
                params=[("select", "id,food_name"), ("limit", "5")],
            )
    except Exception as exc:
        return {"ok": False, "reason": "request_error", "error": str(exc), "key_kind": key_kind}

    if probe_resp.status_code >= 400:
        return {
            "ok": False,
            "reason": "http_error",
            "status_code": probe_resp.status_code,
            "body": probe_resp.text[:180],
            "key_kind": key_kind,
        }

    rows = _parse_json_response_utf8(probe_resp)
    if rows is None:
        return {"ok": False, "reason": "invalid_json", "key_kind": key_kind}

    if not isinstance(rows, list):
        return {"ok": False, "reason": "unexpected_payload", "key_kind": key_kind}

    sample = []
    for row in rows[:3]:
        if isinstance(row, dict):
            sample.append(
                {
                    "id": str(row.get("id") or ""),
                    "food_name": str(
                        _fix_mojibake_value(
                            row.get("food_name") or row.get("canonical_name") or ""
                        )
                    ),
                }
            )
    keyword_rows = _supabase_rest_list(
        "food_catalog",
        [("select", "id,food_name"), ("food_name", "ilike.*牛*"), ("limit", "3")],
    )
    return {
        "ok": True,
        "key_kind": key_kind,
        "row_count": len(rows),
        "sample": sample,
        "keyword_niu_count": len(keyword_rows),
    }


@app.get("/usage")
def usage(limit: int = 50, _admin: None = Depends(_require_admin)):
    return {"records": _read_usage_records(limit)}


@app.get("/usage/summary")
def usage_summary(_admin: None = Depends(_require_admin)):
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

