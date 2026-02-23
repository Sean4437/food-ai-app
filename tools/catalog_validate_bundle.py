#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

CATALOG_REQUIRED_COLUMNS = [
    "lang",
    "food_name",
    "canonical_name",
    "calorie_range",
    "macros",
    "food_items",
    "judgement_tags",
    "dish_summary",
    "suggestion",
    "is_beverage",
    "is_food",
    "is_active",
    "beverage_profile",
    "source",
    "verified_level",
    "reference_used",
]

ALIAS_REQUIRED_COLUMNS = [
    "food_name",
    "lang",
    "alias",
]

CALORIE_RE = re.compile(r"^\s*\d+\s*-\s*\d+\s*kcal\s*$", re.IGNORECASE)


@dataclass(frozen=True)
class CatalogKey:
    lang: str
    name: str


def normalize_text(value: str) -> str:
    return " ".join((value or "").strip().lower().split())


def parse_bool(raw: str) -> bool | None:
    value = (raw or "").strip().lower()
    if value in {"true", "t", "1", "yes", "y"}:
        return True
    if value in {"false", "f", "0", "no", "n"}:
        return False
    return None


def read_json(raw: str, expected_type: type, field_name: str, file_path: Path, line_no: int, errors: list[str]) -> Any:
    text = (raw or "").strip()
    if not text:
        if expected_type is dict:
            return {}
        return []
    try:
        data = json.loads(text)
    except Exception:
        errors.append(f"{file_path}:{line_no} invalid JSON in `{field_name}`")
        return {} if expected_type is dict else []
    if not isinstance(data, expected_type):
        errors.append(
            f"{file_path}:{line_no} `{field_name}` must be {expected_type.__name__}"
        )
        return {} if expected_type is dict else []
    return data


def resolve_paths(globs: list[str], files: list[str]) -> list[Path]:
    output: list[Path] = []
    seen: set[str] = set()
    for pattern in globs:
        matches = list(Path(".").glob(pattern))
        if not matches and Path(pattern).exists():
            matches = [Path(pattern)]
        for path in matches:
            key = str(path.resolve())
            if key in seen:
                continue
            seen.add(key)
            output.append(path)
    for raw in files:
        path = Path(raw)
        if not path.exists():
            continue
        key = str(path.resolve())
        if key in seen:
            continue
        seen.add(key)
        output.append(path)
    output.sort(key=lambda p: str(p))
    return output


