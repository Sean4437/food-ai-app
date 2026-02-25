# Food AI App - Handoff

最後更新：2026-02-25

## 1. 專案摘要
- `food-ai-app` 是 Flutter（iOS/Web）+ FastAPI 的飲食記錄與 AI 分析專案。
- 分析入口包含：圖片分析、名稱輸入分析、營養標示分析。
- 資料來源策略：優先 catalog，必要時才進 AI fallback。
- 目標商業策略：Web 主要做測試；正式收費以 iOS 訂閱為主。

## 2. 目錄與環境
- Repo（Windows）：`C:\Users\USER\Documents\AI\food-ai-app`
- Repo（Mac）：`/Users/hsiangyuhsieh/Documents/AI/app/food-ai-app`
- 前端：`frontend/`
- 後端：`backend/`
- SQL/CSV：`backend/sql/`
- Catalog 工具：`tools/`
- Actions：`.github/workflows/`

## 3. 後端部署現況（重要）
- 正式 API Base：`https://food-ai-app-production.up.railway.app`
- 後端主力已是 Railway，不再以本機 `uvicorn` 當主要服務。
- `/health` 受 `X-Admin-Key` 保護；未帶 key 出現 `admin_required` 屬正常行為。

## 4. Auth / 忘記密碼重點
- Web auth 改為 implicit flow，避免 PKCE 在跨裝置流程造成 `code verifier` 失效。
- 忘記密碼錯誤碼已分類：
- `network`
- `rate_limited`
- `link_expired`
- `email_not_found`
- `weak_password`
- `unknown`

## 5. 訂閱與試用策略
- 新用戶試用：`TRIAL_DAYS=2`（前 2 天全功能）。
- 測試白名單：`TEST_BYPASS_EMAILS`。
- 網頁分級模擬：`PLAN_FREE/PLAN_PLUS/PLAN_PRO`（含 entitlement 與 email 白名單）。
- 2026-02-25（commit `d131f80`）：`PLAN_PRO_ENTITLEMENTS` 預設改為完整 AI entitlement（與 paid 對齊），避免付費方案能力不一致。
- 2026-02-25（commit `d131f80`）：Settings 訂閱狀態新增 server plan 判斷，`accessPlan=pro/plus` 會顯示 `Subscribed (server)` 與 `Paid plan`。
- 設定頁不再讓一般使用者修改 API Base URL，避免同步污染。
- 名稱輸入分析採「catalog-first」：catalog 命中時不需 AI entitlement；未命中才檢查 `ai_analyze`。
- 名稱輸入匹配防誤判（2026-02-24）：取消 score-only 命中，改成 `exact/prefix` 或 `contains+coverage` 才能回 catalog，降低「未知食物被硬配對」。
- 補充（2026-02-24）：catalog 未命中且不可用 AI 時，前端改回 `catalog_not_found` 提示，文案為「目前資料庫尚未收錄，已記錄，後續更新」。
- iOS 訂閱驗證（2026-02-25）：
- 後端新增 `POST /subscription/ios/verify`，以 App Store `verifyReceipt`（含 21007 sandbox fallback）驗證收據。
- 驗證結果會寫回 `profiles.plan_id` / `profiles.subscription_expires_at`，並回傳最新 `access`。
- 前端 IAP 購買/恢復改為「先送後端驗證，再刷新 access_status」，不再把 `purchased/restored` 直接視為已訂閱。
- 權限 gating 改為 backend entitlements 為主：`canUseFeature` 與 `trialExpired` 不再用本地 `_iapSubscriptionActive` 放行。

## 6. 前端近期結構調整
- 設定頁已重整，保留必要控制項並清理測試干擾。
- 首頁 overflow 設定導覽改為 tab 切換，避免多層頁面堆疊問題。
- 紀錄頁曾出現整頁空白與 A/B 項目錯位，均已修復。
- 明細頁已加入來源標記方向（資料庫 / AI 估算 / 自訂）。
- 2026-02-24：新增「直接名稱輸入」多入口（Home 快捷按鈕、Log 雙 FAB），並支援 `showRecordSheet(preferNameInput: true)` 直接進 name mode。

## 7. Catalog 架構與流程
- 表：`food_catalog`、`food_aliases`。
- 已落地：飲料糖度/加料公式化、飲料 baseline 保護、批次驗證/部署流程。
- 後端 `POST /analyze_name`（2026-02-24 更新）：
- 先走 `GET /foods/search` + match 門檻（prefix `>=3.5`；contains 需 `score>=5.0` 且覆蓋率 `>=0.45`）
- 命中直接回傳 catalog 結果；未命中才 fallback AI
- 常見問題：
- alias 歧義（ambiguous alias）
- CSV 批次重複
- 目前已切出批次：`priority2_batch1`、`priority2_batch2`、`priority2_batch3`（deploy 可直接選 bundle）。
- 固定部署流程：先 dry-run，再正式寫入，`stop_on_error=true`。
- 詳細流程見：`docs/CATALOG_AUTOMATION.md`

## 8. 關鍵工具與 workflow
- `tools/catalog_validate_bundle.py`
- `tools/catalog_upsert_supabase.py`
- `tools/catalog_control.ps1`（單一入口：validate / dry-run / deploy / status）
- `.github/workflows/catalog_validate.yml`
- `.github/workflows/catalog_deploy.yml`

重要修正（commit `f520ba9`）：
- 當 deploy 指定 `--catalog-file/--alias-file` 時，validator 只驗指定檔，不再掃所有 `*_draft.csv`。
- 目的：避免先前 668 duplicate 誤炸。

## 9. 驗證指令（每次可部署改動後）
- Backend：
```bash
python -m py_compile backend/app.py
```
- Frontend（至少改動檔）：
```bash
flutter analyze
```
- Frontend release：
```bash
flutter build web --release --base-href /food-ai-app/
```

## 10. 交接時最少要確認
1. 本次是否有可部署改動；若有，`SESSION_NOTES` 是否已補「問題/根因/修正/驗證/commit/date」。
2. 若流程或架構有變，`HANDOFF` 是否同步更新。
3. 文字檔是否 UTF-8。
4. 是否只提交任務相關檔案（避免夾帶無關 `docs/*`、`tools/*`）。
