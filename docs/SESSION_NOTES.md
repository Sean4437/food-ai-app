# Session Notes（food-ai-app）

最後更新：2026-02-25
用途：長期維護記憶（本機為主）。

## 維護規則（本串）
- 每次完成「可部署改動」都要補一筆：問題 / 根因 / 修正 / 驗證 / commit / date。
- 流程或架構有改，需同步更新 `docs/HANDOFF.md`。
- 文件統一 UTF-8，避免亂碼污染。
- 未被明確要求時，不提交與任務無關的 `docs/*`、`tools/*`。

## 記錄模板
- 問題：
- 根因：
- 修正：
- 驗證：
- commit：
- date：

## 近期關鍵紀錄

### 1) Catalog deploy 誤炸 668 duplicates
- 問題：Deploy workflow 明明只選一組 CSV，validator 卻掃到所有 `*_draft.csv`，出現大量 duplicate 錯誤。
- 根因：`tools/catalog_validate_bundle.py` 在有 `--catalog-file/--alias-file` 時仍會套用 wildcard。
- 修正：明確檔案參數存在時，不再自動加預設 glob。
- 驗證：Deploy workflow 使用指定 CSV pair 可正常只驗當次檔案。
- commit：`f520ba9`
- date：2026-02-24

### 2) Catalog 自動化文件亂碼
- 問題：`docs/CATALOG_AUTOMATION.md` 出現編碼亂碼，交接不可讀。
- 根因：歷史編碼混用（非 UTF-8）造成文字污染。
- 修正：整份重寫為 UTF-8，內容對齊現行 workflow 與工具腳本。
- 驗證：本機重新開檔顯示正常；流程與檔名可對應到現有 repo。
- commit：pending
- date：2026-02-24

### 3) Auth 與忘記密碼錯誤分類
- 問題：跨裝置流程下，PKCE code verifier 容易失效；忘記密碼錯誤回饋不一致。
- 根因：Web auth flow 與錯誤映射未針對真實場景分流。
- 修正：Web 改 implicit flow；忘記密碼錯誤碼統一為 `network/rate_limited/link_expired/email_not_found/weak_password/unknown`。
- 驗證：跨裝置重設流程可穩定完成；UI 可依錯誤碼顯示對應文案。
- commit：未記錄（歷史）
- date：2026-02（歷史）

### 4) 後端部署主軸轉 Railway
- 問題：團隊曾以本機 `uvicorn` 為主要心智模型，與正式環境不一致。
- 根因：交接文件未反映部署重心轉移。
- 修正：正式 API base 明確定為 `https://food-ai-app-production.up.railway.app`；補充 `/health` 需 admin key。
- 驗證：未帶 key 時 `/health` 回 `admin_required`；帶 key 可用。
- commit：未記錄（歷史）
- date：2026-02（歷史）

### 5) 試用與訂閱模擬策略
- 問題：開發測試時難以驗證 free/plus/pro 權限與試用邏輯。
- 根因：缺少可配置 plan 與白名單變數。
- 修正：加入 `TRIAL_DAYS=2`、`TEST_BYPASS_EMAILS`、`PLAN_*` entitlement 與 email 白名單變數。
- 驗證：可在 web 模擬不同方案；新用戶前 2 天享完整功能。
- commit：未記錄（歷史）
- date：2026-02（歷史）

### 6) 設定頁與導覽污染修正
- 問題：API Base URL 可被一般使用者改動，造成同步與環境污染；首頁 overflow 導覽易疊層。
- 根因：設定頁責任過多，導覽入口分散。
- 修正：API Base URL 不再給一般使用者直接編輯；首頁 overflow 改 tab 切換。
- 驗證：不再發生多層頁導覽錯亂；測試帳號不會誤改全域 API 設定。
- commit：未記錄（歷史）
- date：2026-02（歷史）

### 7) 紀錄頁顯示穩定性
- 問題：曾出現紀錄頁空白與點 A 顯示 B 的錯位。
- 根因：列表渲染與資料映射邏輯有同步落差。
- 修正：調整頁面資料綁定與列表識別流程；明細頁補來源標記（資料庫/AI估算/自訂）。
- 驗證：頁面不再整頁空白；項目對應正確。
- commit：未記錄（歷史）
- date：2026-02（歷史）

### 8) Catalog 飲料保護與常見陷阱
- 問題：飲料 baseline 曾有被非飲料資料覆蓋風險；alias 也常出現歧義。
- 根因：批次 upsert 未限制覆蓋方向，且 alias 有多對一命名碰撞。
- 修正：`catalog_upsert_supabase.py` 預設保護 `is_beverage=true` 既有列；必要時才用 `--allow-beverage-overwrite`。
- 驗證：dry-run 報表可見 protected row 計數；部署時可避免錯誤覆蓋。
- commit：未記錄（歷史）
- date：2026-02（歷史）