def validate_bundle(
    catalog_paths: list[Path],
    alias_paths: list[Path],
    allow_ambiguous_alias: bool,
) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []

    catalog_food_keys: dict[CatalogKey, str] = {}
    catalog_canonical_keys: dict[CatalogKey, str] = {}
    all_food_name_norms: set[str] = set()

    for path in catalog_paths:
        with path.open("r", encoding="utf-8-sig", newline="") as handle:
            reader = csv.DictReader(handle)
            headers = reader.fieldnames or []
            missing = [col for col in CATALOG_REQUIRED_COLUMNS if col not in headers]
            if missing:
                errors.append(f"{path}: missing columns -> {', '.join(missing)}")
                continue

            for line_no, row in enumerate(reader, start=2):
                lang = (str(row.get("lang") or "").strip() or "zh-TW")
                food_name = str(row.get("food_name") or "").strip()
                canonical_name = str(row.get("canonical_name") or "").strip()
                calorie_range = str(row.get("calorie_range") or "").strip()
                source = str(row.get("source") or "").strip()
                verified_level = str(row.get("verified_level") or "").strip()
                is_beverage = str(row.get("is_beverage") or "").strip()
                is_food = str(row.get("is_food") or "").strip()
                is_active = str(row.get("is_active") or "").strip()
                ref_used = str(row.get("reference_used") or "").strip()

                if not food_name:
                    errors.append(f"{path}:{line_no} `food_name` is required")
                    continue
                if not source:
                    errors.append(f"{path}:{line_no} `source` is required")
                if not ref_used:
                    warnings.append(f"{path}:{line_no} `reference_used` is empty")
                if not CALORIE_RE.match(calorie_range):
                    errors.append(f"{path}:{line_no} invalid `calorie_range` -> {calorie_range}")

                if parse_bool(is_beverage) is None:
                    errors.append(f"{path}:{line_no} `is_beverage` must be true/false")
                if parse_bool(is_food) is None:
                    errors.append(f"{path}:{line_no} `is_food` must be true/false")
                if parse_bool(is_active) is None:
                    errors.append(f"{path}:{line_no} `is_active` must be true/false")

                if not re.fullmatch(r"-?\d+", verified_level):
                    errors.append(f"{path}:{line_no} `verified_level` must be integer")

                macros = read_json(str(row.get("macros") or ""), dict, "macros", path, line_no, errors)
                for key in ("protein", "carbs", "fat", "sodium"):
                    raw = macros.get(key, 0) if isinstance(macros, dict) else 0
                    try:
                        value = float(raw)
                    except Exception:
                        errors.append(f"{path}:{line_no} `macros.{key}` must be numeric")
                        continue
                    if value < 0:
                        errors.append(f"{path}:{line_no} `macros.{key}` must be >= 0")

                read_json(str(row.get("food_items") or ""), list, "food_items", path, line_no, errors)
                read_json(str(row.get("judgement_tags") or ""), list, "judgement_tags", path, line_no, errors)
                read_json(str(row.get("beverage_profile") or ""), dict, "beverage_profile", path, line_no, errors)

                key_food = CatalogKey(lang=lang, name=normalize_text(food_name))
                key_food_prev = catalog_food_keys.get(key_food)
                if key_food_prev:
                    errors.append(
                        f"{path}:{line_no} duplicate food_name key ({lang}, {food_name})"
                        f" also seen in {key_food_prev}"
                    )
                else:
                    catalog_food_keys[key_food] = f"{path}:{line_no}"

                if canonical_name:
                    key_canonical = CatalogKey(lang=lang, name=normalize_text(canonical_name))
                    key_canonical_prev = catalog_canonical_keys.get(key_canonical)
                    if key_canonical_prev:
                        errors.append(
                            f"{path}:{line_no} duplicate canonical_name key ({lang}, {canonical_name})"
                            f" also seen in {key_canonical_prev}"
                        )
                    else:
                        catalog_canonical_keys[key_canonical] = f"{path}:{line_no}"

                all_food_name_norms.add(normalize_text(food_name))

    alias_seen: dict[tuple[str, str, str], str] = {}
    alias_to_foods: dict[tuple[str, str], set[str]] = {}

    for path in alias_paths:
        with path.open("r", encoding="utf-8-sig", newline="") as handle:
            reader = csv.DictReader(handle)
            headers = reader.fieldnames or []
            missing = [col for col in ALIAS_REQUIRED_COLUMNS if col not in headers]
            if missing:
                errors.append(f"{path}: missing columns -> {', '.join(missing)}")
                continue

            for line_no, row in enumerate(reader, start=2):
                food_name = str(row.get("food_name") or "").strip()
                lang = (str(row.get("lang") or "").strip() or "zh-TW")
                alias = str(row.get("alias") or "").strip()

                if not food_name:
                    errors.append(f"{path}:{line_no} `food_name` is required")
                    continue
                if not alias:
                    errors.append(f"{path}:{line_no} `alias` is required")
                    continue

                food_norm = normalize_text(food_name)
                alias_norm = normalize_text(alias)
                if food_norm not in all_food_name_norms:
                    errors.append(
                        f"{path}:{line_no} alias points to unknown food_name `{food_name}`"
                    )

                dedupe_key = (food_norm, lang.lower(), alias_norm)
                prev = alias_seen.get(dedupe_key)
                if prev:
                    errors.append(
                        f"{path}:{line_no} duplicate alias tuple ({food_name}, {lang}, {alias})"
                        f" also seen in {prev}"
                    )
                else:
                    alias_seen[dedupe_key] = f"{path}:{line_no}"

                alias_key = (lang.lower(), alias_norm)
                alias_to_foods.setdefault(alias_key, set()).add(food_norm)

    for (lang, alias_norm), foods in sorted(alias_to_foods.items()):
        if len(foods) <= 1:
            continue
        msg = f"ambiguous alias `{alias_norm}` in lang `{lang}` maps to {len(foods)} foods"
        if allow_ambiguous_alias:
            warnings.append(msg)
        else:
            errors.append(msg)

    return errors, warnings


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Validate food catalog + alias CSV drafts as one bundle."
    )
    parser.add_argument(
        "--catalog-glob",
        action="append",
        default=[],
        help="Catalog glob/path (repeatable).",
    )
    parser.add_argument(
        "--alias-glob",
        action="append",
        default=[],
        help="Alias glob/path (repeatable).",
    )
    parser.add_argument(
        "--catalog-file",
        action="append",
        default=[],
        help="Explicit catalog CSV file (repeatable).",
    )
    parser.add_argument(
        "--alias-file",
        action="append",
        default=[],
        help="Explicit alias CSV file (repeatable).",
    )
    parser.add_argument(
        "--allow-ambiguous-alias",
        action="store_true",
        help="Downgrade alias ambiguity from error to warning.",
    )
    parser.add_argument(
        "--report-json",
        default="",
        help="Optional output report JSON path.",
    )
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    catalog_globs = args.catalog_glob or ["backend/sql/food_catalog*_draft.csv"]
    alias_globs = args.alias_glob or ["backend/sql/food_aliases*_draft.csv"]

    catalog_paths = resolve_paths(catalog_globs, args.catalog_file)
    alias_paths = resolve_paths(alias_globs, args.alias_file)

    if not catalog_paths:
        print("error: no catalog CSV files found", file=sys.stderr)
        return 2
    if not alias_paths:
        print("error: no alias CSV files found", file=sys.stderr)
        return 2

    errors, warnings = validate_bundle(
        catalog_paths=catalog_paths,
        alias_paths=alias_paths,
        allow_ambiguous_alias=bool(args.allow_ambiguous_alias),
    )

    print("catalog bundle validation")
    print(f"- catalog files: {len(catalog_paths)}")
    print(f"- alias files:   {len(alias_paths)}")
    print(f"- errors:        {len(errors)}")
    print(f"- warnings:      {len(warnings)}")

    if errors:
        print("")
        print("errors:")
        for msg in errors:
            print(f"- {msg}")

    if warnings:
        print("")
        print("warnings:")
        for msg in warnings:
            print(f"- {msg}")

    if args.report_json:
        report_path = Path(args.report_json)
        report_path.parent.mkdir(parents=True, exist_ok=True)
        report_path.write_text(
            json.dumps(
                {
                    "catalog_files": [str(p) for p in catalog_paths],
                    "alias_files": [str(p) for p in alias_paths],
                    "errors": errors,
                    "warnings": warnings,
                },
                ensure_ascii=False,
                indent=2,
            ),
            encoding="utf-8",
        )

    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
