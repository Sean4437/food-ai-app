#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import json
import os
import sys
from pathlib import Path
from typing import Any
from urllib import error, parse, request

QUEUE_COLUMNS = [
    "query_norm",
    "sample_query",
    "lang",
    "miss_count",
    "last_seen_at",
    "status",
    "note",
]


def normalize_text(value: str) -> str:
    return " ".join((value or "").strip().lower().split())


def load_known_tokens(catalog_paths: list[Path], alias_paths: list[Path]) -> set[str]:
    known: set[str] = set()

    for path in catalog_paths:
        if not path.exists():
            continue
        with path.open("r", encoding="utf-8-sig", newline="") as handle:
            reader = csv.DictReader(handle)
            for row in reader:
                food_name = normalize_text(str(row.get("food_name") or ""))
                canonical_name = normalize_text(str(row.get("canonical_name") or ""))
                if food_name:
                    known.add(food_name)
                if canonical_name:
                    known.add(canonical_name)

    for path in alias_paths:
        if not path.exists():
            continue
        with path.open("r", encoding="utf-8-sig", newline="") as handle:
            reader = csv.DictReader(handle)
            for row in reader:
                alias = normalize_text(str(row.get("alias") or ""))
                if alias:
                    known.add(alias)

    return known


def load_existing_queue(path: Path) -> dict[tuple[str, str], dict[str, str]]:
    rows: dict[tuple[str, str], dict[str, str]] = {}
    if not path.exists():
        return rows

    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        for row in reader:
            query_norm = normalize_text(str(row.get("query_norm") or ""))
            lang = (str(row.get("lang") or "").strip() or "zh-TW")
            if not query_norm:
                continue
            key = (lang, query_norm)
            rows[key] = {
                "query_norm": query_norm,
                "sample_query": str(row.get("sample_query") or "").strip(),
                "lang": lang,
                "miss_count": str(row.get("miss_count") or "0").strip() or "0",
                "last_seen_at": str(row.get("last_seen_at") or "").strip(),
                "status": str(row.get("status") or "todo").strip() or "todo",
                "note": str(row.get("note") or "").strip(),
            }
    return rows


def fetch_miss_top(base_url: str, admin_key: str, days: int, limit: int, lang: str | None) -> list[dict[str, Any]]:
    query_params: list[tuple[str, str]] = [("days", str(days)), ("limit", str(limit))]
    if lang:
        query_params.append(("lang", lang))
    url = f"{base_url.rstrip('/')}/foods/miss_top?{parse.urlencode(query_params)}"

    req = request.Request(
        url,
        headers={
            "X-Admin-Key": admin_key,
            "Accept": "application/json",
        },
        method="GET",
    )
    try:
        with request.urlopen(req, timeout=30) as resp:
            payload = json.loads(resp.read().decode("utf-8"))
    except error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="ignore")
        raise RuntimeError(f"miss_top http {exc.code}: {body[:240]}") from exc
    except Exception as exc:
        raise RuntimeError(f"miss_top request failed: {exc}") from exc

    items = payload.get("items")
    if not isinstance(items, list):
        raise RuntimeError("miss_top payload has no `items` list")
    return [item for item in items if isinstance(item, dict)]


def _to_int(value: Any, default: int = 0) -> int:
    try:
        return int(value)
    except Exception:
        return default


def _existing_or_default(existing: dict[str, str] | None, key: str, default: str) -> str:
    if not existing:
        return default
    value = str(existing.get(key) or "").strip()
    return value if value else default


def build_queue_rows(
    miss_items: list[dict[str, Any]],
    known_tokens: set[str],
    existing_rows: dict[tuple[str, str], dict[str, str]],
    include_known: bool,
    max_new: int,
) -> tuple[list[dict[str, str]], int]:
    new_count = 0

    for item in miss_items:
        lang = (str(item.get("lang") or "").strip() or "zh-TW")
        query_norm = normalize_text(str(item.get("query_norm") or ""))
        sample_query = str(item.get("sample_query") or item.get("query") or "").strip()
        sample_norm = normalize_text(sample_query)
        miss_count = str(_to_int(item.get("miss_count"), 0))
        last_seen_at = str(item.get("last_seen_at") or "").strip()

        if not query_norm:
            continue
        key = (lang, query_norm)
        exists = existing_rows.get(key)
        if exists is None:
            is_known = query_norm in known_tokens or (sample_norm and sample_norm in known_tokens)
            if is_known and not include_known:
                continue
            if max_new > 0 and new_count >= max_new:
                continue
            new_count += 1

        existing_rows[key] = {
            "query_norm": query_norm,
            "sample_query": sample_query or _existing_or_default(exists, "sample_query", query_norm),
            "lang": lang,
            "miss_count": miss_count,
            "last_seen_at": last_seen_at,
            "status": _existing_or_default(exists, "status", "todo"),
            "note": _existing_or_default(exists, "note", ""),
        }

    def sort_key(row: dict[str, str]) -> tuple[int, int, str]:
        status = (row.get("status") or "todo").strip().lower()
        status_order = {
            "todo": 0,
            "in_review": 1,
            "in-progress": 1,
            "done": 2,
            "ignored": 3,
        }.get(status, 9)
        count = _to_int(row.get("miss_count"), 0)
        return (status_order, -count, row.get("query_norm") or "")

    rows = list(existing_rows.values())
    rows.sort(key=sort_key)
    return rows, new_count


