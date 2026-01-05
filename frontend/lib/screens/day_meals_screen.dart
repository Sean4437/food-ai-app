import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import '../state/app_state.dart';
import '../models/meal_entry.dart';
import '../design/app_theme.dart';
import 'meal_items_screen.dart';

class DayMealsScreen extends StatelessWidget {
  const DayMealsScreen({super.key, required this.date});

  final DateTime date;

  String _mealTypeLabel(MealType type, AppLocalizations t) {
    switch (type) {
      case MealType.breakfast:
        return t.breakfast;
      case MealType.lunch:
        return t.lunch;
      case MealType.dinner:
        return t.dinner;
      case MealType.lateSnack:
        return t.lateSnack;
      case MealType.other:
        return t.other;
    }
  }

  String _groupTimeLabel(List<MealEntry> group) {
    final times = group.map((e) => e.time).toList()..sort();
    final start = times.first;
    final end = times.last;
    if (start == end) {
      return '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    }
    return '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
  }

  Widget _photoStack(List<MealEntry> group) {
    final main = group.first;
    final extra = group.length - 1;
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.memory(main.imageBytes, height: 160, width: double.infinity, fit: BoxFit.cover),
        ),
        if (extra > 0)
          Positioned(
            right: 10,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text('+$extra', style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ),
      ],
    );
  }

  Widget _mealCard(BuildContext context, List<MealEntry> group) {
    final t = AppLocalizations.of(context)!;
    final app = AppStateScope.of(context);
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppTheme>()!;
    final summary = app.buildMealSummary(group, t);
    final mealTypeLabel = _mealTypeLabel(group.first.type, t);
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MealItemsScreen(group: group)),
      ),
      child: SizedBox(
        height: 320,
        child: Stack(
          children: [
            Positioned(
              left: 18,
              right: 0,
              top: 12,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: appTheme.card.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(appTheme.radiusCard),
                  border: Border.all(color: Colors.black.withOpacity(0.05), width: 1),
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 8,
              top: 6,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: appTheme.card.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(appTheme.radiusCard),
                  border: Border.all(color: Colors.black.withOpacity(0.07), width: 1),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: appTheme.card,
                  borderRadius: BorderRadius.circular(appTheme.radiusCard),
                  border: Border.all(color: Colors.black.withOpacity(0.08), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(mealTypeLabel, style: TextStyle(color: theme.colorScheme.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                        const Spacer(),
                        Text(
                          _groupTimeLabel(group),
                          style: const TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _photoStack(group),
                    const SizedBox(height: 10),
                    Text(t.mealSummaryTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(
                      '${t.mealTotal}: ${summary?.calorieRange ?? t.calorieUnknown}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 10),
                    Divider(color: Colors.black.withOpacity(0.08)),
                    const SizedBox(height: 8),
                    Text(t.nextMealTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      summary?.advice ?? t.nextMealHint,
                      style: const TextStyle(color: Colors.black54),
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final app = AppStateScope.of(context);
    final groups = app.mealGroupsForDateAll(date);
    final formatter = DateFormat('yyyy/MM/dd', Localizations.localeOf(context).toLanguageTag());
    return Scaffold(
      appBar: AppBar(
        title: Text('${t.dayMealsTitle} · ${formatter.format(date)}'),
        backgroundColor: const Color(0xFFF3F5FB),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (groups.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(t.noEntries),
              ),
            for (final group in groups) ...[
              _mealCard(context, group),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}
