# Screen Contracts (Regression Guard)

Last updated: 2026-02-20

## How to use this file
- Purpose: prevent repeated regressions when context is split across threads.
- Rule: before editing a screen, check "Must keep" and "Quick checks".
- Goal: avoid feature loss from accidental full-file overwrite.

## 0) Global Navigation Contract
Path: `frontend/lib/main.dart`

Must keep:
- Tab navigation works for Suggestions, Home, Log, Custom, Settings, Chat.
- Auth gate works (signed-out user goes to login).
- Trial/access gate still blocks restricted features when needed.

Quick checks:
1. Login and tap all tabs.
2. Logout/login again and verify tab routing still works.

## 1) Settings Screen Contract (highest priority)
Path: `frontend/lib/screens/settings_screen.dart`

Must keep:
- Sync controls and status.
- Subscription status display (trial/mock/iap/whitelist/access plan).
- Plan settings (goal, speed, activity profile related settings).
- Container settings (type, size, depth, diameter, capacity).
- Diet preference (`dietType`, `dietNote`).
- Suggestion style (`tone`, `persona`).
- Summary settings (daily/weekly summary schedule).
- Meal time windows.
- Reminder settings.
- Language switch.
- Theme/layout settings (theme, text scale, plate, chart style).
- Chat settings (assistant name, avatar pick/remove).
- Version and data management section.

Must not reintroduce:
- User-editable production API base URL field.

Quick checks:
1. All sections render and are actionable.
2. Save, restart app, verify persistence.
3. Web and iOS both open Settings without crashes.

## 2) Suggestions Screen Contract
Path: `frontend/lib/screens/suggestions_screen.dart`

Must keep:
- Camera/gallery analyze flow.
- Name-input flow with catalog suggestions.
- Fallback behavior and error hints for miss/unavailable states.
- Saved result appears in log.

Quick checks:
1. Name input returns suggestions for existing catalog prefixes.
2. Submit by name and verify entry in log.

## 3) Log Screen Contract
Path: `frontend/lib/screens/log_screen.dart`

Must keep:
- Date switching and day grouping.
- Existing data must render (no blank full page).
- Quick add (`+`) flow works.
- Tap entry opens detail screen.

Quick checks:
1. Logout/login with existing data and verify list renders.
2. Add one new entry and verify immediate visibility.

## 4) Meal Detail Screen Contract
Path: `frontend/lib/screens/meal_items_screen.dart`

Must keep:
- Edit food name.
- Edit portion percent.
- Reanalyze.
- Delete entry.
- Edit entry time (date + time).
- Add/remove nutrition label image.
- Source badge rendering (catalog / ai / custom / label / beverage formula).

Quick checks:
1. Tap time button and change date/time.
2. Verify updated entry still appears in correct date/meal group.

## 5) Home Screen Contract
Path: `frontend/lib/screens/home_screen.dart`

Must keep:
- Home cards render.
- AppBar overflow "Settings" routes to Settings tab.
- Test-only actions do not break normal navigation.

Quick checks:
1. Overflow -> Settings should switch tab correctly.

## 6) Login and Reset Password Contract
Paths:
- `frontend/lib/screens/login_screen.dart`
- `frontend/lib/screens/reset_password_screen.dart`
- `frontend/lib/services/supabase_service.dart`

Must keep:
- Error display strategy for login/reset flows.
- Reset password error code mapping:
`network`, `rate_limited`, `link_expired`, `email_not_found`, `weak_password`, `unknown`.
- Recovery flow compatibility on web.

Quick checks:
1. Invalid email format gets actionable feedback.
2. Recovery link can reach reset screen and update password.

## 7) Chat Screen Contract
Path: `frontend/lib/screens/chat_screen.dart`

Must keep:
- Multi-turn chat.
- Assistant name/avatar from settings.
- Quick prompt chips.
- Error mapping for auth/quota/network/server.

Quick checks:
1. Change assistant name/avatar in settings and verify chat reflects it.
2. Clear chat and verify state resets.

## 8) Backend Contract (UI dependent)
Path: `backend/app.py`

Must keep:
- `/foods/search` returns catalog candidates.
- `/analyze` and `/analyze_name` return stable schema.
- `/access_status` returns entitlements/access plan.
- `/health` remains admin protected.

Quick checks:
1. `/health` with admin key returns 200.
2. `/foods/search?q=<known item>&limit=5` returns `items`.

## 9) Known Frequent Regressions
- Settings sections lost after overwrite.
- Log page blank while data still exists.
- Name-input route bypassing public catalog.
- Missing time-edit action in meal detail toolbar.
- L10n key added without regenerated files, causing web build failure.