### 9) Priority2 Batch2 草稿建立（避免與 Batch1 重複）
- 問題：需開始下一批 catalog 擴充，但不能與 `priority2_batch1` 重複。
- 根因：`priority2` 主檔同時包含 batch1 與待擴充項目，直接使用會導致重複風險。
- 修正：由 `priority2_import` 扣除 `priority2_batch1` 差集，產生：
- `backend/sql/food_catalog_priority2_batch2_import_draft.csv`（108 筆）
- `backend/sql/food_aliases_priority2_batch2_import_draft.csv`（273 筆）
- 驗證：
- `python tools/catalog_validate_bundle.py --catalog-file backend/sql/food_catalog_priority2_batch2_import_draft.csv --alias-file backend/sql/food_aliases_priority2_batch2_import_draft.csv --allow-ambiguous-alias`
- 結果：`errors=0`、`warnings=9`（皆 alias 歧義警告）
- 交叉檢查：batch1 與 batch2 的 catalog/alias key overlap 皆為 0
- commit：`9c53e36`
- date：2026-02-24

### 10) 公用資料庫一鍵控制腳本
- 問題：目前控制公用資料庫需手動進 GitHub UI，步驟多且易漏掉 dry-run。
- 根因：缺少單一入口工具整合 validate / dispatch / status。
- 修正：新增 `tools/catalog_control.ps1`，支援：
- `validate`（本機檔案驗證）
- `dry-run`（觸發 `catalog_deploy.yml`，`dry_run=true`）
- `deploy`（正式寫入，需輸入 `DEPLOY`）
- `status`（查最近 workflow run）
- 驗證：
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/catalog_control.ps1 -Action validate -Bundle priority2_batch2`（通過）
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/catalog_control.ps1 -Action status -StatusCount 1`（成功抓取 run）
- commit：pending
- date：2026-02-24

### 11) Dry-run dispatch 403（PAT 權限不足）
- 問題：使用 `catalog_control.ps1 -Action dry-run` 觸發 workflow 時回 403。
- 根因：目前本機 PAT 缺少觸發 workflow 所需權限（`Resource not accessible by personal access token`）。
- 修正：
- 建立/更新 PAT 權限需求：
- Fine-grained token：Repository `food-ai-app`，`Actions: Read and write`、`Contents: Read`
- 或 Classic PAT：至少 `repo` + `workflow`
- `tools/catalog_control.ps1` 已補強 GitHub API 失敗訊息格式，便於排錯。
- 驗證：
- `status` 可讀取最近 runs（token 讀取權限存在）
- `dry-run` 仍因寫入權限不足而被拒（403）
- commit：pending
- date：2026-02-24

### 12) 啟用 batch2 workflow 並完成 dry-run
- 問題：`priority2_batch2` 在 GitHub workflow 中不可選，dispatch 會回 422。
- 根因：遠端 `catalog_deploy.yml` 尚未包含 `priority2_batch2` bundle（本機有改但尚未 push）。
- 修正：push `catalog_deploy.yml` + batch2 CSV 到 `main`，commit `9c53e36`。
- 驗證：
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/catalog_control.ps1 -Action dry-run -Bundle priority2_batch2`
- 結果：run `22348682787`，conclusion=`success`
- commit：`9c53e36`
- date：2026-02-24

### 13) 新增 Priority2 Batch3 食物擴充
- 問題：使用者要求再新增一批食物，但既有 `food_names_batch_300` 已全部入庫，無法再由既有清單直接切差集。
- 根因：目前候選檔案僅覆蓋既有 300 筆 catalog，缺少新的未覆蓋候選來源。
- 修正：
- 新增 `backend/sql/food_catalog_priority2_batch3_import_draft.csv`（96 筆）
- 新增 `backend/sql/food_aliases_priority2_batch3_import_draft.csv`（96 筆，先用全名 alias）
- 更新 `catalog_deploy.yml`、`catalog_control.ps1`，支援 `priority2_batch3` bundle
- 驗證：
- `python tools/catalog_validate_bundle.py --catalog-file backend/sql/food_catalog_priority2_batch3_import_draft.csv --alias-file backend/sql/food_aliases_priority2_batch3_import_draft.csv --allow-ambiguous-alias`
- 結果：`errors=0`、`warnings=0`
- commit：`8657d78`
- date：2026-02-24

### 14) 修正 batch3 dry-run 在 alias 階段誤失敗
- 問題：`priority2_batch3` dry-run 在 `Upsert to Supabase` 失敗，訊息為 `food_name not found in catalog`。
- 根因：`catalog_upsert_supabase.py` 在 dry-run 對新 food 不寫入 DB，但 alias 階段仍強制查 DB food_id，造成誤報錯誤。
- 修正：在 dry-run 對「新 catalog row」做 in-memory 標記，alias 階段改為模擬 skip，不再查 DB。
- 驗證：
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/catalog_control.ps1 -Action dry-run -Bundle priority2_batch3`
- 結果：run `22353483018`，conclusion=`success`
- commit：`6f4ef1c`
- date：2026-02-24

