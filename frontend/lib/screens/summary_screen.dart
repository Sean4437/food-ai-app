import 'package:flutter/material.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import '../state/app_state.dart';
import '../state/tab_state.dart';
import '../models/meal_entry.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  String _summaryText(AppLocalizations t, MealEntry? entry) {
    if (entry == null || entry.result == null) return t.summaryEmpty;
    final fat = entry.result!.macros['fat'] ?? '';
    final protein = entry.result!.macros['protein'] ?? '';
    final carbs = entry.result!.macros['carbs'] ?? '';
    final oily = fat.contains(t.levelHigh) || fat.toLowerCase().contains('high');
    final proteinOk = protein.contains(t.levelMedium) ||
        protein.contains(t.levelHigh) ||
        protein.toLowerCase().contains('medium') ||
        protein.toLowerCase().contains('high');
    final carbHigh = carbs.contains(t.levelHigh) || carbs.toLowerCase().contains('high');

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
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
    final entry = app.latestEntry;
    final totalMeals = app.entries.length;
    final breakfast = app.entries.where((e) => e.type == MealType.breakfast).length;
    final lunch = app.entries.where((e) => e.type == MealType.lunch).length;
    final dinner = app.entries.where((e) => e.type == MealType.dinner).length;
    final lateSnack = app.entries.where((e) => e.type == MealType.lateSnack).length;

    return SafeArea(
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
                    Text(t.summaryTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
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
                      Text('${t.mealsCountLabel} $totalMeals ${t.mealsLabel}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(_summaryText(t, entry), style: const TextStyle(color: Colors.black54)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _statChip(Icons.free_breakfast, t.breakfast, breakfast.toString()),
                          _statChip(Icons.lunch_dining, t.lunch, lunch.toString()),
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
    );
  }
}
