import 'package:flutter/material.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import 'package:intl/intl.dart';
import '../state/app_state.dart';
import '../state/tab_state.dart';
import '../models/meal_entry.dart';
import '../widgets/app_background.dart';
import '../design/text_styles.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  String _summaryText(
    AppState app,
    AppLocalizations t,
    MealEntry? entry, {
    required bool beverageOnly,
  }) {
    if (entry == null || entry.result == null) {
      return beverageOnly ? t.summaryBeverageOnly : t.summaryEmpty;
    }
    final fat = app.macroPercentFromResult(entry.result!, 'fat');
    final protein = app.macroPercentFromResult(entry.result!, 'protein');
    final carbs = app.macroPercentFromResult(entry.result!, 'carbs');
    final oily = fat >= 70;
    final proteinOk = protein >= 45;
    final carbHigh = carbs >= 70;

    if (oily && carbHigh) return t.summaryOilyCarb;
    if (oily) return t.summaryOily;
    if (carbHigh) return t.summaryCarb;
    if (proteinOk) return t.summaryProteinOk;
    return t.summaryNeutral;
  }

  Widget _statChip(BuildContext context, String emoji, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption(context).copyWith(color: Colors.black54)),
              Text(value, style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final app = AppStateScope.of(context);
    final entry = app.latestNonBeverageEntryForSelectedDate;
    final entries = app.entriesForSelectedDate;
    final groupsByType = app.mealGroupsByTypeForDate(app.selectedDate);
    final totalMeals = app.mealGroupsForDateAll(app.selectedDate).where((g) => !app.isBeverageGroup(g)).length;
    final entryCount = entries.length;
    final hasBeverageEntries = app.hasBeverageEntriesForDate(app.selectedDate);
    final beverageOnly = hasBeverageEntries && !app.hasNonBeverageEntriesForDate(app.selectedDate);
    final summaryLine = StringBuffer('${t.mealsCountLabel} $totalMeals ${t.mealsLabel} · ${t.itemsCount(entryCount)}');
    if (hasBeverageEntries) {
      summaryLine.write('（${t.includesBeverages}）');
    }
    final proteinRange = app.proteinTargetRangeGrams();
    final proteinConsumed = app.dailyProteinConsumedGrams(app.selectedDate).round();
    final breakfast = groupsByType[MealType.breakfast]?.where((g) => !app.isBeverageGroup(g)).length ?? 0;
    final brunch = groupsByType[MealType.brunch]?.where((g) => !app.isBeverageGroup(g)).length ?? 0;
    final lunch = groupsByType[MealType.lunch]?.where((g) => !app.isBeverageGroup(g)).length ?? 0;
    final afternoonTea = groupsByType[MealType.afternoonTea]?.where((g) => !app.isBeverageGroup(g)).length ?? 0;
    final dinner = groupsByType[MealType.dinner]?.where((g) => !app.isBeverageGroup(g)).length ?? 0;
    final lateSnack = groupsByType[MealType.lateSnack]?.where((g) => !app.isBeverageGroup(g)).length ?? 0;
    final dateFormatter = DateFormat('yyyy/MM/dd', Localizations.localeOf(context).toLanguageTag());
    final selectedDate = app.selectedDate;

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
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: Colors.black45, size: 18),
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            TabScope.of(context).setIndex(2);
                          }
                        },
                      ),
                      const SizedBox(width: 4),
                      Text(t.summaryTitle, style: AppTextStyles.title1(context)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: Colors.black45, size: 18),
                        onPressed: () => app.shiftSelectedDate(-1),
                      ),
                      Expanded(
                        child: Text(
                          dateFormatter.format(selectedDate),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, color: Colors.black45, size: 18),
                        onPressed: () => app.shiftSelectedDate(1),
                      ),
                    ],
                  ),
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
                        Text(
                          summaryLine.toString(),
                          style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _summaryText(app, t, entry, beverageOnly: beverageOnly),
                          style: AppTextStyles.caption(context).copyWith(color: Colors.black54),
                        ),
                        if (proteinRange != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            t.proteinIntakeTodayLabel,
                            style: AppTextStyles.caption(context).copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t.proteinIntakeFormat(
                              app.dailyProteinConsumedGrams(app.selectedDate).round(),
                              proteinRange[0],
                              proteinRange[1],
                            ),
                            style: AppTextStyles.caption(context).copyWith(color: Colors.black54),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _statChip(context, '🍳', t.breakfast, breakfast.toString()),
                            _statChip(context, '🥪', t.brunch, brunch.toString()),
                            _statChip(context, '🍱', t.lunch, lunch.toString()),
                            _statChip(context, '☕', t.afternoonTea, afternoonTea.toString()),
                            _statChip(context, '🍽️', t.dinner, dinner.toString()),
                            _statChip(context, '🌙', t.lateSnack, lateSnack.toString()),
                          ],
                        ),
                      ],
                    ),
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
