import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/feature_flags.dart';
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

class _SubscriptionSheet extends StatefulWidget {
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
  State<_SubscriptionSheet> createState() => _SubscriptionSheetState();
}

class _SubscriptionSheetState extends State<_SubscriptionSheet> {
  late String _selectedPlanId;

  @override
  void initState() {
    super.initState();
    final initial = widget.plans
        .where((p) => p.highlighted)
        .cast<_SubscriptionPlan?>()
        .firstOrNull;
    _selectedPlanId = (initial ?? widget.plans.first).id;
  }

  _SubscriptionPlan get _selectedPlan {
    for (final plan in widget.plans) {
      if (plan.id == _selectedPlanId) return plan;
    }
    return widget.plans.first;
  }

  List<String> get _benefits {
    final source = _selectedPlan.bullets.isNotEmpty
        ? _selectedPlan.bullets
        : widget.plans.expand((p) => p.bullets);
    final unique = <String>{};
    final list = <String>[];
    for (final item in source) {
      if (unique.add(item)) list.add(item);
      if (list.length >= 4) break;
    }
    return list;
  }

  Future<void> _continue() async {
    if (widget.processing) return;
    await widget.onPlanTap(_selectedPlan.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const processingLabel = 'Processing...';
    final titleStyle = GoogleFonts.notoSansTc(
      color: Colors.white,
      fontSize: 30,
      fontWeight: FontWeight.w900,
      height: 1.1,
      letterSpacing: 0.3,
    );
    final subtitleStyle = GoogleFonts.notoSansTc(
      color: Colors.white.withValues(alpha: 0.88),
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.35,
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0A1428),
                  const Color(0xFF12294D),
                  theme.colorScheme.primary.withValues(alpha: 0.58),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Stack(
              children: [
                const Positioned(
                  top: -120,
                  right: -70,
                  child: _GlowCircle(size: 260, color: Color(0xFF9AD3FF)),
                ),
                const Positioned(
                  bottom: -90,
                  left: -60,
                  child: _GlowCircle(size: 220, color: Color(0xFF76F2B6)),
                ),
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  width: 44,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.34),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              splashRadius: 18,
                              visualDensity: VisualDensity.compact,
                              onPressed: () => Navigator.of(context).maybePop(),
                              icon: Icon(
                                Icons.close_rounded,
                                size: 20,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.22)),
                          ),
                          child: Text(
                            'PREMIUM',
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(widget.title, style: titleStyle),
                        const SizedBox(height: 8),
                        Text(widget.subtitle, style: subtitleStyle),
                        if (widget.statusLine != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              widget.statusLine!,
                              style: GoogleFonts.notoSansTc(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _benefits
                              .map((text) => _BenefitChip(label: text))
                              .toList(),
                        ),
                        const SizedBox(height: 14),
                        ...widget.plans.map(
                          (plan) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _SubscriptionPlanCard(
                              plan: plan,
                              selected: plan.id == _selectedPlanId,
                              processing: widget.processing,
                              onTap: () => setState(() {
                                _selectedPlanId = plan.id;
                              }),
                            ),
                          ),
                        ),
                        if (widget.errorText != null) ...[
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color:
                                      Colors.redAccent.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              widget.errorText!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.notoSansTc(
                                color: const Color(0xFFFFD7D7),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: widget.processing ? null : _continue,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: const Color(0xFF7BFFB8),
                              foregroundColor: const Color(0xFF03231A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: widget.processing
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF03231A),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        processingLabel,
                                        style: GoogleFonts.dmSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    _selectedPlan.ctaLabel,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        TextButton(
                          onPressed:
                              widget.processing || widget.onRestore == null
                                  ? null
                                  : () => widget.onRestore!(),
                          child: Text(
                            widget.restoreLabel,
                            style: GoogleFonts.notoSansTc(
                              color: Colors.white.withValues(alpha: 0.88),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (widget.footerText != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.footerText!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.notoSansTc(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
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
    required this.selected,
    required this.processing,
    required this.onTap,
  });

  final _SubscriptionPlan plan;
  final bool selected;
  final bool processing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? const Color(0xFF7BFFB8)
        : Colors.white.withValues(alpha: 0.22);
    final bgColor = selected
        ? const Color(0xCC0D2F3D)
        : Colors.white.withValues(alpha: 0.09);
    final titleStyle = GoogleFonts.notoSansTc(
      color: Colors.white,
      fontWeight: FontWeight.w800,
      fontSize: 16,
    );

    return InkWell(
      onTap: processing ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: selected ? 1.7 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(plan.title, style: titleStyle)),
                if (plan.badge != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF87F8C0),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      plan.badge!,
                      style: GoogleFonts.dmSans(
                        color: const Color(0xFF093125),
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected
                      ? const Color(0xFF86F7C0)
                      : Colors.white.withValues(alpha: 0.55),
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...plan.bullets.take(3).map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.done_rounded,
                          size: 14,
                          color: selected
                              ? const Color(0xFF8CFBC5)
                              : Colors.white.withValues(alpha: 0.75),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item,
                            style: GoogleFonts.notoSansTc(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12.5,
                              height: 1.25,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _BenefitChip extends StatelessWidget {
  const _BenefitChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, size: 13, color: Color(0xFF91FBC8)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.notoSansTc(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.58),
            color.withValues(alpha: 0),
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
