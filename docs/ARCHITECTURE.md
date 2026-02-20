# Food AI App Architecture

Last updated: 2026-02-20

## 1) Scope
- Product: food analysis and meal logging app.
- Primary platform: iOS app.
- Secondary platform: Web (test and QA use).
- Frontend: Flutter.
- Backend: FastAPI on Railway.
- Data/Auth: Supabase.

## 2) Main Components
| Layer | Component | Path |
|---|---|---|
| App shell | Auth gate + tab navigation | `frontend/lib/main.dart` |
| Global state | Single source of truth | `frontend/lib/state/app_state.dart` |
| API client | HTTP requests to backend | `frontend/lib/services/api_service.dart` |
| Auth/sync | Supabase auth and sync | `frontend/lib/services/supabase_service.dart` |
| Local storage | Entries/settings persistence | `frontend/lib/storage/*` |
| Backend API | Endpoints + AI prompts | `backend/app.py` |

## 3) Frontend Architecture
### 3.1 State model
- `AppState` owns auth, access status, analyze flows, logs, sync, chat, and settings.
- UI screens should call `AppState`, not backend endpoints directly.

### 3.2 Core flows
1. Photo analyze flow:
`record_sheet.dart` -> `AppState.addEntry/addEntryFromFiles` -> `ApiService.analyzeImage` -> `_resolveNutritionResult` -> local store -> sync.
2. Name input flow:
`record_sheet.dart` -> `AppState.analyzeNameAndSave` -> `/foods/search` -> miss reporting/fallback logic.
3. Custom food flow:
custom food -> `MealEntry` conversion -> log pipeline.
4. Access gate flow:
`access_status` decides entitlements (`ai_analyze`, `ai_chat`, `ai_summary`, `ai_suggest`).

### 3.3 UI structure
- Tab index is managed by `TabScope`.
- Main tabs: Suggestions, Home, Log, Custom, Settings, Chat.
- `settings_screen.dart` and `app_state.dart` are high-risk files for regression.

## 4) Backend Architecture
### 4.1 Key endpoint groups
- Analyze: `/analyze`, `/analyze_name`, `/analyze_label`
- Summary/advice: `/summarize_day`, `/summarize_week`, `/suggest_meal`
- Chat: `/chat`
- Access: `/access_status`
- Catalog: `/foods/search`, `/foods/search_miss`
- Admin/ops: `/health`, `/usage`, `/usage/summary`

### 4.2 Security and quotas
- Supabase JWT validation for user endpoints.
- `ADMIN_API_KEY` required for admin endpoints.
- Analyze/chat rate limits from env vars.
- AI availability controlled by `CALL_REAL_AI`, `FREE_DAILY_LIMIT`, and entitlements.

## 5) Deployment and Environment
- Production backend base URL:
`https://food-ai-app-production.up.railway.app`
- Frontend should use fixed base URL for production behavior.
- Railway variables must include:
`SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `ADMIN_API_KEY`, `API_KEY`, `OPENAI_MODEL`, `CALL_REAL_AI`, `ALLOWED_ORIGINS`, and rate-limit vars.

## 6) High-Risk Files (read before edits)
- `frontend/lib/state/app_state.dart`
- `frontend/lib/screens/settings_screen.dart`
- `frontend/lib/screens/log_screen.dart`
- `frontend/lib/screens/suggestions_screen.dart`
- `frontend/lib/screens/meal_items_screen.dart`
- `backend/app.py`

## 7) Required Change Workflow
1. Before implementation, read:
`docs/ARCHITECTURE.md`, `docs/SCREEN_CONTRACTS.md`, `docs/CHANGELOG_DEV.md`.
2. Compare planned changes with screen contracts.
3. Run minimal smoke tests for affected flows.
4. After commit, append a short entry to `docs/CHANGELOG_DEV.md`.
