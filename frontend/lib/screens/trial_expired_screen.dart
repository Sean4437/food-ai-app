import 'package:flutter/material.dart';
import 'package:food_ai_app/gen/app_localizations.dart';

import '../design/text_styles.dart';
import '../state/app_state.dart';
import '../widgets/app_background.dart';
import '../widgets/subscription_paywall.dart';

class TrialExpiredScreen extends StatelessWidget {
  const TrialExpiredScreen({super.key});

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
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 18),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withOpacity(0.92),
                            const Color(0xFF4E7EFF),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        t.trialExpiredTitle,
                        style: AppTextStyles.title1(context)
                            .copyWith(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      t.trialExpiredBody,
                      style:
                          AppTextStyles.body(context).copyWith(color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    _Bullet(text: t.paywallFeatureAiAnalysis),
                    _Bullet(text: t.paywallFeatureNutritionAdvice),
                    _Bullet(text: t.paywallFeatureSummaries),
                    if (app.accessStatusFailed) ...[
                      const SizedBox(height: 10),
                      Text(
                        t.accessStatusFailed,
                        style: AppTextStyles.body(context)
                            .copyWith(color: Colors.redAccent, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: () =>
                          showSubscriptionPaywall(context, app, t),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E4EEA),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.check_circle, size: 16, color: Color(0xFF1E4EEA)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.body(context).copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
