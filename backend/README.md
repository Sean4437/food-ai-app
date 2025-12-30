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
