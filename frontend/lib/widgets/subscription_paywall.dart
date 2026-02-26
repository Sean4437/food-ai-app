import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:food_ai_app/gen/app_localizations.dart';

import '../config/feature_flags.dart';
import '../design/text_styles.dart';
import '../state/app_state.dart';

Future<void> showSubscriptionPaywall(
  BuildContext context,
  AppState app,
  AppLocalizations t,
) async {
  if (kIsWeb) {
    if (!kEnableWebMockSubscription) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(t.webPaywallTestNote)));
      }
      return;
    }
    await _showMockPaywall(context, app, t);
    return;
  }
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    await _showIapPaywall(context, app, t);
  }
}

Future<void> _showMockPaywall(
  BuildContext context,
  AppState app,
  AppLocalizations t,
) async {
  final currentPlan = app.mockSubscriptionPlanId;
  final currentPlanLabel = currentPlan == kIapMonthlyId
      ? t.webPaywallCurrentPlanMonthly
      : currentPlan == kIapYearlyId
          ? t.webPaywallCurrentPlanYearly
          : t.webPaywallCurrentPlanNone;

  final chosen = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _SubscriptionSheet(
      title: t.webPaywallTitle,
      subtitle: t.paywallSubtitle,
      statusLine: currentPlanLabel,
      plans: [
        _SubscriptionPlan(
          id: kIapMonthlyId,
          title: t.planMonthlyWithPrice(r'$5.99'),
          badge: t.webPaywallTestBadge,
          ctaLabel: t.paywallStartMonthly,
          highlighted: false,
          bullets: [
            t.paywallFeatureAiAnalysis,
            t.paywallFeatureNutritionAdvice,
            t.paywallFeatureSummaries,
          ],
        ),
        _SubscriptionPlan(
          id: kIapYearlyId,
          title: t.planYearlyWithPrice(r'$49.99'),
          badge: t.paywallYearlyBadge,
          ctaLabel: t.paywallStartYearly,
          highlighted: true,
          bullets: [
            t.paywallFeatureAiAnalysis,
            t.paywallFeatureNutritionAdvice,
            t.paywallFeatureSummaries,
            t.paywallFeatureBestValue,
          ],
        ),
      ],
      processing: false,
      footerText: t.webPaywallTestNote,
      restoreLabel: t.cancel,
      onPlanTap: (planId) async => Navigator.of(context).pop(planId),
      onRestore: () async => Navigator.of(context).pop('cancel'),
    ),
  );

  if (chosen == kIapMonthlyId || chosen == kIapYearlyId) {
    app.setMockSubscriptionActive(true, planId: chosen);
    if (!context.mounted) return;
    await _showMockSuccess(context, t);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.webPaywallActivated)),
    );
  }
}

Future<void> _showIapPaywall(
  BuildContext context,
  AppState app,
  AppLocalizations t,
) async {
  if (!app.iapAvailable) {
    await app.initIap();
  }
  if (!context.mounted) return;
  if (!app.iapAvailable) {
    if (context.mounted) {
      await _showIapUnavailable(context, t);
    }
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AnimatedBuilder(
      animation: app,
      builder: (context, _) {
        final monthlyProduct = app.productById(kIapMonthlyId);
        final yearlyProduct = app.productById(kIapYearlyId);
        final monthlyPrice = monthlyProduct?.price ?? r'$5.99';
        final yearlyPrice = yearlyProduct?.price ?? r'$49.99';
        return _SubscriptionSheet(
          title: t.paywallTitle,
          subtitle: t.paywallSubtitle,
          plans: [
            _SubscriptionPlan(
              id: kIapMonthlyId,
              title: t.planMonthlyWithPrice(monthlyPrice),
              badge: null,
              ctaLabel: t.paywallStartMonthly,
              highlighted: false,
              bullets: [
                t.paywallFeatureAiAnalysis,
                t.paywallFeatureNutritionAdvice,
                t.paywallFeatureSummaries,
              ],
            ),
            _SubscriptionPlan(
              id: kIapYearlyId,
              title: t.planYearlyWithPrice(yearlyPrice),
              badge: t.paywallYearlyBadge,
              ctaLabel: t.paywallStartYearly,
              highlighted: true,
              bullets: [
                t.paywallFeatureAiAnalysis,
                t.paywallFeatureNutritionAdvice,
                t.paywallFeatureSummaries,
                t.paywallFeatureBestValue,
              ],
            ),
          ],
          processing: app.iapProcessing,
          footerText: t.paywallDisclaimer,
          restoreLabel: t.paywallRestore,
          errorText:
              (app.iapLastError ?? '').trim().isEmpty ? null : app.iapLastError,
          onPlanTap: (planId) => app.buySubscription(planId),
          onRestore: app.iapProcessing ? null : app.restoreIapPurchases,
        );
      },
    ),
  );
}

