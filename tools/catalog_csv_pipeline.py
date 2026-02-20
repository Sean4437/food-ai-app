#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import json
import os
import re
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any
from urllib import error, request

CATALOG_COLUMNS = [
    "food_name",
    "canonical_name",
    "calorie_range",
    "protein_g",
    "carbs_g",
    "fat_g",
    "sodium_mg",
    "dish_summary",
    "suggestion",
    "food_items_json",
    "judgement_tags_json",
    "is_beverage",
    "is_food",
    "source",
    "verified_level",
    "image_url",
    "thumb_url",
    "image_source",
    "image_license",
    "reference_used",
]

ALIAS_COLUMNS = ["food_name", "lang", "alias"]
ZH_TAGS = {"清淡", "偏油", "碳水偏多", "蛋白不足", "高鈉", "高糖", "纖維不足"}


@dataclass
class InputFood:
    food_name: str
    alias_zh: list[str]
    alias_en: list[str]
    portion_hint: str


class DraftError(RuntimeError):
    pass


def _split_aliases(raw: str) -> list[str]:
    if not raw:
        return []
    parts = re.split(r"[;,，、/|]+", raw)
    result: list[str] = []
    seen: set[str] = set()
    for part in parts:
        value = part.strip()
        if not value:
            continue
        key = value.lower()
        if key in seen:
            continue
        seen.add(key)
        result.append(value)
    return result


def _is_zh_text(value: str) -> bool:
    return re.search(r"[\u4e00-\u9fff]", value) is not None


def _auto_portion_hint(food_name: str) -> str:
    text = food_name.strip()
    lower = text.lower()
    if not text:
        return "1 serving"

    beverage_tokens = [
        "茶",
        "咖啡",
        "豆漿",
        "果汁",
        "奶茶",
        "拿鐵",
        "可樂",
        "汽水",
        "飲",
        "tea",
        "coffee",
        "juice",
        "latte",
        "soda",
        "drink",
    ]
    soup_noodle_tokens = ["麵", "拉麵", "粥", "湯", "鍋", "麵線", "米粉湯"]
    rice_bowl_tokens = ["飯", "便當", "丼", "炒飯", "餐盒", "壽司"]
    light_tokens = ["沙拉", "水果", "地瓜", "香蕉", "蘋果", "芭樂", "茶葉蛋"]

    if any(t in text for t in beverage_tokens) or any(t in lower for t in beverage_tokens):
        return "medium cup (500 ml)"
    if any(t in text for t in soup_noodle_tokens):
        return "1 bowl (about 550 g)"
    if any(t in text for t in rice_bowl_tokens):
        return "1 meal box / bowl (about 420 g)"
    if any(t in text for t in light_tokens):
        return "1 serving (about 180 g)"
    return "1 serving (about 300 g)"


def load_input(path: Path) -> list[InputFood]:
    if not path.exists():
        raise DraftError(f"input not found: {path}")
    foods: list[InputFood] = []
    seen: set[str] = set()
    if path.suffix.lower() == ".csv":
        with path.open("r", encoding="utf-8-sig", newline="") as f:
            reader = csv.DictReader(f)
            headers = {h.strip() for h in (reader.fieldnames or [])}
            if "food_name" not in headers and headers:
                raise DraftError("CSV must include `food_name` column")
            for row in reader:
                name = (row.get("food_name") or "").strip()
                if not name:
                    continue
                key = name.lower()
                if key in seen:
                    continue
                seen.add(key)
                portion_hint = (row.get("portion_hint") or "").strip()
                if not portion_hint:
                    portion_hint = _auto_portion_hint(name)
                foods.append(
                    InputFood(
                        food_name=name,
                        alias_zh=_split_aliases((row.get("alias_zh") or "").strip()),
                        alias_en=_split_aliases((row.get("alias_en") or "").strip()),
                        portion_hint=portion_hint,
                    )
                )
        return foods

    with path.open("r", encoding="utf-8-sig") as f:
        for raw in f:
            line = raw.strip()
            if not line or line.startswith("#"):
                continue
            # text format:
            # food_name
            # food_name|alias_zh_1,alias_zh_2|alias_en_1,alias_en_2|portion_hint
            parts = [p.strip() for p in line.split("|")]
            name = parts[0]
            if not name:
                continue
            key = name.lower()
            if key in seen:
                continue
            seen.add(key)
            alias_zh = _split_aliases(parts[1]) if len(parts) >= 2 else []
            alias_en = _split_aliases(parts[2]) if len(parts) >= 3 else []
            portion_hint = parts[3].strip() if len(parts) >= 4 else ""
            if not portion_hint:
                portion_hint = _auto_portion_hint(name)
            foods.append(
                InputFood(
                    food_name=name,
                    alias_zh=alias_zh,
                    alias_en=alias_en,
                    portion_hint=portion_hint,
                )
            )
    return foods


