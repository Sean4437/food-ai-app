from fastapi import FastAPI, UploadFile, File, Query, Form
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
    macros: Dict[str, float]
    dish_summary: Optional[str] = None
    suggestion: str
    tier: str
    source: str
    cost_estimate_usd: Optional[float] = None
    confidence: Optional[float] = None
    is_beverage: Optional[bool] = None
    debug_reason: Optional[str] = None


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
    lang: Optional[str] = None
    profile: Optional[dict] = None


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


class WeekSummaryRequest(BaseModel):
    week_start: str
    week_end: str
    days: List[WeekSummaryInput]
    lang: Optional[str] = None
    profile: Optional[dict] = None


class WeekSummaryResponse(BaseModel):
    week_summary: str
    next_week_advice: str
    source: str
    confidence: Optional[float] = None


class MealAdviceRequest(BaseModel):
    meal_type: str
    calorie_range: str
    dish_summaries: List[str]
    lang: Optional[str] = None
    profile: Optional[dict] = None


class MealAdviceResponse(BaseModel):
    self_cook: str
    convenience: str
    bento: str
    other: str
    source: str
    confidence: Optional[float] = None

FREE_DAILY_LIMIT = int(os.getenv("FREE_DAILY_LIMIT", "1"))
CALL_REAL_AI = os.getenv("CALL_REAL_AI", "false").lower() == "true"
DEFAULT_LANG = os.getenv("DEFAULT_LANG", "zh-TW")
API_KEY = os.getenv("API_KEY", "")
OPENAI_MODEL = os.getenv("OPENAI_MODEL", "gpt-4o-mini")
PRICE_INPUT_PER_M = float(os.getenv("PRICE_INPUT_PER_M", "0.15"))
PRICE_OUTPUT_PER_M = float(os.getenv("PRICE_OUTPUT_PER_M", "0.60"))
RETURN_AI_ERROR = os.getenv("RETURN_AI_ERROR", "false").lower() == "true"

_client = OpenAI(api_key=API_KEY) if API_KEY else None
logging.basicConfig(level=logging.INFO)
_last_ai_error: Optional[str] = None

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

_fake_macro_choices = [25, 40, 55, 70, 85]


def _macro_level_to_percent(value: str) -> int:
    lower = value.lower()
    if value in ("低", "偏低") or "low" in lower:
        return 30
    if value in ("高", "偏高") or "high" in lower:
        return 80
    return 55


def _normalize_macro_value(value) -> float:
    if isinstance(value, (int, float)):
        return float(max(0, min(100, value)))
    if isinstance(value, str):
        stripped = value.strip()
        try:
            num = float(stripped.replace("%", ""))
            return float(max(0, min(100, num)))
        except Exception:
            return float(_macro_level_to_percent(stripped))
    return 55.0


