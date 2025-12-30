# 食物 AI MVP

這是「拍照記錄飲食、給出溫和建議」的最小可運行專案。
前端使用 Flutter，後端使用 FastAPI，分析內容為假資料。

## 結構

- backend：FastAPI API
- frontend：Flutter App

## 多國語系

- Flutter 使用官方 gen-l10n（ARB）管理文案
- 目前內建 zh-TW、en
- 後端 /analyze 支援 `lang` 參數，前端會自動帶入目前系統語系

## 啟動後端

```bash
cd backend
python -m venv .venv
. .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -r requirements.txt
uvicorn app:app --reload --host 0.0.0.0 --port 8000
```

## 啟動前端

```bash
cd frontend
flutter pub get
flutter run
```

## 備註

- 後端回傳假分析結果，尚未接真 AI。
- 免費/付費邏輯為佔位（見 backend/app.py）。
- Flutter API 位置預設 Android 模擬器：10.0.2.2