def _extract_json(text: str) -> dict[str, Any]:
    text = text.strip()
    if not text:
        raise DraftError("empty model output")
    try:
        parsed = json.loads(text)
        if isinstance(parsed, dict):
            return parsed
    except json.JSONDecodeError:
        pass

    match = re.search(r"\{[\s\S]*\}", text)
    if not match:
        raise DraftError(f"model output is not valid JSON: {text[:180]}")
    try:
        parsed = json.loads(match.group(0))
    except json.JSONDecodeError as exc:
        raise DraftError(f"failed to parse model JSON: {exc}") from exc
    if not isinstance(parsed, dict):
        raise DraftError("model output JSON must be an object")
    return parsed


def _openai_chat_completion(
    api_key: str,
    model: str,
    food_name: str,
    portion_hint: str,
) -> dict[str, Any]:
    system_prompt = (
        "You are a nutrition data drafting assistant. "
        "Return only one JSON object with no markdown."
    )
    user_prompt = (
        "Create a draft entry for food catalog import.\n"
        f"Food name: {food_name}\n\n"
        f"Portion baseline: {portion_hint}\n\n"
        "Rules:\n"
        "1) Use Traditional Chinese for dish_summary_zh, suggestion_zh, aliases_zh.\n"
        "2) Use short plain text.\n"
        "3) calorie_min_kcal <= calorie_max_kcal.\n"
        "4) sodium_mg is in mg. protein/carbs/fat are in grams.\n"
        "5) judgement_tags_zh must be from: 清淡, 偏油, 碳水偏多, 蛋白不足, 高鈉, 高糖, 纖維不足.\n"
        "6) All nutrition values must follow the portion baseline above.\n\n"
        "Return JSON schema:\n"
        "{\n"
        '  "canonical_name_en": "string",\n'
        '  "calorie_min_kcal": 0,\n'
        '  "calorie_max_kcal": 0,\n'
        '  "protein_g": 0,\n'
        '  "carbs_g": 0,\n'
        '  "fat_g": 0,\n'
        '  "sodium_mg": 0,\n'
        '  "dish_summary_zh": "string",\n'
        '  "suggestion_zh": "string",\n'
        '  "food_items_zh": ["string"],\n'
        '  "judgement_tags_zh": ["string"],\n'
        '  "is_beverage": false,\n'
        '  "aliases_zh": ["string"],\n'
        '  "aliases_en": ["string"]\n'
        "}\n"
    )

    payload = {
        "model": model,
        "temperature": 0.2,
        "response_format": {"type": "json_object"},
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt},
        ],
    }
    data = json.dumps(payload).encode("utf-8")
    req = request.Request(
        "https://api.openai.com/v1/chat/completions",
        data=data,
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    try:
        with request.urlopen(req, timeout=90) as resp:
            body = json.loads(resp.read().decode("utf-8"))
    except error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="ignore")
        raise DraftError(f"OpenAI HTTP {exc.code}: {detail}") from exc
    except Exception as exc:
        raise DraftError(f"OpenAI request failed: {exc}") from exc

    choices = body.get("choices")
    if not isinstance(choices, list) or not choices:
        raise DraftError("OpenAI returned no choices")
    message = choices[0].get("message", {})
    content = message.get("content", "")
    if not isinstance(content, str):
        raise DraftError("OpenAI content is empty")
    return _extract_json(content)