def _normalize_macros(data: dict, lang: str) -> dict:
    macros = data.get("macros") if isinstance(data, dict) else None
    if not isinstance(macros, dict):
        macros = {}
    macros = {
        "protein": _normalize_macro_value(macros.get("protein", 55)),
        "carbs": _normalize_macro_value(macros.get("carbs", 55)),
        "fat": _normalize_macro_value(macros.get("fat", 55)),
        "sodium": _normalize_macro_value(macros.get("sodium", 55)),
    }
    is_beverage = False
    if isinstance(data, dict):
        raw_flag = data.get("is_beverage")
        if isinstance(raw_flag, bool):
            is_beverage = raw_flag
        elif isinstance(raw_flag, str):
            is_beverage = raw_flag.strip().lower() == "true"
    if is_beverage:
        macros["protein"] = min(macros["protein"], 15.0)
        macros["fat"] = min(macros["fat"], 15.0)
    return macros


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
    label_context: str | None,
) -> str:
    profile_text = ""
    if profile:
        profile_text = (
            f"User profile (do not mention exact values): {json.dumps(profile, ensure_ascii=True)}\n"
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
    label_text = ""
    if label_context:
        label_text = (
            f"Nutrition label info (must override calorie_range and macros if provided): {label_context}\n"
        )
    meal_text = ""
    if meal_type:
        if lang == "zh-TW":
            meal_text = f"餐次：{meal_type}\n"
            if meal_type in ("dinner", "late_snack"):
                meal_text += "若為晚餐或消夜，建議提醒避免夜間加餐。\n"
        else:
            meal_text = f"Meal type: {meal_type}\n"
            if meal_type in ("dinner", "late_snack"):
                meal_text += "If this is dinner or a late-night snack, suggest avoiding additional late-night eating.\n"
    if meal_photo_count and meal_photo_count > 1:
        if lang == "zh-TW":
            meal_text += f"此餐共有 {meal_photo_count} 張照片，請以整餐為單位輸出結果。\n"
        else:
            meal_text += f"This meal has {meal_photo_count} photos; summarize at the whole-meal level.\n"
    if lang == "zh-TW":
        suggestion_rule = (
            "- suggestion: 溫和、非醫療的下一餐建議，請給出具體食物類型，並包含份量描述（例：主食半碗、蛋白質一掌、蔬菜一碗）\n"
        )
        suggestion_example = (
            "  \"suggestion\": \"下一餐以清淡蛋白質與蔬菜為主，主食半碗即可。\",\n"
        )
        if advice_mode == "current_meal":
            suggestion_rule = (
                "- suggestion: 針對這一餐怎麼吃比較好，輸出三行格式：可以吃 / 不建議吃 / 份量上限\n"
                "- 需要參考 recent context 並用一句話提到上一餐\n"
            )
            suggestion_example = (
                "  \"suggestion\": \"可以吃：蔬菜多一點、保留瘦肉\\n不建議吃：湯底與加工配料\\n份量上限：主食半碗、蛋白質一掌（上一餐偏油，所以這餐清淡一點）\",\n"
            )
        return (
            "你是營養分析助理。請根據照片判斷餐點內容，回傳 JSON。\n"
            "要求：\n"
            "- 僅回傳 JSON（不要多餘文字）\n"
            "- food_name: 中文餐點名稱\n"
            "- calorie_range: 例如 '450-600 kcal'\n"
            "- macros: protein/carbs/fat/sodium 為 0-100 的百分比整數\n"
            "- dish_summary: 20 字內一句話摘要\n"
            "- 規則：自然口語，不要專業營養名詞，不要出現數字/熱量/克數，不責備不命令\n"
            "- 描述整體負擔、口味或營養重點，留空間給下一餐建議\n"
            "- 結構參考：整體感受 + 一個主要特徵 + 輕微提醒\n"
            f"{suggestion_rule}"
            "- confidence: 0 到 1 的信心分數\n"
            "- is_beverage: 是否為飲料（true/false）\n"
            "- 飲料規則：若為飲料，protein/fat 建議 <= 15，熱量偏低；含糖可提升 carbs\n"
            "- 若使用者提供 food_name，必須優先採用\n"
            "- 若提供 nutrition label info，必須使用其 calorie_range 與 macros\n"
            "- 避免醫療或診斷字眼；避免精準數值或克數，維持區間與語意描述\n"
            "- 若畫面中有硬幣或信用卡，請將其視為參考物估計份量；無則使用一般估計\n"
            "JSON 範例：\n"
            "{\n"
            "  \"food_name\": \"牛肉便當\",\n"
            "  \"calorie_range\": \"650-850 kcal\",\n"
            "  \"macros\": {\"protein\": 45, \"carbs\": 55, \"fat\": 65, \"sodium\": 70},\n"
            "  \"dish_summary\": \"油脂偏多、蛋白足夠\",\n"
            f"{suggestion_example}"
            "  \"confidence\": 0.72,\n"
            "  \"is_beverage\": false\n"
            "}\n"
        ) + profile_text + note_text + context_text + label_text + meal_text
    suggestion_rule = (
        "- suggestion: gentle next-meal advice (non-medical), include concrete food types and portion guidance (e.g. half bowl carbs, palm-sized protein, one bowl veggies)\n"
    )
    suggestion_example = "  \"suggestion\": \"Next meal: lean protein + veggies, smaller carbs.\",\n"
    if advice_mode == "current_meal":
        suggestion_rule = (
            "- suggestion: guidance for how to eat this meal, formatted as three lines: Can eat / Avoid / Portion limit\n"
            "- Reference the recent context and briefly mention the previous meal in the suggestion\n"
        )
        suggestion_example = (
            "  \"suggestion\": \"Can eat: more veggies, keep lean protein\\nAvoid: broth and processed sides\\nPortion limit: half bowl carbs, palm-sized protein (previous meal was heavier, so keep it light)\",\n"
        )
    return (
        "You are a nutrition assistant. Analyze the meal image and return JSON.\n"
        "Requirements:\n"
        "- Return JSON only (no extra text)\n"
        "- food_name: English name\n"
        "- calorie_range: e.g. '450-600 kcal'\n"
        "- macros: protein/carbs/fat/sodium are integer percentages (0-100)\n"
        "- dish_summary: single-sentence summary (<= 20 words)\n"
        "- Rules: natural language, avoid technical nutrition terms, no numbers/calories/grams, no scolding or commands\n"
        "- Describe overall burden, taste, or a key nutrition cue, leaving room for next-meal advice\n"
        "- Structure hint: overall feel + one main trait + gentle reminder\n"
        f"{suggestion_rule}"
        "- confidence: 0 to 1 confidence score\n"
        "- is_beverage: true/false\n"
        "- Beverage rule: if beverage, protein/fat should be <= 15; calories should be low; sugary drinks may increase carbs\n"
        "- If user provides food_name, it must be used as the primary name\n"
        "- If nutrition label info is provided, you must use its calorie_range and macros\n"
        "- Avoid medical/diagnosis language; avoid precise numbers/grams\n"
        "- If a coin or credit card is visible, treat it as a size reference; otherwise estimate normally\n"
        "JSON example:\n"
        "{\n"
        "  \"food_name\": \"beef bento\",\n"
        "  \"calorie_range\": \"650-850 kcal\",\n"
        "  \"macros\": {\"protein\": 45, \"carbs\": 55, \"fat\": 65, \"sodium\": 70},\n"
        "  \"dish_summary\": \"Heavier oil, decent protein\",\n"
        f"{suggestion_example}"
        "  \"confidence\": 0.72,\n"
        "  \"is_beverage\": false\n"
        "}\n"
    ) + profile_text + note_text + context_text + label_text + meal_text


def _build_day_prompt(lang: str, profile: dict | None, meals: List[MealSummaryInput]) -> str:
    profile_text = ""
    if profile:
        profile_text = (
            f"User profile (do not mention exact values): {json.dumps(profile, ensure_ascii=True)}\n"
            "Use this only to adjust tone and suggestions. Never mention the profile values explicitly.\n"
        )
    meal_lines = []
    for meal in meals:
        summaries = "; ".join(meal.dish_summaries) if meal.dish_summaries else "no dish summary"
        meal_lines.append(f"- {meal.meal_type}: {meal.calorie_range} | {summaries}")
    meal_block = "\n".join(meal_lines)
    if lang == "zh-TW":
        return (
            "你是營養分析助理。請根據當日多餐摘要，輸出今日總結與明天建議，回傳 JSON。\n"
            "要求：\n"
            "- 僅回傳 JSON（不要多餘文字）\n"
            "- day_summary: 一句話總結（30 字內）\n"
            "- tomorrow_advice: 明天一餐的方向（一句話）\n"
            "- confidence: 0 到 1 的信心分數\n"
            "- 避免醫療或診斷字眼；避免精準數值或克數\n"
            "JSON 範例：\n"
            "{\n"
            "  \"day_summary\": \"整體均衡，油脂略多\",\n"
            "  \"tomorrow_advice\": \"明天以清淡蛋白質與蔬菜為主\",\n"
            "  \"confidence\": 0.7\n"
            "}\n"
            f"餐次摘要：\n{meal_block}\n"
        ) + profile_text
    return (
        "You are a nutrition assistant. Based on day meal summaries, return JSON.\n"
        "Requirements:\n"
        "- Return JSON only\n"
        "- day_summary: one-sentence summary (<= 30 words)\n"
        "- tomorrow_advice: one sentence guidance for tomorrow\n"
        "- confidence: 0 to 1\n"
        "- Avoid medical/diagnosis language; avoid precise numbers/grams\n"
        "JSON example:\n"
        "{\n"
        "  \"day_summary\": \"Overall balanced, slightly higher fat\",\n"
        "  \"tomorrow_advice\": \"Aim for lean protein and more vegetables\",\n"
        "  \"confidence\": 0.7\n"
        "}\n"
        f"Meal summaries:\n{meal_block}\n"
    ) + profile_text


def _build_week_prompt(lang: str, profile: dict | None, days: List[WeekSummaryInput], week_start: str, week_end: str) -> str:
    profile_text = ""
    if profile:
        profile_text = (
            f"User profile (do not mention exact values): {json.dumps(profile, ensure_ascii=True)}\n"
            "Use this only to adjust tone and suggestions. Never mention the profile values explicitly.\n"
        )
    day_lines = []
    for day in days:
        summary = day.day_summary or "no summary"
        day_lines.append(f"- {day.date}: {day.calorie_range} | {summary} | meals={day.meal_count}")
    day_block = "\n".join(day_lines)
    if lang == "zh-TW":
        return (
            "你是營養分析助理。請根據一週摘要，輸出週總結與下週建議，回傳 JSON。\n"
            "要求：\n"
            "- 僅回傳 JSON（不要多餘文字）\n"
            "- week_summary: 一句話總結（40 字內）\n"
            "- next_week_advice: 下週方向（一句話）\n"
            "- confidence: 0 到 1 的信心分數\n"
            "- 避免醫療或診斷字眼；避免精準數值或克數\n"
            "JSON 範例：\n"
            "{\n"
            "  \"week_summary\": \"整體均衡但油脂偏高，注意蔬菜比例\",\n"
            "  \"next_week_advice\": \"下週以清淡蛋白質與蔬菜為主\",\n"
            "  \"confidence\": 0.7\n"
            "}\n"
            f"週期：{week_start} ~ {week_end}\n"
            f"每日摘要：\n{day_block}\n"
        ) + profile_text
    return (
        "You are a nutrition assistant. Based on weekly summaries, return JSON.\n"
        "Requirements:\n"
        "- Return JSON only\n"
        "- week_summary: one-sentence summary (<= 40 words)\n"
        "- next_week_advice: one sentence guidance for next week\n"
        "- confidence: 0 to 1\n"
        "- Avoid medical/diagnosis language; avoid precise numbers/grams\n"
        "JSON example:\n"
        "{\n"
        "  \"week_summary\": \"Overall balanced, but fat intake is slightly high\",\n"
        "  \"next_week_advice\": \"Next week: more veggies and lean protein\",\n"
        "  \"confidence\": 0.7\n"
        "}\n"
        f"Week: {week_start} ~ {week_end}\n"
        f"Daily summaries:\n{day_block}\n"
    ) + profile_text


def _fallback_week_summary(lang: str, days: List[WeekSummaryInput]) -> dict:
    text = " ".join([day.day_summary for day in days if day.day_summary])
    oily = any(word in text for word in ["炸", "油", "酥", "奶油", "fried", "oily"])
    salty = any(word in text for word in ["鹹", "鈉", "鹽", "salty", "sodium"])
    if lang == "zh-TW":
        if oily and salty:
            return {"week_summary": "油脂與鹽分偏高，注意清淡", "next_week_advice": "下週以清湯、蔬菜與瘦蛋白為主", "confidence": 0.5}
        if oily:
            return {"week_summary": "油脂偏高，整體尚可", "next_week_advice": "下週以清淡蛋白質與蔬菜為主", "confidence": 0.5}
        if salty:
            return {"week_summary": "鹽分略多，注意水分與清淡", "next_week_advice": "下週以清湯蔬菜搭配瘦蛋白", "confidence": 0.5}
        return {"week_summary": "整體均衡，維持即可", "next_week_advice": "下週以蛋白質與蔬菜為主", "confidence": 0.5}
    if oily and salty:
        return {"week_summary": "Higher fat and sodium this week", "next_week_advice": "Next week: lean protein + veggies", "confidence": 0.5}
    if oily:
        return {"week_summary": "Fat intake a bit high", "next_week_advice": "Next week: lighter protein and veggies", "confidence": 0.5}
    if salty:
        return {"week_summary": "Sodium a bit high", "next_week_advice": "Next week: clear soup + veggies", "confidence": 0.5}
    return {"week_summary": "Overall balanced", "next_week_advice": "Next week: lean protein + veggies", "confidence": 0.5}

def _build_meal_advice_prompt(lang: str, profile: dict | None, meal: MealAdviceRequest) -> str:
    profile_text = ""
    if profile:
        profile_text = (
            f"User profile (do not mention exact values): {json.dumps(profile, ensure_ascii=True)}\n"
            "Use this only to adjust tone and suggestions. Never mention the profile values explicitly.\n"
        )
    summaries = "; ".join(meal.dish_summaries) if meal.dish_summaries else "no dish summary"
    if lang == "zh-TW":
        return (
            "你是營養分析助理。請根據本餐摘要，給出下一餐建議，回傳 JSON。\n"
            "要求：\n"
            "- 僅回傳 JSON（不要多餘文字）\n"
            "- self_cook / convenience / bento / other：各 1 句建議\n"
            "- 每句需包含具體食物方向 + 份量描述（例：主食半碗、蛋白質一掌、蔬菜一碗）\n"
            "- 避免醫療或診斷字眼；避免精準數值或克數\n"
            "- 需提到上一餐摘要的影響（例如偏油、偏鹹）\n"
            "JSON 範例：\n"
            "{\n"
            "  \"self_cook\": \"清炒蔬菜＋蒸魚，主食半碗即可\",\n"
            "  \"convenience\": \"沙拉＋無糖豆漿，主食半碗\",\n"
            "  \"bento\": \"少飯、加青菜、選清淡蛋白\",\n"
            "  \"other\": \"清湯＋蔬菜＋瘦肉，避免油炸\",\n"
            "  \"confidence\": 0.7\n"
            "}\n"
            f"本餐：{meal.meal_type} | {meal.calorie_range}\n"
            f"本餐摘要：{summaries}\n"
        ) + profile_text
    return (
        "You are a nutrition assistant. Based on the meal summary, return JSON advice for the next meal.\n"
        "Requirements:\n"
        "- Return JSON only\n"
        "- self_cook / convenience / bento / other: one sentence each\n"
        "- Each sentence must include food direction + portion guidance (e.g., half bowl carbs, palm-sized protein, one bowl veggies)\n"
        "- Avoid medical/diagnosis language; avoid precise numbers/grams\n"
        "- Mention the influence of the previous meal summary\n"
        "JSON example:\n"
        "{\n"
        "  \"self_cook\": \"Steamed fish + veggies, half bowl carbs\",\n"
        "  \"convenience\": \"Salad + unsweetened soy milk, half bowl carbs\",\n"
        "  \"bento\": \"Less rice, more veggies, lean protein\",\n"
        "  \"other\": \"Clear soup + veggies + lean protein\",\n"
        "  \"confidence\": 0.7\n"
        "}\n"
        f"Meal: {meal.meal_type} | {meal.calorie_range}\n"
        f"Meal summary: {summaries}\n"
    ) + profile_text


def _fallback_meal_advice(lang: str) -> dict:
    if lang == "zh-TW":
        return {
            "self_cook": "清炒蔬菜＋蒸魚，主食半碗即可",
            "convenience": "沙拉＋無糖豆漿，主食半碗",
            "bento": "少飯、加青菜、選清淡蛋白",
            "other": "清湯＋蔬菜＋瘦肉，避免油炸",
            "confidence": 0.5,
        }
    return {
        "self_cook": "Steamed fish + veggies, half bowl carbs",
        "convenience": "Salad + unsweetened soy milk, half bowl carbs",
        "bento": "Less rice, more veggies, lean protein",
        "other": "Clear soup + veggies + lean protein",
        "confidence": 0.5,
    }

def _build_label_prompt(lang: str) -> str:
    if lang == "zh-TW":
        return (
            "你是營養標示讀取助手。請根據包裝/營養標示圖片回傳 JSON。\n"
            "要求：\n"
            "- 僅回傳 JSON（不要多餘文字）\n"
            "- label_name: 產品或品名（若看不到可留空）\n"
            "- calorie_range: 若有熱量數字，請輸出區間或單一值（例：200 kcal 或 180-220 kcal）\n"
            "- macros: protein/carbs/fat/sodium 為 0-100 的百分比整數\n"
            "- confidence: 0 到 1 的信心分數\n"
            "- is_beverage: 是否為飲料（true/false）\n"
            "- 飲料規則：若為飲料，protein/fat 建議 <= 15\n"
            "JSON 範例：\n"
            "{\n"
            "  \"label_name\": \"無糖茶\",\n"
            "  \"calorie_range\": \"0-10 kcal\",\n"
            "  \"macros\": {\"protein\": 5, \"carbs\": 8, \"fat\": 5, \"sodium\": 15},\n"
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
        "- macros: protein/carbs/fat/sodium as integer percentages (0-100)\n"
        "- confidence: 0 to 1\n"
        "- is_beverage: true/false\n"
        "- Beverage rule: if beverage, protein/fat <= 15\n"
        "JSON example:\n"
        "{\n"
        "  \"label_name\": \"unsweetened tea\",\n"
        "  \"calorie_range\": \"0-10 kcal\",\n"
        "  \"macros\": {\"protein\": 5, \"carbs\": 8, \"fat\": 5, \"sodium\": 15},\n"
        "  \"confidence\": 0.7,\n"
        "  \"is_beverage\": true\n"
        "}\n"
    )


def _fallback_day_summary(lang: str, meals: List[MealSummaryInput]) -> dict:
    dish_text = " ".join([item for meal in meals for item in (meal.dish_summaries or [])])
    oily = any(word in dish_text for word in ["炸", "油", "酥", "奶油", "fried", "oily"])
    salty = any(word in dish_text for word in ["鹹", "鈉", "鹽", "salty", "sodium"])
    if lang == "zh-TW":
        if oily and salty:
            return {"day_summary": "油脂與鹽分偏高，注意清淡", "tomorrow_advice": "明天以清湯、蔬菜與瘦蛋白為主", "confidence": 0.5}
        if oily:
            return {"day_summary": "油脂偏高，整體尚可", "tomorrow_advice": "明天以清淡蛋白質與蔬菜為主", "confidence": 0.5}
        if salty:
            return {"day_summary": "鹽分略多，注意水分與清淡", "tomorrow_advice": "明天以清湯蔬菜搭配瘦蛋白", "confidence": 0.5}
        return {"day_summary": "整體均衡，維持即可", "tomorrow_advice": "明天以蛋白質與蔬菜為主", "confidence": 0.5}
    if oily and salty:
        return {"day_summary": "Higher fat and sodium today", "tomorrow_advice": "Tomorrow: lean protein + veggies", "confidence": 0.5}
    if oily:
        return {"day_summary": "Fat intake a bit high", "tomorrow_advice": "Tomorrow: lighter protein and veggies", "confidence": 0.5}
    if salty:
        return {"day_summary": "Sodium a bit high", "tomorrow_advice": "Tomorrow: clear soup + veggies", "confidence": 0.5}
    return {"day_summary": "Overall balanced", "tomorrow_advice": "Tomorrow: lean protein + veggies", "confidence": 0.5}


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
    label_context: str | None,
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
        label_context,
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
    data["macros"] = _normalize_macros(data, lang)
    data.setdefault("confidence", 0.6)
    data.setdefault("is_beverage", False)
    data.setdefault("dish_summary", "")

    usage = response.usage
    usage_data = None
    if usage is not None:
        usage_data = {
            "input_tokens": usage.prompt_tokens,
            "output_tokens": usage.completion_tokens,
            "total_tokens": usage.total_tokens,
        }
    return {"result": data, "usage": usage_data}


def _normalize_calorie_range(value: str) -> str:
    if not value:
        return ""
    match = [int(s) for s in value.replace(",", "").split() if s.isdigit()]
    if len(match) >= 2:
        return f"{match[0]}-{match[1]} kcal"
    if len(match) == 1:
        return f"{match[0]}-{match[0]} kcal"
    return value


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
    data["macros"] = _normalize_macros(data, lang)
    data["calorie_range"] = _normalize_calorie_range(data.get("calorie_range", ""))
    data.setdefault("confidence", 0.6)
    data.setdefault("is_beverage", False)
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
    note: Optional[str] = Form(default=None),
    context: Optional[str] = Form(default=None),
    portion_percent: Optional[int] = Form(default=None),
    height_cm: Optional[int] = Form(default=None),
    weight_kg: Optional[int] = Form(default=None),
    age: Optional[int] = Form(default=None),
    gender: Optional[str] = Form(default=None),
    goal: Optional[str] = Form(default=None),
    plan_speed: Optional[str] = Form(default=None),
    meal_type: Optional[str] = Form(default=None),
    meal_photo_count: Optional[int] = Form(default=None),
    advice_mode: Optional[str] = Form(default=None),
    force_reanalyze: Optional[str] = Form(default=None),
    label_context: Optional[str] = Form(default=None),
):
    image_bytes = await image.read()
    image_hash = _hash_image(image_bytes)

    use_lang = lang or DEFAULT_LANG
    if use_lang not in _fake_foods:
        use_lang = "zh-TW"

    force_reanalyze_flag = False
    if isinstance(force_reanalyze, str):
        force_reanalyze_flag = force_reanalyze.strip().lower() == "true"

    tier = "full"
    if (
        not force_reanalyze_flag
        and advice_mode != "current_meal"
        and food_name is None
        and note is None
        and context is None
        and portion_percent is None
        and advice_mode is None
        and label_context is None
    ):
        cache = _load_analysis_cache()
        cached = cache.get(image_hash)
        if isinstance(cached, dict) and isinstance(cached.get("result"), dict):
            cached_result = cached["result"]
            return AnalysisResult(
                food_name=cached_result.get("food_name", ""),
                calorie_range=cached_result.get("calorie_range", ""),
                macros=_normalize_macros(cached_result, use_lang),
                dish_summary=cached_result.get("dish_summary", ""),
                suggestion=cached_result.get("suggestion", ""),
                tier="cached",
                source="cache",
                cost_estimate_usd=None,
            )

    use_ai = _should_use_ai()
    profile = {
        "height_cm": height_cm,
        "weight_kg": weight_kg,
        "age": age,
        "gender": gender,
        "goal": goal,
        "plan_speed": plan_speed,
    }
    profile = {k: v for k, v in profile.items() if v not in (None, "", 0)}

    if use_ai and _client is not None:
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
                label_context,
            )
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
                normalized_macros = _normalize_macros(payload["result"], use_lang)
                cache[image_hash] = {
                    "saved_at": datetime.now(timezone.utc).isoformat(),
                    "result": {
                        "food_name": final_name,
                        "calorie_range": payload["result"]["calorie_range"],
                        "macros": normalized_macros,
                        "dish_summary": payload["result"].get("dish_summary", ""),
                        "suggestion": payload["result"]["suggestion"],
                    },
                }
                _save_analysis_cache(cache)
                return AnalysisResult(
                    food_name=final_name,
                    calorie_range=payload["result"]["calorie_range"],
                    macros=normalized_macros,
                    dish_summary=payload["result"].get("dish_summary", ""),
                    suggestion=payload["result"]["suggestion"],
                    tier=tier,
                    source="ai",
                    cost_estimate_usd=cost_estimate,
                    confidence=payload["result"].get("confidence"),
                    is_beverage=payload["result"].get("is_beverage"),
                    debug_reason=None,
                )
        except Exception as exc:
            global _last_ai_error
            _last_ai_error = str(exc)
            logging.exception("AI analyze failed: %s", exc)

    if CALL_REAL_AI and _client is None:
        logging.warning("CALL_REAL_AI is true but API_KEY is missing.")

    if CALL_REAL_AI and not use_ai:
        tier = "lite"

    chosen_name = food_name or random.choice(_fake_foods[use_lang])
    calorie_range = random.choice(["350-450 kcal", "450-600 kcal", "600-800 kcal"])
    macros = {
        "protein": float(random.choice(_fake_macro_choices)),
        "carbs": float(random.choice(_fake_macro_choices)),
        "fat": float(random.choice(_fake_macro_choices)),
        "sodium": float(random.choice(_fake_macro_choices)),
    }
    suggestion = random.choice(_fake_suggestions[use_lang])
    if advice_mode == "current_meal":
        if use_lang == "zh-TW":
            suggestion = (
                "可以吃：保留蔬菜與瘦肉\n"
                "不建議吃：湯底與加工配料\n"
                "份量上限：主食半碗、蛋白質一掌"
            )
        else:
            suggestion = (
                "Can eat: keep veggies and lean protein\n"
                "Avoid: broth and processed sides\n"
                "Portion limit: half bowl carbs, palm-sized protein"
            )

    debug_reason = None
    if CALL_REAL_AI and RETURN_AI_ERROR:
        debug_reason = _last_ai_error or "ai_failed_unknown"
    return AnalysisResult(
        food_name=chosen_name,
        calorie_range=calorie_range,
        macros=macros,
        dish_summary="",
        suggestion=suggestion,
        tier=tier,
        source="mock",
        cost_estimate_usd=None,
        confidence=0.35,
        is_beverage=False,
        debug_reason=debug_reason,
    )


