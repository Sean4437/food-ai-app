# Catalog 自動化流程（GitHub Actions + Supabase）

最後更新：2026-02-25
適用專案：`food-ai-app`

## 1. 目的
- 把「使用者常搜但 catalog 沒命中」的項目，轉成可驗證、可部署的 catalog/alias 草稿 CSV。
- 透過 GitHub Actions 先驗證再部署，避免直接寫入 Supabase 造成污染。
- 對飲料資料保留保護機制，避免 baseline 被非飲料資料覆蓋。

## 2. 主要檔案
- Workflow
- `.github/workflows/catalog_discover.yml`
- `.github/workflows/catalog_validate.yml`
- `.github/workflows/catalog_deploy.yml`
- 工具腳本
- `tools/catalog_discover_from_miss.py`
- `tools/catalog_validate_bundle.py`
- `tools/catalog_upsert_supabase.py`
- CSV 草稿（目前常用）
- `backend/sql/food_catalog_priority2_batch1_import_draft.csv`
- `backend/sql/food_aliases_priority2_batch1_import_draft.csv`
- `backend/sql/food_catalog_priority2_batch2_import_draft.csv`
- `backend/sql/food_aliases_priority2_batch2_import_draft.csv`
- `backend/sql/food_catalog_priority2_batch3_import_draft.csv`
- `backend/sql/food_aliases_priority2_batch3_import_draft.csv`

## 3. GitHub Secrets（Repository > Settings > Secrets and variables > Actions）
- `CATALOG_BACKEND_BASE_URL`
  - 目前正式值：`https://food-ai-app-production.up.railway.app`
- `CATALOG_ADMIN_API_KEY`
  - 對應 Railway 的 `ADMIN_API_KEY`
- `SUPABASE_URL`
  - 例如 `https://<project-ref>.supabase.co`
- `SUPABASE_SERVICE_ROLE_KEY`
  - `sb_secret_...`（不可用 publishable key 取代）

## 4. 三條 workflow 實際用途

### 4.1 `catalog_discover.yml`
- 來源：後端 `/foods/miss_top`（需 `X-Admin-Key`）。
- 產物：更新 `backend/sql/food_discovery_queue.csv`。
- 用途：只做候選收集，不直接部署到 Supabase。

### 4.2 `catalog_validate.yml`
- 在 PR 或手動觸發時，驗證 catalog/alias CSV 與相關工具腳本。
- 目前 workflow 內預設驗證 `priority1` 與 `priority2` 主檔。
- 會檢查：
- 欄位完整性
- JSON 欄位格式
- 布林/整數欄位
- 熱量字串格式（`###-### kcal`）
- food_name/canonical_name 重複
- alias tuple 重複
- alias 指向不存在 food_name

### 4.3 `catalog_deploy.yml`
- 手動觸發，支援 bundle 選擇與 CSV override。
- 目前內建 bundle：`priority1`、`priority2`、`priority2_batch1`、`priority2_batch2`、`priority2_batch3`。
- 在部署前會先呼叫：
- `tools/catalog_validate_bundle.py --catalog-file ... --alias-file ...`
- 驗證通過後，呼叫 `tools/catalog_upsert_supabase.py`。
- 可選 `dry_run`、`stop_on_error`。

## 5. 固定部署流程（務必照順序）
1. 開 `Catalog Deploy to Supabase`。
2. 使用同一組 CSV 路徑先跑一次 `dry_run=true`（Run without writing）。
3. 確認綠燈後，再跑一次相同路徑 `dry_run=false`（正式寫入）。
4. `stop_on_error` 保持 `true`。

## 6. 關鍵防呆與歷史修正
- 飲料保護：`catalog_upsert_supabase.py` 預設會保護既有 `is_beverage=true` 資料，不允許被 `is_beverage=false` 覆蓋。
- 若確定要覆蓋，才可明確加 `--allow-beverage-overwrite`。
- 2026-02-24 重要修正（commit: `f520ba9`）：
- 問題：deploy workflow 只想驗指定 CSV，卻因 validator 掃到所有 `*_draft.csv`，造成 668 duplicate 誤炸。
- 修正：當有 `--catalog-file/--alias-file` 時，`catalog_validate_bundle.py` 不再自動套用 wildcard。
- 結果：deploy 可只驗當次指定 pair。

## 7. 本機檢查指令（建議）
```bash
python tools/catalog_validate_bundle.py \
  --catalog-file backend/sql/food_catalog_priority2_batch1_import_draft.csv \
  --alias-file backend/sql/food_aliases_priority2_batch1_import_draft.csv \
  --allow-ambiguous-alias
```

```bash
python tools/catalog_upsert_supabase.py \
  --catalog backend/sql/food_catalog_priority2_batch1_import_draft.csv \
  --alias backend/sql/food_aliases_priority2_batch1_import_draft.csv \
  --dry-run \
  --stop-on-error
```

## 8. 一鍵控制公用資料庫（建議入口）
新增腳本：`tools/catalog_control.ps1`

### 8.1 先做本機驗證（不寫入）
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/catalog_control.ps1 `
  -Action validate `
  -Bundle priority2_batch2
```

### 8.2 送出 GitHub dry-run（寫入前必做）
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/catalog_control.ps1 `
  -Action dry-run `
  -Bundle priority2_batch2
```

### 8.3 dry-run 綠燈後，正式寫入
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/catalog_control.ps1 `
  -Action deploy `
  -Bundle priority2_batch2
```
- 腳本會要求輸入 `DEPLOY` 以避免誤寫入。
- 預設會持續 watch workflow，直到成功或失敗。

### 8.4 看最近部署狀態
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/catalog_control.ps1 `
  -Action status `
  -StatusCount 5
```

### 8.5 參數說明（常用）
- `-Bundle`：`priority1` / `priority2` / `priority2_batch1` / `priority2_batch2` / `priority2_batch3`
- `-CatalogCsv`、`-AliasCsv`：可覆蓋 bundle 預設路徑（檔名或完整相對路徑）
- `-StopOnError`：預設 `true`
- `-Repo`：預設自動從 `origin` 解析；也可手動指定 `owner/repo`
- `-NoWatch`：只送 dispatch，不等待 workflow 完成

## 9. 實務規範
- 新 batch 一律先避免與既有 batch（至少 `priority2_batch1`）重複。
- alias 歧義預設是錯誤；CI/Deploy 如需放行要明確使用 `--allow-ambiguous-alias`。
- 文字檔統一 UTF-8，避免亂碼再污染流程文件。
