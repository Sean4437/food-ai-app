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

  String _summaryText(AppLocalizations t, MealEntry? entry) {
    if (entry == null || entry.result == null) return t.summaryEmpty;
    final fat = entry.result!.macros['fat'] ?? 0;
    final protein = entry.result!.macros['protein'] ?? 0;
    final carbs = entry.result!.macros['carbs'] ?? 0;
    final oily = fat >= 70;
    final proteinOk = protein >= 45;
    final carbHigh = carbs >= 70;

    if (oily && carbHigh) return t.summaryOilyCarb;
    if (oily) return t.summaryOily;
    if (carbHigh) return t.summaryCarb;
    if (proteinOk) return t.summaryProteinOk;
    return t.summaryNeutral;
  }

  Widget _statChip(IconData icon, String label, String value) {
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
          Icon(icon, color: const Color(0xFF5B7CFA)),
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
    final entry = app.latestEntryForSelectedDate;
    final entries = app.entriesForSelectedDate;
    final totalMeals = entries.length;
    final breakfast = entries.where((e) => e.type == MealType.breakfast).length;
    final brunch = entries.where((e) => e.type == MealType.brunch).length;
    final lunch = entries.where((e) => e.type == MealType.lunch).length;
    final afternoonTea = entries.where((e) => e.type == MealType.afternoonTea).length;
    final dinner = entries.where((e) => e.type == MealType.dinner).length;
    final lateSnack = entries.where((e) => e.type == MealType.lateSnack).length;
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
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            TabScope.of(context).setIndex(0);
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
                        icon: const Icon(Icons.chevron_left),
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
                        icon: const Icon(Icons.chevron_right),
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
                        Text('${t.mealsCountLabel} $totalMeals ${t.mealsLabel}', style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text(_summaryText(t, entry), style: AppTextStyles.caption(context).copyWith(color: Colors.black54)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _statChip(Icons.free_breakfast, t.breakfast, breakfast.toString()),
                            _statChip(Icons.brunch_dining, t.brunch, brunch.toString()),
                            _statChip(Icons.lunch_dining, t.lunch, lunch.toString()),
                            _statChip(Icons.emoji_food_beverage, t.afternoonTea, afternoonTea.toString()),
                            _statChip(Icons.restaurant, t.dinner, dinner.toString()),
                            _statChip(Icons.nightlife, t.lateSnack, lateSnack.toString()),
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