@app.post("/analyze_label", response_model=LabelResult)
async def analyze_label(
    image: UploadFile = File(...),
    lang: str = Query(default=None, description="Language code, e.g. zh-TW, en"),
):
    image_bytes = await image.read()

    use_lang = lang or DEFAULT_LANG
    if use_lang not in _fake_foods:
        use_lang = "zh-TW"

    use_ai = _should_use_ai()
    if use_ai and _client is not None:
        try:
            payload = await asyncio.to_thread(_analyze_label_with_openai, image_bytes, use_lang)
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
        except Exception as exc:
            global _last_ai_error
            _last_ai_error = str(exc)
            logging.exception("Label analyze failed: %s", exc)

    if CALL_REAL_AI and _client is None:
        logging.warning("CALL_REAL_AI is true but API_KEY is missing.")

    macros = {
        "protein": float(random.choice(_fake_macro_choices)),
        "carbs": float(random.choice(_fake_macro_choices)),
        "fat": float(random.choice(_fake_macro_choices)),
        "sodium": float(random.choice(_fake_macro_choices)),
    }
    return LabelResult(
        label_name="",
        calorie_range="",
        macros=_normalize_macros({"macros": macros, "is_beverage": False}, use_lang),
        confidence=0.2,
        is_beverage=False,
        debug_reason=_last_ai_error if RETURN_AI_ERROR else None,
    )