def _to_float(value: Any, default: float = 0.0) -> float:
    if isinstance(value, (int, float)):
        return float(value)
    if isinstance(value, str):
        try:
            return float(value.strip())
        except ValueError:
            return default
    return default


def _to_int(value: Any, default: int) -> int:
    if isinstance(value, bool):
        return default
    if isinstance(value, (int, float)):
        return int(round(float(value)))
    if isinstance(value, str):
        m = re.search(r"-?\d+(?:\.\d+)?", value)
        if m:
            return int(round(float(m.group(0))))
    return default


def _normalize_string_list(value: Any, limit: int = 6) -> list[str]:
    if not isinstance(value, list):
        return []
    result: list[str] = []
    seen: set[str] = set()
    for item in value:
        text = str(item).strip()
        if not text:
            continue
        key = text.lower()
        if key in seen:
            continue
        seen.add(key)
        result.append(text)
        if len(result) >= limit:
            break
    return result


def _normalize_tags(tags: list[str], protein_g: float, carbs_g: float, fat_g: float, sodium_mg: float) -> list[str]:
    normalized = [t for t in tags if t in ZH_TAGS]
    if normalized:
        return normalized[:3]
    guessed: list[str] = []
    if fat_g >= 25:
        guessed.append("偏油")
    if carbs_g >= 55:
        guessed.append("碳水偏多")
    if protein_g <= 15:
        guessed.append("蛋白不足")
    if sodium_mg >= 1000:
        guessed.append("高鈉")
    if not guessed:
        guessed.append("清淡")
    return guessed[:3]


def _calorie_range(cal_min: int, cal_max: int, protein_g: float, carbs_g: float, fat_g: float) -> str:
    if cal_min <= 0 or cal_max <= 0:
        est = int(round((protein_g * 4.0) + (carbs_g * 4.0) + (fat_g * 9.0)))
        if est <= 0:
            est = 350
        cal_min = max(50, int(round(est * 0.85)))
        cal_max = max(cal_min + 40, int(round(est * 1.15)))
    if cal_min > cal_max:
        cal_min, cal_max = cal_max, cal_min
    cal_min = max(50, min(4000, cal_min))
    cal_max = max(cal_min, min(4500, cal_max))
    return f"{cal_min}-{cal_max} kcal"


def _default_is_beverage(food_name: str) -> bool:
    lower = food_name.lower()
    if _is_zh_text(food_name):
        return any(k in food_name for k in ["茶", "咖啡", "豆漿", "牛奶", "飲", "果汁", "可可"])
    return any(k in lower for k in ["tea", "coffee", "milk", "juice", "drink", "latte", "soda", "smoothie"])


