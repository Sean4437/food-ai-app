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

# 2) 查熱門 miss（管理用）
curl -H "X-Admin-Key: <ADMIN_API_KEY>" "http://127.0.0.1:8000/foods/miss_top?days=30&limit=20"
```

## Auth / 試用設定

- 需要 Supabase JWT（前端登入後帶 Authorization: Bearer <token>）
- 必要環境變數：
  - SUPABASE_URL
  - SUPABASE_SERVICE_ROLE_KEY
  - TEST_BYPASS_EMAILS（逗號分隔測試帳號白名單）
  - TRIAL_DAYS（預設 2）