@app.post("/summarize_day", response_model=DaySummaryResponse)
async def summarize_day(payload: DaySummaryRequest):
    use_lang = payload.lang or DEFAULT_LANG
    if use_lang not in _fake_foods:
        use_lang = "zh-TW"
    use_ai = _should_use_ai()
    if use_ai and _client is not None:
        try:
            prompt = _build_day_prompt(use_lang, payload.profile or {}, payload.meals)
            response = _client.chat.completions.create(
                model=OPENAI_MODEL,
                messages=[{"role": "user", "content": prompt}],
                temperature=0.2,
            )
            text = response.choices[0].message.content or ""
            data = _parse_json(text)
            if isinstance(data, dict) and "day_summary" in data and "tomorrow_advice" in data:
                return DaySummaryResponse(
                    day_summary=data.get("day_summary", ""),
                    tomorrow_advice=data.get("tomorrow_advice", ""),
                    source="ai",
                    confidence=(data.get("confidence") or 0.6),
                )
        except Exception as exc:
            global _last_ai_error
            _last_ai_error = str(exc)
            logging.exception("Day summary failed: %s", exc)
    fallback = _fallback_day_summary(use_lang, payload.meals)
    return DaySummaryResponse(
        day_summary=fallback.get("day_summary", ""),
        tomorrow_advice=fallback.get("tomorrow_advice", ""),
        source="mock",
        confidence=fallback.get("confidence", 0.5),
    )


