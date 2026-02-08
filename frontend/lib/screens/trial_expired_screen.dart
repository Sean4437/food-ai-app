import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import '../design/text_styles.dart';
import '../widgets/app_background.dart';
import '../state/app_state.dart';

class TrialExpiredScreen extends StatelessWidget {
  const TrialExpiredScreen({super.key});

  Future<void> _showMockPaywall(BuildContext context, AppState app, AppLocalizations t) async {
    final title = t.webPaywallTitle;
    final subtitle = t.paywallSubtitle;
    final monthly = t.planMonthlyWithPrice(r'$5.99');
    final yearly = t.planYearlyWithPrice(r'$49.99');
    final yearlyBadge = t.paywallYearlyBadge;
    final testBadge = t.webPaywallTestBadge;
    final cancel = t.cancel;
    final currentPlan = app.mockSubscriptionPlanId;
    final currentPlanLabel = currentPlan == kIapMonthlyId
        ? t.webPaywallCurrentPlanMonthly
        : currentPlan == kIapYearlyId
            ? t.webPaywallCurrentPlanYearly
            : t.webPaywallCurrentPlanNone;
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
                  t.paywallFeatureAiAnalysis,
                  t.paywallFeatureNutritionAdvice,
                  t.paywallFeatureSummaries,
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
                  t.paywallFeatureAiAnalysis,
                  t.paywallFeatureNutritionAdvice,
                  t.paywallFeatureSummaries,
                  t.paywallFeatureBestValue,
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                t.webPaywallTestNote,
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
        await _showMockSuccess(context, t: t);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.webPaywallActivated)),
        );
      }
    }
  }

  Future<void> _showIapPaywall(BuildContext context, AppState app) async {
    final t = AppLocalizations.of(context)!;
    if (!app.iapAvailable) {
      await app.initIap();
    }
    if (!app.iapAvailable) {
      if (context.mounted) {
        await _showIapUnavailable(context, t: t);
      }
      return;
    }
    final monthlyProduct = app.productById(kIapMonthlyId);
    final yearlyProduct = app.productById(kIapYearlyId);
    final monthlyPrice = monthlyProduct?.price ?? '\$5.99';
    final yearlyPrice = yearlyProduct?.price ?? '\$49.99';
    final title = t.paywallTitle;
    final subtitle = t.paywallSubtitle;
    final monthlyTitle = t.planMonthlyWithPrice(monthlyPrice);
    final yearlyTitle = t.planYearlyWithPrice(yearlyPrice);
    final yearlyBadge = t.paywallYearlyBadge;
    final restoreLabel = t.paywallRestore;
    final disclaimer = t.paywallDisclaimer;

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
                  ctaLabel: t.paywallStartMonthly,
                  ctaLoading: app.iapProcessing,
                  onTap: () => app.buySubscription(kIapMonthlyId),
                  onCta: () => app.buySubscription(kIapMonthlyId),
                  bullets: [
                    t.paywallFeatureAiAnalysis,
                    t.paywallFeatureNutritionAdvice,
                    t.paywallFeatureSummaries,
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
                  ctaLabel: t.paywallStartYearly,
                  ctaLoading: app.iapProcessing,
                  onTap: () => app.buySubscription(kIapYearlyId),
                  onCta: () => app.buySubscription(kIapYearlyId),
                  bullets: [
                    t.paywallFeatureAiAnalysis,
                    t.paywallFeatureNutritionAdvice,
                    t.paywallFeatureSummaries,
                    t.paywallFeatureBestValue,
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
                    const Text('✅', style: TextStyle(fontSize: 14)),
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

  Future<void> _showMockSuccess(BuildContext context, {required AppLocalizations t}) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.webPaywallSuccessTitle),
        content: Text(
          t.webPaywallSuccessBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t.webPaywallSuccessCta),
          ),
        ],
      ),
    );
  }

  Future<void> _showIapUnavailable(BuildContext context, {required AppLocalizations t}) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.paywallUnavailableTitle),
        content: Text(
          t.paywallUnavailableBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t.dialogOk),
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
                    if (app.accessStatusFailed) ...[
                      const SizedBox(height: 10),
                      Text(
                        t.accessStatusFailed,
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
