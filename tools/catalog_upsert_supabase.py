#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import json
import os
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any
from urllib import error, parse, request

BOOL_TRUE = {"true", "t", "1", "yes", "y"}
BOOL_FALSE = {"false", "f", "0", "no", "n"}


def normalize_text(value: str) -> str:
    return " ".join((value or "").strip().lower().split())


def parse_bool(value: str, default: bool | None = None) -> bool | None:
    raw = (value or "").strip().lower()
    if raw in BOOL_TRUE:
        return True
    if raw in BOOL_FALSE:
        return False
    return default


def parse_float(value: str) -> float | None:
    raw = (value or "").strip()
    if not raw:
        return None
    try:
        return float(raw)
    except Exception:
        return None


def to_float(value: Any, default: float = 0.0) -> float:
    try:
        return float(value)
    except Exception:
        return default


def parse_int(value: str, default: int = 0) -> int:
    raw = (value or "").strip()
    if not raw:
        return default
    if not re.fullmatch(r"-?\d+", raw):
        return default
    return int(raw)


def parse_json_obj(value: str, fallback: dict[str, Any] | None = None) -> dict[str, Any]:
    fallback = fallback or {}
    raw = (value or "").strip()
    if not raw:
        return dict(fallback)
    try:
        parsed = json.loads(raw)
    except Exception:
        return dict(fallback)
    if not isinstance(parsed, dict):
        return dict(fallback)
    return parsed


def parse_json_list(value: str) -> list[Any]:
    raw = (value or "").strip()
    if not raw:
        return []
    try:
        parsed = json.loads(raw)
    except Exception:
        return []
    if not isinstance(parsed, list):
        return []
    return parsed


def encode_filter(op: str, value: str) -> str:
    return f"{op}.{value}"


@dataclass
class SyncStats:
    catalog_inserted: int = 0
    catalog_updated: int = 0
    catalog_skipped: int = 0
    catalog_protected: int = 0
    alias_inserted: int = 0
    alias_skipped: int = 0
    errors: int = 0


class SupabaseClient:
    def __init__(self, base_url: str, service_key: str, timeout_sec: int = 30):
        self.base_url = base_url.rstrip("/")
        self.headers = {
            "apikey": service_key,
            "Authorization": f"Bearer {service_key}",
            "Content-Type": "application/json",
            "Accept": "application/json",
        }
        self.timeout_sec = timeout_sec

    def _url(self, table: str, params: list[tuple[str, str]] | None = None) -> str:
        if not params:
            return f"{self.base_url}/rest/v1/{table}"
        query = parse.urlencode(params, doseq=True, safe="*(),.-_")
        return f"{self.base_url}/rest/v1/{table}?{query}"

    def _request(
        self,
        method: str,
        table: str,
        params: list[tuple[str, str]] | None = None,
        body: Any | None = None,
        prefer: str | None = None,
    ) -> Any:
        url = self._url(table, params)
        headers = dict(self.headers)
        if prefer:
            headers["Prefer"] = prefer
        data = None
        if body is not None:
            data = json.dumps(body, ensure_ascii=False).encode("utf-8")
        req = request.Request(url, data=data, headers=headers, method=method)
        try:
            with request.urlopen(req, timeout=self.timeout_sec) as resp:
                payload = resp.read().decode("utf-8")
                if not payload:
                    return None
                return json.loads(payload)
        except error.HTTPError as exc:
            detail = exc.read().decode("utf-8", errors="ignore")
            raise RuntimeError(f"{method} {table} failed ({exc.code}): {detail[:360]}") from exc
        except Exception as exc:
            raise RuntimeError(f"{method} {table} failed: {exc}") from exc

    def list(self, table: str, params: list[tuple[str, str]]) -> list[dict[str, Any]]:
        payload = self._request("GET", table, params=params, body=None)
        if payload is None:
            return []
        if isinstance(payload, list):
            return [row for row in payload if isinstance(row, dict)]
        return []

    def insert(self, table: str, row: dict[str, Any]) -> list[dict[str, Any]]:
        payload = self._request(
            "POST",
            table,
            params=None,
            body=row,
            prefer="return=representation",
        )
        if isinstance(payload, list):
            return [r for r in payload if isinstance(r, dict)]
        if isinstance(payload, dict):
            return [payload]
        return []

    def update(self, table: str, row_id: str, row: dict[str, Any]) -> list[dict[str, Any]]:
        payload = self._request(
            "PATCH",
            table,
            params=[("id", encode_filter("eq", row_id))],
            body=row,
            prefer="return=representation",
        )
        if isinstance(payload, list):
            return [r for r in payload if isinstance(r, dict)]
        if isinstance(payload, dict):
            return [payload]
        return []


