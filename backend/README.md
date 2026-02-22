# 後端（FastAPI）

## 執行

```bash
python -m venv .venv
. .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -r requirements.txt
uvicorn app:app --reload --host 0.0.0.0 --port 8000
```

## API

- POST /analyze
  - multipart/form-data 欄位：`image`
  - 可選 query：`lang`（例如 zh-TW, en）
  - 回傳分析 JSON

- GET /foods/search
  - 參數：`q`, `lang?`, `limit?`
  - 用途：公開資料庫搜尋（alias + food_name + canonical_name）
  - 飲料加值：若 `q` 含「半糖/少冰/大杯/珍珠」等字樣，且命中 `is_beverage=true` 的 catalog，會套用飲料參數公式回傳調整後營養
  - 回傳：`items[]`（含 calorie/macros/source/image 等）

- POST /foods/search_miss
  - body：`query`, `lang?`, `source?`
  - 用途：記錄「找不到的食物名稱」做資料庫擴充依據

- GET /foods/miss_top
  - 參數：`days?`, `limit?`, `lang?`
  - 權限：需要 `X-Admin-Key`
  - 用途：查看熱門 miss 關鍵字，優先補資料庫

## 常用檢查

```bash
# 1) 搜尋公開資料庫
curl "http://127.0.0.1:8000/foods/search?q=牛肉麵&limit=5"

# 1-1) 飲料參數搜尋（會套用糖/冰/杯量/加料）
curl "http://127.0.0.1:8000/foods/search?q=青茶半糖去冰加珍珠&limit=5"

# 2) 查熱門 miss（管理用）
curl -H "X-Admin-Key: <ADMIN_API_KEY>" "http://127.0.0.1:8000/foods/miss_top?days=30&limit=20"
```

## Supabase SQL 建議執行順序

在 Supabase SQL Editor 依序執行：

1. `backend/sql/db_baseline.sql`
2. `backend/sql/food_catalog_schema.sql`
3. `backend/sql/food_catalog_public_expansion.sql`
4. `backend/sql/food_catalog_hardening.sql`
5. `backend/sql/food_catalog_canonical_hardening.sql`
6. `backend/sql/beverage_catalog_minimum_seed.sql`

說明：
- 第 1 步建立 App 同步核心表（`meals/custom_foods/user_settings/sync_meta/profiles`）與 storage policy。
- 第 5 步會統一 `canonical_name` 規則，並自動處理重複值避免唯一索引衝突。

## Auth / 試用設定

- 需要 Supabase JWT（前端登入後帶 Authorization: Bearer <token>）
- 必要環境變數：
  - SUPABASE_URL
  - SUPABASE_SERVICE_ROLE_KEY
  - TEST_BYPASS_EMAILS（逗號分隔測試帳號白名單）
  - TRIAL_DAYS（預設 2）