Future<void> _showMockSuccess(BuildContext context, AppLocalizations t) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(t.webPaywallSuccessTitle),
      content: Text(t.webPaywallSuccessBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.webPaywallSuccessCta),
        ),
      ],
    ),
  );
}

Future<void> _showIapUnavailable(BuildContext context, AppLocalizations t) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(t.paywallUnavailableTitle),
      content: Text(t.paywallUnavailableBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.dialogOk),
        ),
      ],
    ),
  );
}

class _SubscriptionSheet extends StatelessWidget {
  const _SubscriptionSheet({
    required this.title,
    required this.subtitle,
    required this.plans,
    required this.processing,
    required this.restoreLabel,
    required this.onPlanTap,
    required this.onRestore,
    this.statusLine,
    this.footerText,
    this.errorText,
  });

  final String title;
  final String subtitle;
  final String? statusLine;
  final List<_SubscriptionPlan> plans;
  final bool processing;
  final String restoreLabel;
  final String? footerText;
  final String? errorText;
  final Future<void> Function(String planId) onPlanTap;
  final Future<void> Function()? onRestore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FBFF),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.14),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withOpacity(0.95),
                        const Color(0xFF4E7EFF),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.title1(context)
                            .copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: AppTextStyles.body(context)
                            .copyWith(color: Colors.white.withOpacity(0.92)),
                      ),
                      if (statusLine != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          statusLine!,
                          style: AppTextStyles.caption(context).copyWith(
                            color: Colors.white.withOpacity(0.88),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ...plans.map(
                  (plan) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SubscriptionPlanCard(
                      plan: plan,
                      processing: processing,
                      onTap: () => onPlanTap(plan.id),
                    ),
                  ),
                ),
                if (footerText != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    footerText!,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption(context)
                        .copyWith(color: Colors.black54),
                  ),
                ],
                if (errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorText!,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body(context)
                        .copyWith(color: Colors.redAccent, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 4),
                TextButton(
                  onPressed:
                      processing || onRestore == null ? null : () => onRestore!(),
                  child: Text(restoreLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SubscriptionPlanCard extends StatelessWidget {
  const _SubscriptionPlanCard({
    required this.plan,
    required this.processing,
    required this.onTap,
  });

  final _SubscriptionPlan plan;
  final bool processing;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = plan.highlighted
        ? const Color(0xFF4E7EFF)
        : theme.colorScheme.primary.withOpacity(0.24);
    final background = plan.highlighted
        ? const Color(0xFFEAF0FF)
        : Colors.white;
    return InkWell(
      onTap: processing ? null : () => onTap(),
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: plan.highlighted ? 1.6 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    plan.title,
                    style: AppTextStyles.body(context)
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (plan.badge != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E4EEA),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      plan.badge!,
                      style: AppTextStyles.caption(context)
                          .copyWith(color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ...plan.bullets.map(
              (text) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(Icons.check_circle, size: 14, color: Color(0xFF1E4EEA)),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        text,
                        style: AppTextStyles.body(context).copyWith(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: processing ? null : () => onTap(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E4EEA),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
                child: processing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(plan.ctaLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionPlan {
  const _SubscriptionPlan({
    required this.id,
    required this.title,
    required this.ctaLabel,
    required this.bullets,
    required this.highlighted,
    this.badge,
  });

  final String id;
  final String title;
  final String ctaLabel;
  final List<String> bullets;
  final bool highlighted;
  final String? badge;
}