def read_csv_rows(path: Path) -> list[dict[str, str]]:
    if not path.exists():
        raise RuntimeError(f"CSV not found: {path}")
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        return [{k: (v or "") for k, v in row.items()} for row in reader]


def catalog_payload(row: dict[str, str]) -> dict[str, Any]:
    lang = (row.get("lang") or "").strip() or "zh-TW"
    food_name = (row.get("food_name") or "").strip()
    canonical_name = (row.get("canonical_name") or "").strip()
    calorie_range = (row.get("calorie_range") or "").strip()
    source = (row.get("source") or "").strip() or "manual_seed"
    reference_used = (row.get("reference_used") or "").strip() or "catalog"

    macros = parse_json_obj(
        row.get("macros", ""),
        fallback={"protein": 0, "carbs": 0, "fat": 0, "sodium": 0},
    )
    normalized_macros = {
        "protein": to_float(macros.get("protein", 0), 0.0),
        "carbs": to_float(macros.get("carbs", 0), 0.0),
        "fat": to_float(macros.get("fat", 0), 0.0),
        "sodium": to_float(macros.get("sodium", 0), 0.0),
    }

    payload: dict[str, Any] = {
        "lang": lang,
        "food_name": food_name,
        "canonical_name": canonical_name,
        "calorie_range": calorie_range,
        "macros": normalized_macros,
        "food_items": parse_json_list(row.get("food_items", "")),
        "judgement_tags": parse_json_list(row.get("judgement_tags", "")),
        "dish_summary": (row.get("dish_summary") or "").strip(),
        "suggestion": (row.get("suggestion") or "").strip(),
        "is_beverage": bool(parse_bool(row.get("is_beverage", ""), default=False)),
        "is_food": bool(parse_bool(row.get("is_food", ""), default=True)),
        "is_active": bool(parse_bool(row.get("is_active", ""), default=True)),
        "source": source,
        "verified_level": parse_int(row.get("verified_level", ""), default=0),
        "reference_used": reference_used,
        "image_url": (row.get("image_url") or "").strip() or None,
        "thumb_url": (row.get("thumb_url") or "").strip() or None,
        "image_source": (row.get("image_source") or "").strip() or None,
        "image_license": (row.get("image_license") or "").strip() or None,
        "beverage_profile": parse_json_obj(row.get("beverage_profile", ""), fallback={}),
    }

    beverage_base_ml = parse_float(row.get("beverage_base_ml", ""))
    beverage_full_sugar_carbs = parse_float(row.get("beverage_full_sugar_carbs", ""))
    beverage_default_sugar_ratio = parse_float(row.get("beverage_default_sugar_ratio", ""))
    beverage_sugar_adjustable = parse_bool(row.get("beverage_sugar_adjustable", ""), default=None)

    if beverage_base_ml is not None:
        payload["beverage_base_ml"] = beverage_base_ml
    if beverage_full_sugar_carbs is not None:
        payload["beverage_full_sugar_carbs"] = beverage_full_sugar_carbs
    if beverage_default_sugar_ratio is not None:
        payload["beverage_default_sugar_ratio"] = beverage_default_sugar_ratio
    if beverage_sugar_adjustable is not None:
        payload["beverage_sugar_adjustable"] = beverage_sugar_adjustable

    return payload


def find_catalog_row(client: SupabaseClient, payload: dict[str, Any]) -> tuple[dict[str, Any] | None, str]:
    lang = str(payload.get("lang") or "zh-TW")
    canonical_name = str(payload.get("canonical_name") or "").strip()
    food_name = str(payload.get("food_name") or "").strip()

    if canonical_name:
        rows = client.list(
            "food_catalog",
            [
                ("select", "id,food_name,is_beverage,verified_level"),
                ("lang", encode_filter("eq", lang)),
                ("canonical_name", encode_filter("ilike", canonical_name)),
                ("is_active", encode_filter("eq", "true")),
                ("limit", "2"),
            ],
        )
        if rows:
            return rows[0], "canonical_name"

    rows = client.list(
        "food_catalog",
        [
            ("select", "id,food_name,is_beverage,verified_level"),
            ("lang", encode_filter("eq", lang)),
            ("food_name", encode_filter("ilike", food_name)),
            ("is_active", encode_filter("eq", "true")),
            ("limit", "2"),
        ],
    )
    if rows:
        return rows[0], "food_name"
    return None, ""