@app.post("/summarize_week", response_model=WeekSummaryResponse)
async def summarize_week(payload: WeekSummaryRequest):
    use_lang = payload.lang or DEFAULT_LANG
    if use_lang not in _fake_foods:
        use_lang = "zh-TW"
    use_ai = _should_use_ai()
    if use_ai and _client is not None:
        try:
            prompt = _build_week_prompt(use_lang, payload.profile or {}, payload.days, payload.week_start, payload.week_end)
            response = _client.chat.completions.create(
                model=OPENAI_MODEL,
                messages=[{"role": "user", "content": prompt}],
                temperature=0.2,
            )
            text = response.choices[0].message.content or ""
            data = _parse_json(text)
            if isinstance(data, dict) and "week_summary" in data and "next_week_advice" in data:
                return WeekSummaryResponse(
                    week_summary=data.get("week_summary", ""),
                    next_week_advice=data.get("next_week_advice", ""),
                    source="ai",
                    confidence=(data.get("confidence") or 0.6),
                )
        except Exception as exc:
            global _last_ai_error
            _last_ai_error = str(exc)
            logging.exception("Week summary failed: %s", exc)
    fallback = _fallback_week_summary(use_lang, payload.days)
    return WeekSummaryResponse(
        week_summary=fallback.get("week_summary", ""),
        next_week_advice=fallback.get("next_week_advice", ""),
        source="mock",
        confidence=fallback.get("confidence", 0.5),
    )


@app.post("/suggest_meal", response_model=MealAdviceResponse)
async def suggest_meal(payload: MealAdviceRequest):
    use_lang = payload.lang or DEFAULT_LANG
    if use_lang not in _fake_foods:
        use_lang = "zh-TW"
    profile = payload.profile or {}
    if CALL_REAL_AI and _client is not None and _should_use_ai():
        try:
            prompt = _build_meal_advice_prompt(use_lang, profile, payload)
            response = _client.chat.completions.create(
                model=OPENAI_MODEL,
                messages=[{"role": "user", "content": prompt}],
                temperature=0.2,
            )
            text = response.choices[0].message.content or ""
            data = _parse_json(text)
            if isinstance(data, dict):
                required = {"self_cook", "convenience", "bento", "other"}
                if required.issubset(set(data.keys())):
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
        except Exception as exc:
            global _last_ai_error
            _last_ai_error = str(exc)
            logging.exception("Meal advice failed: %s", exc)
    fallback = _fallback_meal_advice(use_lang)
    return MealAdviceResponse(
        self_cook=fallback["self_cook"],
        convenience=fallback["convenience"],
        bento=fallback["bento"],
        other=fallback["other"],
        source="mock",
        confidence=fallback.get("confidence"),
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
