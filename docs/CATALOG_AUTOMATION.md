# Catalog 自動化流程（GitHub Actions + Supabase）

## 目標
- 自動收集使用者查不到的食物關鍵字（miss queue）。
- 針對 catalog CSV 做一致性檢查。
- 一鍵把指定 CSV 匯入 Supabase（可先 dry-run）。

## 新增的工作流
- `.github/workflows/catalog_discover.yml`
  - 來源：後端 `/foods/miss_top`（需要 `X-Admin-Key`）。
  - 輸出：`backend/sql/food_discovery_queue.csv`
  - 觸發：每日排程 + 手動。
  - 變更時會自動開 PR。

- `.github/workflows/catalog_validate.yml`
  - 驗證 `food_catalog*_draft.csv` + `food_aliases*_draft.csv`
  - 觸發：PR（有改 SQL CSV/工具腳本）+ 手動。

- `.github/workflows/catalog_deploy.yml`
  - 手動選擇 catalog/alias CSV 後，執行匯入 Supabase。
  - 支援 `dry_run=true` 先檢查不寫入。

## 新增工具腳本
- `tools/catalog_discover_from_miss.py`
  - 抓 miss_top 並更新 queue CSV。
  - 會自動排除目前 catalog/alias 已存在的詞。

- `tools/catalog_validate_bundle.py`
  - 驗證欄位、JSON、布林值、重複、alias 歧義。

- `tools/catalog_upsert_supabase.py`
  - 讀取 catalog/alias CSV，透過 Supabase REST upsert。
  - 可 `--dry-run` / `--stop-on-error`。

## GitHub Secrets（Repository -> Settings -> Secrets and variables -> Actions）
必填：
- `CATALOG_BACKEND_BASE_URL`
  - 例如：`https://food-ai-app-production.up.railway.app`
- `CATALOG_ADMIN_API_KEY`
  - Railway 的 `ADMIN_API_KEY`
- `SUPABASE_URL`
  - 例如：`https://<project-ref>.supabase.co`
- `SUPABASE_SERVICE_ROLE_KEY`
  - `sb_secret_...`（不是 publishable key）

## 推薦操作順序（正式）
1. 跑 `Catalog Discover Queue`（手動）。
2. 在 PR 內整理 `backend/sql/food_discovery_queue.csv`。
3. 依 queue 補到 `food_catalog*_draft.csv` / `food_aliases*_draft.csv`。
4. `Catalog Validate` 通過後合併。
5. 先跑 `Catalog Deploy to Supabase`，`dry_run=true`。
6. 再跑一次 `dry_run=false` 正式寫入。

## 注意
- 這套流程預設是「以真實 miss 查詢驅動擴充」，不是直接爬網全自動寫庫。
- 若要加「自動網路蒐集來源」可再加一層 generator，但建議仍保留 PR 人工審核，避免髒資料進庫。