def resolve_food_id_by_name(client: SupabaseClient, food_name: str) -> str | None:
    rows = client.list(
        "food_catalog",
        [
            ("select", "id,lang,food_name"),
            ("food_name", encode_filter("ilike", food_name)),
            ("is_active", encode_filter("eq", "true")),
            ("limit", "5"),
        ],
    )
    if not rows:
        return None
    for row in rows:
        if str(row.get("lang") or "") == "zh-TW":
            return str(row.get("id") or "")
    return str(rows[0].get("id") or "")


def parse_alias_row(row: dict[str, str]) -> tuple[str, str, str]:
    food_name = (row.get("food_name") or "").strip()
    lang = (row.get("lang") or "").strip() or "zh-TW"
    alias = (row.get("alias") or "").strip()
    return food_name, lang, alias


def should_protect_beverage_row(existing_row: dict[str, Any], incoming_payload: dict[str, Any]) -> bool:
    existing_is_beverage = existing_row.get("is_beverage") is True
    incoming_is_beverage = incoming_payload.get("is_beverage") is True
    return existing_is_beverage and not incoming_is_beverage


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Upsert catalog and aliases CSV rows into Supabase via REST API."
    )
    parser.add_argument(
        "--catalog",
        required=True,
        help="Catalog CSV path (food_catalog*_draft.csv).",
    )
    parser.add_argument(
        "--alias",
        default="",
        help="Alias CSV path (food_aliases*_draft.csv).",
    )
    parser.add_argument(
        "--base-url-env",
        default="SUPABASE_URL",
        help="Environment variable for Supabase URL.",
    )
    parser.add_argument(
        "--service-key-env",
        default="SUPABASE_SERVICE_ROLE_KEY",
        help="Environment variable for Supabase service role key.",
    )
    parser.add_argument("--dry-run", action="store_true", help="Do not write, only report actions.")
    parser.add_argument(
        "--stop-on-error",
        action="store_true",
        help="Stop immediately on first write error.",
    )
    parser.add_argument("--timeout-sec", type=int, default=30, help="HTTP timeout in seconds.")
    parser.add_argument("--verbose", action="store_true", help="Print per-row actions.")
    parser.add_argument(
        "--allow-beverage-overwrite",
        action="store_true",
        help="Allow overwriting existing beverage rows with non-beverage rows.",
    )
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    supabase_url = os.getenv(args.base_url_env, "").strip()
    if not supabase_url:
        print(f"error: missing env `{args.base_url_env}`", file=sys.stderr)
        return 2

    service_key = os.getenv(args.service_key_env, "").strip()
    if not service_key:
        print(f"error: missing env `{args.service_key_env}`", file=sys.stderr)
        return 2

    catalog_path = Path(args.catalog)
    alias_path = Path(args.alias) if args.alias else None

    try:
        catalog_rows = read_csv_rows(catalog_path)
        alias_rows = read_csv_rows(alias_path) if alias_path else []
    except Exception as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2

    client = SupabaseClient(supabase_url, service_key, timeout_sec=max(5, args.timeout_sec))
    stats = SyncStats()
    food_id_cache: dict[str, str] = {}
    dryrun_new_foods: set[str] = set()

    for idx, row in enumerate(catalog_rows, start=1):
        try:
            payload = catalog_payload(row)
            food_name = str(payload.get("food_name") or "").strip()
            if not food_name:
                raise RuntimeError("empty food_name")
            cache_key = normalize_text(food_name)

            existing_row, matched_by = find_catalog_row(client, payload)
            if existing_row:
                found_id = str(existing_row.get("id") or "").strip()
                if not found_id:
                    raise RuntimeError("matched row missing id")

                if (
                    not args.allow_beverage_overwrite
                    and should_protect_beverage_row(existing_row, payload)
                ):
                    stats.catalog_skipped += 1
                    stats.catalog_protected += 1
                    food_id_cache[cache_key] = found_id
                    existing_name = str(existing_row.get("food_name") or "").strip() or food_name
                    print(
                        f"[catalog:{idx}] protected beverage baseline, skipped overwrite: {existing_name}",
                        file=sys.stderr,
                    )
                    continue

                if args.dry_run:
                    stats.catalog_skipped += 1
                    if args.verbose:
                        print(f"[catalog:{idx}] dry-run update ({matched_by}): {food_name}")
                    food_id_cache[cache_key] = found_id
                    continue
                updated = client.update("food_catalog", found_id, payload)
                stats.catalog_updated += 1
                row_id = str(updated[0].get("id") or found_id) if updated else found_id
                food_id_cache[cache_key] = row_id
                if args.verbose:
                    print(f"[catalog:{idx}] updated ({matched_by}): {food_name}")
            else:
                if args.dry_run:
                    stats.catalog_skipped += 1
                    if args.verbose:
                        print(f"[catalog:{idx}] dry-run insert: {food_name}")
                    # Mark as "would insert" so alias phase can simulate
                    # instead of forcing DB lookup on a row that doesn't
                    # exist yet (dry-run path).
                    dryrun_new_foods.add(cache_key)
                    continue
                inserted = client.insert("food_catalog", payload)
                if not inserted:
                    raise RuntimeError("insert returned empty response")
                row_id = str(inserted[0].get("id") or "").strip()
                if not row_id:
                    raise RuntimeError("insert returned row with empty id")
                food_id_cache[cache_key] = row_id
                stats.catalog_inserted += 1
                if args.verbose:
                    print(f"[catalog:{idx}] inserted: {food_name}")
        except Exception as exc:
            stats.errors += 1
            print(f"[catalog:{idx}] {food_name} failed: {exc}", file=sys.stderr)
            if args.stop_on_error:
                break

    if not args.stop_on_error or stats.errors == 0:
        for idx, row in enumerate(alias_rows, start=1):
            food_name, lang, alias = parse_alias_row(row)
            if not food_name or not alias:
                stats.errors += 1
                print(f"[alias:{idx}] skip invalid row (food_name/alias required)", file=sys.stderr)
                if args.stop_on_error:
                    break
                continue

            food_norm = normalize_text(food_name)
            food_id = food_id_cache.get(food_norm)

            if args.dry_run and food_norm in dryrun_new_foods:
                stats.alias_skipped += 1
                if args.verbose:
                    print(f"[alias:{idx}] dry-run insert (new catalog row): {food_name} / {lang} / {alias}")
                continue

            if not food_id:
                try:
                    food_id = resolve_food_id_by_name(client, food_name)
                except Exception as exc:
                    food_id = None
                    stats.errors += 1
                    print(f"[alias:{idx}] lookup failed for `{food_name}`: {exc}", file=sys.stderr)
                    if args.stop_on_error:
                        break
                if food_id:
                    food_id_cache[food_norm] = food_id

            if not food_id:
                stats.errors += 1
                print(f"[alias:{idx}] food_name not found in catalog: {food_name}", file=sys.stderr)
                if args.stop_on_error:
                    break
                continue

            try:
                exists = client.list(
                    "food_aliases",
                    [
                        ("select", "id"),
                        ("food_id", encode_filter("eq", food_id)),
                        ("lang", encode_filter("eq", lang)),
                        ("alias", encode_filter("ilike", alias)),
                        ("limit", "1"),
                    ],
                )
                if exists:
                    stats.alias_skipped += 1
                    if args.verbose:
                        print(f"[alias:{idx}] exists: {food_name} / {lang} / {alias}")
                    continue

                if args.dry_run:
                    stats.alias_skipped += 1
                    if args.verbose:
                        print(f"[alias:{idx}] dry-run insert: {food_name} / {lang} / {alias}")
                    continue

                client.insert(
                    "food_aliases",
                    {
                        "food_id": food_id,
                        "lang": lang,
                        "alias": alias,
                    },
                )
                stats.alias_inserted += 1
                if args.verbose:
                    print(f"[alias:{idx}] inserted: {food_name} / {lang} / {alias}")
            except Exception as exc:
                stats.errors += 1
                print(f"[alias:{idx}] failed ({food_name} / {alias}): {exc}", file=sys.stderr)
                if args.stop_on_error:
                    break

    print("supabase catalog sync summary")
    print(f"- dry_run:          {bool(args.dry_run)}")
    print(f"- catalog inserted: {stats.catalog_inserted}")
    print(f"- catalog updated:  {stats.catalog_updated}")
    print(f"- catalog skipped:  {stats.catalog_skipped}")
    print(f"- protected rows:   {stats.catalog_protected}")
    print(f"- alias inserted:   {stats.alias_inserted}")
    print(f"- alias skipped:    {stats.alias_skipped}")
    print(f"- errors:           {stats.errors}")

    return 1 if stats.errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
