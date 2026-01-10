import 'package:flutter/material.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import '../state/app_state.dart';
import '../widgets/app_background.dart';
import '../design/text_styles.dart';

class NextMealScreen extends StatelessWidget {
  const NextMealScreen({super.key});

  Widget _optionCard({
    required IconData icon,
    required String title,
    required String desc,
    required Color tint,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tint.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: tint),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(desc, style: AppTextStyles.caption(context).copyWith(color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final app = AppStateScope.of(context);
    final entry = app.latestEntryAny;
    final prefix = entry?.result?.source == 'mock' ? '${t.mockPrefix} ' : '';
    return AppBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(t.nextMealTitle, style: AppTextStyles.title1(context)),
                  const SizedBox(height: 6),
                  Text(t.nextMealHint, style: AppTextStyles.caption(context).copyWith(color: Colors.black54)),
                  if (entry?.result != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.detailAiLabel, style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text(
                            '${prefix}${entry!.result!.suggestion}',
                            style: AppTextStyles.caption(context).copyWith(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _optionCard(
                    icon: Icons.store_mall_directory,
                    title: t.optionConvenienceTitle,
                    desc: t.optionConvenienceDesc,
                    tint: const Color(0xFF5B7CFA),
                  ),
                  const SizedBox(height: 12),
                  _optionCard(
                    icon: Icons.lunch_dining,
                    title: t.optionBentoTitle,
                    desc: t.optionBentoDesc,
                    tint: const Color(0xFF8AD7A4),
                  ),
                  const SizedBox(height: 12),
                  _optionCard(
                    icon: Icons.restaurant,
                    title: t.optionLightTitle,
                    desc: t.optionLightDesc,
                    tint: const Color(0xFFF4C95D),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