def _build_rows(food: InputFood, draft: dict[str, Any]) -> tuple[dict[str, Any], list[dict[str, str]]]:
    canonical_name = str(draft.get("canonical_name_en") or "").strip().lower()
    protein_g = max(0.0, _to_float(draft.get("protein_g"), 0.0))
    carbs_g = max(0.0, _to_float(draft.get("carbs_g"), 0.0))
    fat_g = max(0.0, _to_float(draft.get("fat_g"), 0.0))
    sodium_mg = max(0.0, _to_float(draft.get("sodium_mg"), 0.0))
    cal_min = _to_int(draft.get("calorie_min_kcal"), 0)
    cal_max = _to_int(draft.get("calorie_max_kcal"), 0)
    calorie_range = _calorie_range(cal_min, cal_max, protein_g, carbs_g, fat_g)

    dish_summary = str(draft.get("dish_summary_zh") or "").strip()
    suggestion = str(draft.get("suggestion_zh") or "").strip()
    if not dish_summary:
        dish_summary = f"{food.food_name}（AI 草稿）"
    if not suggestion:
        suggestion = "可補充份量與品牌，讓估算更準確。"
    portion_note = f"（份量基準：{food.portion_hint}）"
    if portion_note not in dish_summary:
        dish_summary = f"{dish_summary}{portion_note}"

    food_items = _normalize_string_list(draft.get("food_items_zh"), limit=8)
    if not food_items:
        food_items = [food.food_name]

    tags = _normalize_tags(
        _normalize_string_list(draft.get("judgement_tags_zh"), limit=6),
        protein_g=protein_g,
        carbs_g=carbs_g,
        fat_g=fat_g,
        sodium_mg=sodium_mg,
    )

    is_beverage_raw = draft.get("is_beverage")
    is_beverage = bool(is_beverage_raw) if isinstance(is_beverage_raw, bool) else _default_is_beverage(food.food_name)

    catalog_row = {
        "food_name": food.food_name,
        "canonical_name": canonical_name,
        "calorie_range": calorie_range,
        "protein_g": f"{protein_g:.1f}".rstrip("0").rstrip("."),
        "carbs_g": f"{carbs_g:.1f}".rstrip("0").rstrip("."),
        "fat_g": f"{fat_g:.1f}".rstrip("0").rstrip("."),
        "sodium_mg": f"{sodium_mg:.1f}".rstrip("0").rstrip("."),
        "dish_summary": dish_summary,
        "suggestion": suggestion,
        "food_items_json": json.dumps(food_items, ensure_ascii=False),
        "judgement_tags_json": json.dumps(tags, ensure_ascii=False),
        "is_beverage": "true" if is_beverage else "false",
        "is_food": "true",
        "source": "ai_estimate",
        "verified_level": "0",
        "image_url": "",
        "thumb_url": "",
        "image_source": "",
        "image_license": "",
        "reference_used": "ai_draft",
    }

    aliases_zh = _normalize_string_list(draft.get("aliases_zh"), limit=12)
    aliases_en = _normalize_string_list(draft.get("aliases_en"), limit=12)
    aliases_zh.extend(food.alias_zh)
    aliases_en.extend(food.alias_en)

    if _is_zh_text(food.food_name):
        aliases_zh.insert(0, food.food_name)
    else:
        aliases_en.insert(0, food.food_name)

    alias_rows: list[dict[str, str]] = []
    seen_alias: set[tuple[str, str]] = set()
    for lang, alias_list in [("zh-TW", aliases_zh), ("en", aliases_en)]:
        for alias in alias_list:
            text = alias.strip()
            if not text:
                continue
            key = (lang, text.lower())
            if key in seen_alias:
                continue
            seen_alias.add(key)
            alias_rows.append({"food_name": food.food_name, "lang": lang, "alias": text})
    return catalog_row, alias_rows