### 15) Priority2 Batch3 正式 deploy 完成
- 問題：需將 batch3 新食物正式寫入 Supabase 公用資料庫。
- 根因：僅 dry-run 不會寫入，需再執行一次 `dry_run=false`。
- 修正：執行 `catalog_control.ps1 -Action deploy -Bundle priority2_batch3 -ForceWrite`。
- 驗證：
- run `22354515756`
- workflow 結果：`conclusion=success`
- commit：N/A（操作紀錄）
- date：2026-02-24

### 16) 後端名稱分析改為 catalog-first（未命中才 AI）
- 問題：`POST /analyze_name` 原本先檢查 `ai_analyze` 權限，free tier 在名稱輸入時即使 catalog 可命中也可能被擋住。
- 根因：後端流程固定 AI-first，與前端既有「先 catalog、再 AI fallback」策略不一致。
- 修正：
- `backend/app.py` 新增 catalog matching helper，沿用前端門檻（prefix `>=3.5`、score-only `>=4.0`）。
- `POST /analyze_name` 先呼叫 `foods_search`；命中即直接回傳 catalog `AnalysisResult`。
- 僅在 catalog 未命中時，才執行 `_require_entitlement(..., \"ai_analyze\")` 與後續 AI 流程。
- 驗證：
- `python -m py_compile backend/app.py`（通過）
- commit：pending
- date：2026-02-24

### 17) 修正未知食物被誤匹配成 catalog 任一項
- 問題：使用者輸入資料庫沒有的食物名稱時，系統偶發直接回傳不相干 catalog 結果（看起來像「隨便丟一筆」）。
- 根因：前後端 `best match` 都存在 score-only fallback（只看 `match_score>=4.0`），當查詢字串僅包含短 token（如「拿鐵」）也可能被誤認為命中。
- 修正：
- 後端 `backend/app.py`：`_best_catalog_food_match` 移除純分數 fallback，改為 `exact/prefix` 或 `contains+coverage`（`score>=5.0` 且覆蓋率 `>=0.45`）才視為命中。
- 前端 `frontend/lib/state/app_state.dart`：`_bestCatalogFoodMatch` 同步相同規則，避免前後端行為分裂。
- 驗證：
- `python -m py_compile backend/app.py`（通過）
- `flutter analyze frontend/lib/state/app_state.dart`（無新增 error；現有 warning 仍在）
- `flutter build web --release --base-href /food-ai-app/`（通過）
- commit：pending
- date：2026-02-24

### 18) catalog 未收錄時改為「已記錄，後續更新」提示
- 問題：使用者輸入未收錄食物時，free/no-AI 路徑會顯示 `subscription_required`，語意偏向升級而非資料庫未收錄。
- 根因：`analyzeNameAndSave` 在 catalog miss 且不可用 AI 時，固定回傳 `subscription_required`。
- 修正：
- `frontend/lib/state/app_state.dart`：catalog miss + no AI 路徑改為 `NameLookupException('catalog_not_found')`，並將 miss source 改為 `catalog_not_found`。
- `frontend/lib/widgets/record_sheet.dart`：針對 `catalog_not_found` 與 `subscription_required` 補強文案，明確提示「目前資料庫尚未收錄，已記錄，後續會更新」。
- 驗證：
- `flutter analyze frontend/lib/state/app_state.dart frontend/lib/widgets/record_sheet.dart`（無新增 error，既有 warning 仍在）
- `flutter build web --release --base-href /food-ai-app/`（通過）
- commit：pending
- date：2026-02-24

