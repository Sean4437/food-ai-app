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
  - 回傳假分析 JSON

## Auth / 試用設定

- 需要 Supabase JWT（前端登入後帶 Authorization: Bearer <token>）
- 必要環境變數：
  - SUPABASE_URL
  - SUPABASE_SERVICE_ROLE_KEY
  - TEST_BYPASS_EMAILS（逗號分隔測試帳號白名單）
  - TRIAL_DAYS（預設 2）
