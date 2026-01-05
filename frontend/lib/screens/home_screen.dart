import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import '../state/app_state.dart';
import '../screens/meal_detail_screen.dart';
import '../models/meal_entry.dart';
import '../design/app_theme.dart';
import '../widgets/record_sheet.dart';
import 'day_meals_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.88);
  int _pageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openRecordSheet(AppState app) async {
    await showRecordSheet(context, app);
  }

  Widget _statusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _mealTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  List<String> _overallTagsFromSummary(MealSummary? summary, AppLocalizations t) {
    if (summary == null) return [];
    final tags = <String>[];
    final fat = summary.macros['fat'] ?? '';
    final protein = summary.macros['protein'] ?? '';
    final carbs = summary.macros['carbs'] ?? '';
    if (fat.contains(t.levelHigh) || fat.toLowerCase().contains('high')) tags.add(t.tagOily);
    if (protein.contains(t.levelHigh) || protein.toLowerCase().contains('high')) tags.add(t.tagProteinOk);
    if (protein.contains(t.levelLow) || protein.toLowerCase().contains('low')) tags.add(t.tagProteinLow);
    if (carbs.contains(t.levelHigh) || carbs.toLowerCase().contains('high')) tags.add(t.tagCarbHigh);
    if (tags.isEmpty) tags.add(t.tagOk);
    return tags.take(3).toList();
  }

  Widget _photoStack(List<MealEntry> group) {
    final main = group.first;
    final extra = group.length - 1;
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.memory(main.imageBytes, height: 180, width: double.infinity, fit: BoxFit.cover),
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

  String _groupTimeLabel(List<MealEntry> group) {
    final times = group.map((e) => e.time).toList()..sort();
    final start = times.first;
    final end = times.last;
    if (start == end) {
      return '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    }
    return '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
  }

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

  Future<void> _openMealGroupSheet(BuildContext context, List<MealEntry> group) async {
    final t = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 12),
            Text(t.mealItemsTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final entry in group)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(entry.imageBytes, width: 56, height: 56, fit: BoxFit.cover),
                      ),
                      title: Text(entry.overrideFoodName ?? entry.result?.foodName ?? t.unknownFood),
                      subtitle: Text('${t.portionLabel} ${entry.portionPercent}%'),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MealDetailScreen(entry: entry))),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _mealAdviceCard(
    List<MealEntry> group,
    AppLocalizations t,
    ThemeData theme,
    AppTheme appTheme,
  ) {
    final formatter = DateFormat('MM/dd', Localizations.localeOf(context).toLanguageTag());
    final summary = AppStateScope.of(context).buildMealSummary(group, t);
    final tags = _overallTagsFromSummary(summary, t);
    final mealTypeLabel = _mealTypeLabel(group.first.type, t);
    return GestureDetector(
      onTap: () => _openMealGroupSheet(context, group),
      child: SizedBox(
        height: 380,
        child: Stack(
          children: [
            Positioned(
              left: 18,
              right: 0,
              top: 10,
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
                          '${formatter.format(group.first.time)} · ${_groupTimeLabel(group)}',
                          style: const TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _photoStack(group),
                    const SizedBox(height: 10),
                    Text(
                      summary == null ? t.latestMealTitle : t.mealSummaryTitle,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in tags) _mealTag(tag, theme.colorScheme.primary),
                      ],
                    ),
                    const SizedBox(height: 12),
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

  Widget _dateCard(
    DateTime date,
    AppLocalizations t,
    ThemeData theme,
    AppTheme appTheme,
    AppState app,
  ) {
    final formatter = DateFormat('MM/dd', Localizations.localeOf(context).toLanguageTag());
    final summary = app.buildDaySummary(date, t);
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DayMealsScreen(date: date),
          ),
        );
      },
      child: SizedBox(
        height: 380,
        child: Stack(
          children: [
            Positioned(
              left: 22,
              right: 0,
              top: 14,
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
              left: 12,
              right: 8,
              top: 8,
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
                padding: const EdgeInsets.all(16),
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
                          child: Text(t.dayCardTitle, style: TextStyle(color: theme.colorScheme.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                        const Spacer(),
                        Text(
                          formatter.format(date),
                          style: const TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(t.dailyCalorieRange, style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 6),
                    Text(
                      summary?.calorieRange ?? t.calorieUnknown,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    Text(t.tomorrowAdviceTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
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
    final entries = app.entries;
    final dateFormatter = DateFormat('yyyy/MM/dd', Localizations.localeOf(context).toLanguageTag());
    final selectedDate = app.selectedDate;
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppTheme>()!;
    final dates = entries
        .map((e) => DateTime(e.time.year, e.time.month, e.time.day))
        .toSet()
        .toList();
    dates.sort((a, b) => b.compareTo(a));
    final displayDates = dates.isEmpty ? [DateTime.now()] : dates;

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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.greetingTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(t.streakLabel, style: const TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ),
                    _statusPill(t.aiSuggest, theme.colorScheme.primary),
                  ],
                ),
                const SizedBox(height: 14),
                if (displayDates.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: appTheme.card,
                      borderRadius: BorderRadius.circular(appTheme.radiusCard),
                    ),
                    child: Text(t.latestMealEmpty, style: const TextStyle(color: Colors.black54)),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 420,
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) => setState(() => _pageIndex = index),
                          itemCount: displayDates.length,
                          itemBuilder: (context, index) => _dateCard(displayDates[index], t, theme, appTheme, app),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          displayDates.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _pageIndex == index ? 8 : 6,
                            height: _pageIndex == index ? 8 : 6,
                            decoration: BoxDecoration(
                              color: _pageIndex == index ? theme.colorScheme.primary : Colors.black26,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onTap: () => _openRecordSheet(app),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(t.captureTitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
