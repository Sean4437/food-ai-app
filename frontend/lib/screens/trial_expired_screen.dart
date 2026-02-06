import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import '../design/text_styles.dart';
import '../widgets/app_background.dart';
import '../state/app_state.dart';

class TrialExpiredScreen extends StatelessWidget {
  const TrialExpiredScreen({super.key});

  Future<void> _showMockPaywall(BuildContext context, AppState app, AppLocalizations t) async {
    final isZh = Localizations.localeOf(context).languageCode.startsWith('zh');
    final title = isZh ? '解鎖完整功能（Web 測試）' : 'Unlock full features (Web test)';
    final subtitle = isZh ? 'AI 分析、營養圖、週／月總結' : 'AI analysis, nutrition charts, weekly/monthly summaries';
    final monthly = isZh ? '月訂 \$5.99' : 'Monthly \$5.99';
    final yearly = isZh ? '年訂 \$49.99' : 'Yearly \$49.99';
    final yearlyBadge = isZh ? '年訂省下約 30%' : 'Save about 30% yearly';
    final testBadge = isZh ? '僅供測試，不會扣款' : 'Test only, no charge';
    final cancel = isZh ? '取消' : 'Cancel';
    final currentPlan = app.mockSubscriptionPlanId;
    final currentPlanLabel = currentPlan == kIapMonthlyId
        ? (isZh ? '目前方案：月訂（測試）' : 'Current plan: Monthly (test)')
        : currentPlan == kIapYearlyId
            ? (isZh ? '目前方案：年訂（測試）' : 'Current plan: Yearly (test)')
            : (isZh ? '目前方案：未訂閱' : 'Current plan: None');
    final chosen = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 12),
            Text(title, style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.body(context).copyWith(color: Colors.black54, fontSize: 13),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                currentPlanLabel,
                textAlign: TextAlign.center,
                style: AppTextStyles.body(context).copyWith(color: Colors.black54, fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _planCard(
                context,
                title: monthly,
                badge: testBadge,
                onTap: () => Navigator.of(context).pop(kIapMonthlyId),
                bullets: [
                  isZh ? '完整 AI 分析' : 'Full AI analysis',
                  isZh ? '熱量與營養建議' : 'Calories & nutrition advice',
                  isZh ? '週／月總結' : 'Weekly/monthly summaries',
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _planCard(
                context,
                title: yearly,
                badge: yearlyBadge,
                onTap: () => Navigator.of(context).pop(kIapYearlyId),
                bullets: [
                  isZh ? '完整 AI 分析' : 'Full AI analysis',
                  isZh ? '熱量與營養建議' : 'Calories & nutrition advice',
                  isZh ? '週／月總結' : 'Weekly/monthly summaries',
                  isZh ? '更划算的長期方案' : 'Best value for long term',
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                isZh ? 'Web 測試版：此流程不會實際扣款。' : 'Web test: this flow does not charge real money.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body(context).copyWith(color: Colors.black45, fontSize: 12),
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.of(context).pop('cancel'),
              child: Text(cancel),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (chosen == kIapMonthlyId || chosen == kIapYearlyId) {
      app.setMockSubscriptionActive(true, planId: chosen);
      if (context.mounted) {
        await _showMockSuccess(context, isZh: isZh);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isZh ? '已啟用測試訂閱' : 'Test subscription enabled')),
        );
      }
    }
  }

  Future<void> _showIapPaywall(BuildContext context, AppState app) async {
    final isZh = Localizations.localeOf(context).languageCode.startsWith('zh');
    if (!app.iapAvailable) {
      await app.initIap();
    }
    if (!app.iapAvailable) {
      if (context.mounted) {
        await _showIapUnavailable(context, isZh: isZh);
      }
      return;
    }
    final monthlyProduct = app.productById(kIapMonthlyId);
    final yearlyProduct = app.productById(kIapYearlyId);
    final monthlyPrice = monthlyProduct?.price ?? '\$5.99';
    final yearlyPrice = yearlyProduct?.price ?? '\$49.99';
    final title = isZh ? '解鎖完整功能' : 'Unlock full features';
    final subtitle = isZh ? 'AI 分析、營養圖、週／月總結' : 'AI analysis, nutrition charts, weekly/monthly summaries';
    final monthlyTitle = isZh ? '月訂 $monthlyPrice' : 'Monthly $monthlyPrice';
    final yearlyTitle = isZh ? '年訂 $yearlyPrice' : 'Yearly $yearlyPrice';
    final yearlyBadge = isZh ? '年訂省下約 30%' : 'Save about 30% yearly';
    final restoreLabel = isZh ? '恢復購買' : 'Restore purchases';
    final disclaimer = isZh
        ? '訂閱將自動續訂，可隨時在 Apple ID 訂閱管理中取消。付款由 Apple 處理。'
        : 'Subscriptions auto‑renew and can be canceled in Apple ID settings. Payments are handled by Apple.';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(8))),
              const SizedBox(height: 12),
              Text(title, style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body(context).copyWith(color: Colors.black54, fontSize: 13),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _planCard(
                  context,
                  title: monthlyTitle,
                  badge: null,
                  ctaLabel: isZh ? '開始月訂' : 'Start monthly',
                  ctaLoading: app.iapProcessing,
                  onTap: () => app.buySubscription(kIapMonthlyId),
                  onCta: () => app.buySubscription(kIapMonthlyId),
                  bullets: [
                    isZh ? '完整 AI 分析' : 'Full AI analysis',
                    isZh ? '熱量與營養建議' : 'Calories & nutrition advice',
                    isZh ? '週／月總結' : 'Weekly/monthly summaries',
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _planCard(
                  context,
                  title: yearlyTitle,
                  badge: yearlyBadge,
                  ctaLabel: isZh ? '開始年訂' : 'Start yearly',
                  ctaLoading: app.iapProcessing,
                  onTap: () => app.buySubscription(kIapYearlyId),
                  onCta: () => app.buySubscription(kIapYearlyId),
                  bullets: [
                    isZh ? '完整 AI 分析' : 'Full AI analysis',
                    isZh ? '熱量與營養建議' : 'Calories & nutrition advice',
                    isZh ? '週／月總結' : 'Weekly/monthly summaries',
                    isZh ? '更划算的長期方案' : 'Best value for long term',
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  disclaimer,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body(context).copyWith(color: Colors.black45, fontSize: 12),
                ),
              ),
              if ((app.iapLastError ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
                  child: Text(
                    app.iapLastError!,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body(context).copyWith(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: app.iapProcessing ? null : () => app.restoreIapPurchases(),
                child: Text(restoreLabel),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _planCard(
    BuildContext context, {
    required String title,
    required List<String> bullets,
    required VoidCallback onTap,
    String? badge,
    String? ctaLabel,
    bool ctaLoading = false,
    VoidCallback? onCta,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w700)),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge,
                      style: AppTextStyles.body(context).copyWith(fontSize: 11, color: theme.colorScheme.primary),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ...bullets.map(
              (text) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Expanded(child: Text(text, style: AppTextStyles.body(context).copyWith(fontSize: 13))),
                  ],
                ),
              ),
            ),
            if (ctaLabel != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: ctaLoading ? null : onCta,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(ctaLoading ? '...' : ctaLabel),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMockSuccess(BuildContext context, {required bool isZh}) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isZh ? '測試訂閱成功' : 'Test Subscription Active'),
        content: Text(
          isZh ? '已解鎖完整功能（測試模式）。' : 'Full features unlocked (test mode).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(isZh ? '開始使用' : 'Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _showIapUnavailable(BuildContext context, {required bool isZh}) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isZh ? '無法載入訂閱' : 'Subscription unavailable'),
        content: Text(
          isZh ? '目前無法取得 App Store 訂閱資訊，請稍後再試。' : 'Unable to load App Store subscriptions. Please try again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(isZh ? '知道了' : 'OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final app = AppStateScope.of(context);
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      t.trialExpiredTitle,
                      style: AppTextStyles.title1(context),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t.trialExpiredBody,
                      style: AppTextStyles.body(context).copyWith(color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                    if ((app.accessStatusError ?? '').isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        app.accessStatusError!,
                        style: AppTextStyles.body(context).copyWith(color: Colors.redAccent, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (kIsWeb) {
                          _showMockPaywall(context, app, t);
                          return;
                        }
                        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
                          _showIapPaywall(context, app);
                          return;
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        t.trialExpiredAction,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    TextButton(
                      onPressed: () => app.signOutSupabase(),
                      child: Text(t.signOut),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