def write_csv(path: Path, columns: list[str], rows: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8-sig", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=columns)
        writer.writeheader()
        for row in rows:
            out = {k: row.get(k, "") for k in columns}
            writer.writerow(out)


def cmd_draft(args: argparse.Namespace) -> int:
    foods = load_input(Path(args.input))
    if not foods:
        raise DraftError("no food items found in input")
    if args.max_items and args.max_items > 0:
        foods = foods[: args.max_items]

    api_key = os.getenv(args.api_key_env, "").strip()
    if not api_key:
        raise DraftError(f"missing API key env: {args.api_key_env}")

    catalog_rows: list[dict[str, Any]] = []
    alias_rows: list[dict[str, str]] = []
    failures: list[str] = []

    for idx, food in enumerate(foods, start=1):
        print(f"[{idx}/{len(foods)}] drafting: {food.food_name}")
        try:
            draft = _openai_chat_completion(
                api_key=api_key,
                model=args.model,
                food_name=food.food_name,
                portion_hint=food.portion_hint,
            )
            catalog_row, alias_batch = _build_rows(food, draft)
            catalog_rows.append(catalog_row)
            alias_rows.extend(alias_batch)
        except Exception as exc:
            failures.append(f"{food.food_name}: {exc}")
            print(f"  ! failed: {exc}", file=sys.stderr)
        if args.sleep_ms > 0 and idx < len(foods):
            time.sleep(args.sleep_ms / 1000.0)

    if not catalog_rows:
        raise DraftError("all rows failed; no output generated")

    out_catalog = Path(args.out_catalog)
    out_alias = Path(args.out_alias)
    write_csv(out_catalog, CATALOG_COLUMNS, catalog_rows)
    write_csv(out_alias, ALIAS_COLUMNS, alias_rows)

    print("")
    print(f"catalog rows: {len(catalog_rows)} -> {out_catalog}")
    print(f"alias rows:   {len(alias_rows)} -> {out_alias}")
    if failures:
        print("")
        print("failed items:")
        for line in failures:
            print(f"- {line}")
    print("")
    print("next step:")
    print(f"python tools/catalog_csv_pipeline.py validate --catalog \"{out_catalog}\" --alias \"{out_alias}\"")
    return 0 if not failures else 2


def _parse_bool(raw: str) -> bool | None:
    lower = raw.strip().lower()
    if lower in {"true", "t", "1", "yes", "y"}:
        return True
    if lower in {"false", "f", "0", "no", "n"}:
        return False
    return None


def _validate_catalog(path: Path) -> tuple[list[str], list[str], set[str]]:
    errors: list[str] = []
    warnings: list[str] = []
    names: set[str] = set()
    if not path.exists():
        return [f"catalog file not found: {path}"], warnings, names

    with path.open("r", encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f)
        headers = reader.fieldnames or []
        missing = [c for c in CATALOG_COLUMNS if c not in headers]
        if missing:
            errors.append(f"catalog missing columns: {', '.join(missing)}")
            return errors, warnings, names

        for i, row in enumerate(reader, start=2):
            food_name = (row.get("food_name") or "").strip()
            if not food_name:
                errors.append(f"catalog line {i}: food_name is required")
                continue

            key = food_name.lower()
            if key in names:
                errors.append(f"catalog line {i}: duplicate food_name `{food_name}`")
            names.add(key)

            calorie_range = (row.get("calorie_range") or "").strip()
            m = re.match(r"^\s*(\d+)\s*-\s*(\d+)\s*kcal\s*$", calorie_range, flags=re.IGNORECASE)
            if not m:
                errors.append(f"catalog line {i}: invalid calorie_range `{calorie_range}`")
            else:
                lo, hi = int(m.group(1)), int(m.group(2))
                if lo > hi:
                    errors.append(f"catalog line {i}: calorie_range min > max")
                if hi > 4500:
                    warnings.append(f"catalog line {i}: unusually high calorie_range `{calorie_range}`")

            for key_num in ["protein_g", "carbs_g", "fat_g", "sodium_mg"]:
                raw = (row.get(key_num) or "").strip()
                try:
                    val = float(raw)
                except ValueError:
                    errors.append(f"catalog line {i}: `{key_num}` is not numeric")
                    continue
                if val < 0:
                    errors.append(f"catalog line {i}: `{key_num}` must be >= 0")
                if key_num != "sodium_mg" and val > 300:
                    warnings.append(f"catalog line {i}: `{key_num}` unusually high ({val})")
                if key_num == "sodium_mg" and val > 10000:
                    warnings.append(f"catalog line {i}: `sodium_mg` unusually high ({val})")

            for key_json in ["food_items_json", "judgement_tags_json"]:
                raw_json = (row.get(key_json) or "").strip()
                try:
                    parsed = json.loads(raw_json)
                except json.JSONDecodeError:
                    errors.append(f"catalog line {i}: `{key_json}` is not valid JSON")
                    continue
                if not isinstance(parsed, list):
                    errors.append(f"catalog line {i}: `{key_json}` must be a JSON array")

            for key_bool in ["is_beverage", "is_food"]:
                raw_bool = (row.get(key_bool) or "").strip()
                if _parse_bool(raw_bool) is None:
                    errors.append(f"catalog line {i}: `{key_bool}` must be true/false")

            verified = (row.get("verified_level") or "").strip()
            if not re.match(r"^-?\d+$", verified):
                errors.append(f"catalog line {i}: `verified_level` must be integer")

            source = (row.get("source") or "").strip()
            if not source:
                errors.append(f"catalog line {i}: `source` is required")

    return errors, warnings, names


def _validate_alias(path: Path, catalog_names: set[str]) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []
    if not path.exists():
        return [f"alias file not found: {path}"], warnings

    with path.open("r", encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f)
        headers = reader.fieldnames or []
        missing = [c for c in ALIAS_COLUMNS if c not in headers]
        if missing:
            errors.append(f"alias missing columns: {', '.join(missing)}")
            return errors, warnings

        seen: set[tuple[str, str, str]] = set()
        for i, row in enumerate(reader, start=2):
            food_name = (row.get("food_name") or "").strip()
            lang = (row.get("lang") or "").strip()
            alias = (row.get("alias") or "").strip()
            if not food_name:
                errors.append(f"alias line {i}: food_name is required")
                continue
            if not alias:
                errors.append(f"alias line {i}: alias is required")
                continue
            if not lang:
                errors.append(f"alias line {i}: lang is required")
                continue
            if lang not in {"zh-TW", "zh-CN", "en"}:
                warnings.append(f"alias line {i}: uncommon lang `{lang}`")

            if food_name.lower() not in catalog_names:
                errors.append(f"alias line {i}: food_name `{food_name}` not found in catalog")

            key = (food_name.lower(), lang.lower(), alias.lower())
            if key in seen:
                errors.append(f"alias line {i}: duplicate alias ({food_name}, {lang}, {alias})")
            seen.add(key)

    return errors, warnings


def cmd_validate(args: argparse.Namespace) -> int:
    catalog_path = Path(args.catalog)
    alias_path = Path(args.alias)
    c_errors, c_warnings, names = _validate_catalog(catalog_path)
    a_errors, a_warnings = _validate_alias(alias_path, names)
    errors = c_errors + a_errors
    warnings = c_warnings + a_warnings

    print("validation result")
    print(f"- errors: {len(errors)}")
    print(f"- warnings: {len(warnings)}")
    if errors:
        print("")
        print("errors:")
        for e in errors:
            print(f"- {e}")
    if warnings:
        print("")
        print("warnings:")
        for w in warnings:
            print(f"- {w}")
    return 1 if errors else 0


def cmd_portionize(args: argparse.Namespace) -> int:
    foods = load_input(Path(args.input))
    if not foods:
        raise DraftError("no food items found in input")
    out = Path(args.output)
    rows: list[dict[str, str]] = []
    for food in foods:
        rows.append(
            {
                "food_name": food.food_name,
                "portion_hint": food.portion_hint,
                "alias_zh": ",".join(food.alias_zh),
                "alias_en": ",".join(food.alias_en),
            }
        )
    write_csv(out, ["food_name", "portion_hint", "alias_zh", "alias_en"], rows)
    print(f"wrote {len(rows)} rows -> {out}")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Generate and validate food catalog/alias CSV files for Supabase import."
    )
    sub = parser.add_subparsers(dest="command", required=True)

    draft = sub.add_parser("draft", help="Draft catalog + aliases CSV from a food-name list via OpenAI.")
    draft.add_argument("--input", required=True, help="Input txt/csv path.")
    draft.add_argument(
        "--out-catalog",
        default="backend/sql/food_catalog_import_generated.csv",
        help="Output catalog CSV path.",
    )
    draft.add_argument(
        "--out-alias",
        default="backend/sql/food_aliases_import_generated.csv",
        help="Output aliases CSV path.",
    )
    draft.add_argument("--model", default="gpt-4.1-mini", help="OpenAI model.")
    draft.add_argument("--api-key-env", default="OPENAI_API_KEY", help="Environment variable name for OpenAI API key.")
    draft.add_argument("--max-items", type=int, default=0, help="Limit number of input foods (0 = all).")
    draft.add_argument("--sleep-ms", type=int, default=350, help="Delay between API calls.")
    draft.set_defaults(func=cmd_draft)

    validate = sub.add_parser("validate", help="Validate generated catalog + aliases CSV files.")
    validate.add_argument("--catalog", required=True, help="Catalog CSV path.")
    validate.add_argument("--alias", required=True, help="Alias CSV path.")
    validate.set_defaults(func=cmd_validate)

    portionize = sub.add_parser(
        "portionize",
        help="Convert txt/csv input into a reviewable CSV with auto portion hints.",
    )
    portionize.add_argument("--input", required=True, help="Input txt/csv path.")
    portionize.add_argument(
        "--output",
        default="backend/sql/food_names_with_portion.csv",
        help="Output CSV path.",
    )
    portionize.set_defaults(func=cmd_portionize)
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    try:
        return int(args.func(args))
    except DraftError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
