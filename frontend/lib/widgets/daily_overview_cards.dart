import 'package:flutter/material.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import '../design/app_theme.dart';
import '../design/text_styles.dart';
import '../state/app_state.dart';

class DailyOverviewCards extends StatelessWidget {
  const DailyOverviewCards({
    super.key,
    required this.date,
    required this.app,
    required this.t,
    required this.appTheme,
    required this.theme,
    required this.onSelectActivityLevel,
    required this.onSelectExerciseType,
    required this.onSelectExerciseMinutes,
  });

  final DateTime date;
  final AppState app;
  final AppLocalizations t;
  final AppTheme appTheme;
  final ThemeData theme;
  final VoidCallback onSelectActivityLevel;
  final VoidCallback onSelectExerciseType;
  final VoidCallback onSelectExerciseMinutes;

  Widget activityCard(BuildContext context) => _activityCard(context);

  Widget calorieCard(BuildContext context) => _calorieCard(context);

  Widget _emojiIcon(String emoji, {double size = 16}) {
    return Text(emoji, style: TextStyle(fontSize: size, height: 1));
  }

  Widget _infoCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appTheme.card,
        borderRadius: BorderRadius.circular(appTheme.radiusCard),
        border: Border.all(color: Colors.black.withOpacity(0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _activityCard(BuildContext context) {
    final current = app.dailyActivityLevel(date);
    final exerciseType = app.dailyExerciseType(date);
    final exerciseMinutes = app.dailyExerciseMinutes(date);
    final exerciseLabel = app.exerciseLabel(exerciseType, t);
    final shortExercise = exerciseLabel.length > 3
        ? exerciseLabel.substring(0, 3)
        : exerciseLabel;
    return _infoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.activityCardTitle,
            style: AppTextStyles.title2(context),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              app.targetCalorieRangeLabel(date, t),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onSelectActivityLevel,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Row(
                      children: [
                        Text(
                          app.activityLabel(current, t),
                          style: AppTextStyles.caption(context)
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right,
                            color: Colors.black45, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: onSelectExerciseType,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Row(
                      children: [
                        Text(
                          shortExercise,
                          style: AppTextStyles.caption(context).copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right,
                            color: Colors.black45, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: onSelectExerciseMinutes,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black12),
              ),
              child: Row(
                children: [
                  Text(
                    t.exerciseMinutesLabel,
                    style: AppTextStyles.caption(context)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    '$exerciseMinutes ${t.exerciseMinutesUnit}',
                    style: AppTextStyles.caption(context)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Icon(Icons.chevron_right,
                      color: Colors.black45, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _calorieCard(BuildContext context) {
    return _infoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.dayCardCalorieLabel,
            style: AppTextStyles.title2(context),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  app.dailyCalorieRangeLabelForDate(date, t),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Builder(builder: (context) {
            final delta = app.dailyCalorieDeltaValue(date);
            final isSurplus = delta != null && delta > 0;
            final pillColor =
                isSurplus ? Colors.redAccent : theme.colorScheme.primary;
            final icon = isSurplus ? '⚠️' : '📉';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: pillColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _emojiIcon(icon, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    app.dailyCalorieDeltaLabel(date, t),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: pillColor,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Text(
            '${t.dayCardMealsLabel} ${app.dayMealLabels(date, t)}',
            style:
                AppTextStyles.caption(context).copyWith(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _activityCard(context)),
        const SizedBox(width: 12),
        Expanded(child: _calorieCard(context)),
      ],
    );
  }
}