### 19) 新增多入口「直接輸入名稱」快捷操作
- 問題：名稱輸入仍集中在單一路徑（先開記錄流程再選名稱），操作層級偏深。
- 根因：`showRecordSheet` 只能先選模式，Home/Log 畫面沒有可見的「直接名稱輸入」快捷入口。
- 修正：
- `frontend/lib/widgets/record_sheet.dart`：`showRecordSheet` 新增 `preferNameInput` 參數，可直接進名稱輸入流程。
- `frontend/lib/screens/home_screen.dart`：首頁新增「名稱輸入」快捷按鈕，直接開啟 name mode。
- `frontend/lib/screens/log_screen.dart`：紀錄頁 FAB 改為雙按鈕（一般新增 + 直接名稱輸入）。
- 驗證：
- `flutter analyze frontend/lib/widgets/record_sheet.dart frontend/lib/screens/home_screen.dart frontend/lib/screens/log_screen.dart`（無新增 error；既有 warning 仍在）
- `flutter build web --release --base-href /food-ai-app/`（通過）
- `python -m py_compile backend/app.py`（通過）
- commit：pending
- date：2026-02-24

### 20) Free/Paid 權限對齊（先行收斂）
- 問題：付費方案在 `pro` 預設 entitlement 下與 `plus` 有能力差異（缺 `ai_chat`），且 Settings 對後端 `pro/plus` 顯示不明確。
- 根因：`PLAN_PRO_ENTITLEMENTS` 預設值不含完整 AI；前端訂閱欄位主要看 iOS/mock 狀態，未對齊 server plan。
- 修正：
- `backend/app.py`：`PLAN_PRO_ENTITLEMENTS` 預設改為 `_AI_ENTITLEMENTS`（完整 AI）。
- `frontend/lib/state/app_state.dart`：新增 `hasPaidAccess`（統一判斷 paid access）。
- `frontend/lib/screens/settings_screen.dart`：訂閱狀態新增 backend paid plan 分支，顯示 `Subscribed (server)` / `Paid plan`。
- 驗證：
- `python -m py_compile backend/app.py`（通過）
- `flutter analyze --no-fatal-infos --no-fatal-warnings frontend/lib/state/app_state.dart frontend/lib/screens/settings_screen.dart`（通過；既有 info/warning 保留）
- `flutter build web --release --base-href /food-ai-app/`（通過）
- commit：`d131f80`
- date：2026-02-25

### 21) iOS 訂閱改為後端收據驗證（backend source-of-truth）
- 問題：前端只要收到 `PurchaseStatus.purchased/restored` 就可能直接視為訂閱有效，可能出現未驗證收據卻放行 AI 的風險。
- 根因：IAP 流程缺少「後端驗證收據 + 寫回 server plan」這一層，feature gating 仍可被本地 `_iapSubscriptionActive` 影響。
- 修正：
- `backend/app.py`：
  - 新增 `POST /subscription/ios/verify`（`IosSubscriptionVerifyRequest/Response`）。
  - 串接 Apple `verifyReceipt`（production + `21007` sandbox fallback）。
  - 解析 `latest_receipt_info/in_app` 最新到期時間，對應 `plan_id`（pro/plus），並 upsert `profiles.plan_id/subscription_expires_at`。
  - `/health` 增加 iOS verify 設定檢查（secret 是否設定、product ids 數量）。
- `frontend/lib/services/api_service.dart`：新增 `verifyIosSubscription(...)` API。
- `frontend/lib/state/app_state.dart`：
  - IAP 購買/恢復改為呼叫後端驗證收據，不再直接把 `purchased/restored` 當作已訂閱。
  - 驗證後刷新 `access_status`；`canUseFeature` 與 `trialExpired` 改為 backend entitlement/plan 判斷，不再由 `_iapSubscriptionActive` 直接放行。
- 驗證：
- `python -m py_compile backend/app.py`（通過）
- `flutter analyze --no-fatal-warnings --no-fatal-infos frontend/lib/services/api_service.dart frontend/lib/state/app_state.dart`（通過；既有 39 則 info/warning 未新增 error）
- `flutter build web --release --base-href /food-ai-app/`（通過）
- free/pro/plus 分級檢查：
  - free：四項 AI entitlement 皆 deny（`subscription_required`）
  - pro：四項 AI entitlement 皆 allow
  - plus：四項 AI entitlement 皆 allow
- commit：pending
- date：2026-02-25

## 目前進行中（本串）
- 已完成：
- 讀取長期記憶檔與指定 workflow/工具/CSV。
- 補齊 `HANDOFF.md`、`SESSION_NOTES.md`、`CATALOG_AUTOMATION.md`（UTF-8）。
- 建立 `priority2_batch2` 草稿，且確認與 `priority2_batch1` 無重複。
- 新增 `catalog_control.ps1`，可一步控制 validate / dry-run / deploy / status。
- iOS 訂閱流程切換為「後端收據驗證 -> server access 判斷」。
