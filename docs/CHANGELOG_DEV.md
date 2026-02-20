# Dev Changelog

Last updated: 2026-02-20

## Changelog format
For each commit entry, keep:
- Date
- Commit
- Main files changed
- Risk / regression notes
- Minimal verification result

## 2026-02-20
### Commit `deb1b30`
- Summary:
  - Added piece-food guard for dumpling-like foods to prevent AI overestimation.
  - Applied same guard to quick-capture preview path.
  - Fixed `_resolveNutritionResult` pass-through for fields like
    `is_food`, `reference_used`, `container_guess_type`, `container_guess_size`.
  - Added unit-food rule text to backend prompts.
- Files:
  - `frontend/lib/state/app_state.dart`
  - `backend/app.py`
- Risk:
  - Guard currently applies only to mapped piece-food categories.
- Verify:
  - `flutter build web --release --base-href /food-ai-app/` passed.
  - `python -m py_compile backend/app.py` passed.

### Commit `41849b1`
- Summary:
  - Restored missing time-edit UI action on meal detail screen.
- Files:
  - `frontend/lib/screens/meal_items_screen.dart`
- Risk:
  - Toolbar button density on narrow screens.
- Verify:
  - `flutter build web --release --base-href /food-ai-app/` passed.
  - Manual check: can change entry date/time from meal detail.

### Commit `5d9ff82`
- Summary:
  - Added new-thread startup template to reduce long-thread slowdown and handoff loss.
- Files:
  - `docs/THREAD_START_TEMPLATE.md`
- Risk:
  - No runtime impact.
- Verify:
  - Template file exists and can be copied into a new thread.

## 2026-02-06
- Web test paywall parity + current plan display.
- Added mock plan persistence + access grace hours setting.
- Added localized strings for web test + access failure.
- Added `ios_run.sh` + README entry.
- Fixed l10n template mismatch (`app_zh_TW.arb`).