def write_queue(path: Path, rows: list[dict[str, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=QUEUE_COLUMNS)
        writer.writeheader()
        for row in rows:
            writer.writerow({col: row.get(col, "") for col in QUEUE_COLUMNS})


def resolve_paths(patterns: list[str]) -> list[Path]:
    output: list[Path] = []
    seen: set[str] = set()
    for pattern in patterns:
        matches = list(Path(".").glob(pattern))
        if not matches and Path(pattern).exists():
            matches = [Path(pattern)]
        for path in matches:
            key = str(path.resolve())
            if key in seen:
                continue
            seen.add(key)
            output.append(path)
    output.sort(key=lambda p: str(p))
    return output


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Build a catalog discovery queue from backend /foods/miss_top telemetry."
    )
    parser.add_argument(
        "--base-url",
        default=os.getenv("CATALOG_BACKEND_BASE_URL", "").strip(),
        help="Backend base URL (or env CATALOG_BACKEND_BASE_URL).",
    )
    parser.add_argument(
        "--admin-key-env",
        default="CATALOG_ADMIN_API_KEY",
        help="Environment variable name for backend admin key.",
    )
    parser.add_argument("--days", type=int, default=30, help="Lookback window for miss_top.")
    parser.add_argument("--limit", type=int, default=300, help="Max miss_top rows to fetch.")
    parser.add_argument("--lang", default="zh-TW", help="Language filter for miss_top.")
    parser.add_argument(
        "--out",
        default="backend/sql/food_discovery_queue.csv",
        help="Output CSV path.",
    )
    parser.add_argument(
        "--catalog-glob",
        action="append",
        default=[],
        help="Glob/path for catalog draft CSV (repeatable).",
    )
    parser.add_argument(
        "--alias-glob",
        action="append",
        default=[],
        help="Glob/path for alias draft CSV (repeatable).",
    )
    parser.add_argument("--include-known", action="store_true", help="Keep rows already covered by current catalog/alias.")
    parser.add_argument("--max-new", type=int, default=200, help="Maximum number of newly added queue rows (0 = unlimited).")
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    base_url = (args.base_url or "").strip()
    if not base_url:
        print("error: missing --base-url (or env CATALOG_BACKEND_BASE_URL)", file=sys.stderr)
        return 2

    admin_key = os.getenv(args.admin_key_env, "").strip()
    if not admin_key:
        print(f"error: missing admin key env `{args.admin_key_env}`", file=sys.stderr)
        return 2

    catalog_patterns = args.catalog_glob or ["backend/sql/food_catalog*_draft.csv"]
    alias_patterns = args.alias_glob or ["backend/sql/food_aliases*_draft.csv"]
    catalog_paths = resolve_paths(catalog_patterns)
    alias_paths = resolve_paths(alias_patterns)
    known_tokens = load_known_tokens(catalog_paths, alias_paths)

    out_path = Path(args.out)
    existing_rows = load_existing_queue(out_path)
    before_count = len(existing_rows)

    try:
        items = fetch_miss_top(base_url, admin_key, args.days, args.limit, args.lang)
    except Exception as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2

    rows, new_count = build_queue_rows(
        miss_items=items,
        known_tokens=known_tokens,
        existing_rows=existing_rows,
        include_known=bool(args.include_known),
        max_new=max(0, int(args.max_new)),
    )
    write_queue(out_path, rows)

    print("catalog discovery queue refreshed")
    print(f"- fetched miss rows: {len(items)}")
    print(f"- known tokens: {len(known_tokens)}")
    print(f"- queue before: {before_count}")
    print(f"- queue after:  {len(rows)}")
    print(f"- new rows:     {new_count}")
    print(f"- output:       {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
