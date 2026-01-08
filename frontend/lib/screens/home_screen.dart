import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import '../state/app_state.dart';
import '../models/meal_entry.dart';
import '../design/app_theme.dart';
import '../widgets/record_sheet.dart';
import '../widgets/plate_photo.dart';
import '../widgets/plate_polygon_stack.dart';
import 'day_meals_screen.dart';
import 'meal_items_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _pageIndex = 0;
  final Map<DateTime, int> _dateSelectedMeal = {};

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openRecordSheet(AppState app) async {
    final result = await showRecordSheet(context, app);
    if (!mounted || result == null) return;
    final mealId = result.mealId;
    if (result.mealCount >= 2) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DayMealsScreen(date: result.date, initialMealId: mealId),
        ),
      );
      return;
    }
    final group = app.entriesForMealId(mealId);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MealItemsScreen(
          group: group,
          autoReturnToDayMeals: true,
          autoReturnDate: result.date,
          autoReturnMealId: mealId,
        ),
      ),
    );
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

  Widget _plateStackForGroups(DateTime date, List<List<MealEntry>> groups) {
    final app = AppStateScope.of(context);
    final plateAsset = app.profile.plateAsset.isEmpty ? kDefaultPlateAsset : app.profile.plateAsset;
    final key = DateTime(date.year, date.month, date.day);
    final selectedIndex = (_dateSelectedMeal[key] ?? 0).clamp(0, groups.length - 1);
    return PlatePolygonStack(
      images: groups.map((group) => group.first.imageBytes).toList(),
      plateAsset: plateAsset,
      selectedIndex: selectedIndex,
      onSelect: (index) => setState(() => _dateSelectedMeal[key] = index),
      onOpen: (_) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DayMealsScreen(date: date)),
      ),
      maxPlateSize: 300,
      minPlateSize: 220,
    );
  }

  Widget _mealStackForDate(
    DateTime date,
    AppLocalizations t,
    ThemeData theme,
    AppTheme appTheme,
    AppState app,
  ) {
    final groups = app.mealGroupsForDateAll(date);
    if (groups.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: appTheme.card,
          borderRadius: BorderRadius.circular(appTheme.radiusCard),
          border: Border.all(color: Colors.black.withOpacity(0.08)),
        ),
        child: Text(t.latestMealEmpty, style: const TextStyle(color: Colors.black54)),
      );
    }

    return _plateStackForGroups(date, groups);
  }

  Widget _homeInfoCard({required Widget child, required AppTheme appTheme}) {
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

  Widget _activityCard(
    DateTime date,
    AppLocalizations t,
    AppTheme appTheme,
    AppState app,
    ThemeData theme,
  ) {
    final levels = ['sedentary', 'light', 'moderate', 'high'];
    final current = app.dailyActivityLevel(date);
    return _homeInfoCard(
      appTheme: appTheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                t.activityCardTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  app.targetCalorieRangeLabel(date, t),
                  style: TextStyle(fontWeight: FontWeight.w700, color: theme.colorScheme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: levels.map((level) {
              final label = app.activityLabel(level, t);
              final selected = level == current;
              return ChoiceChip(
                label: Text(label),
                selected: selected,
                onSelected: (_) => app.updateDailyActivity(date, level),
                selectedColor: theme.colorScheme.primary.withOpacity(0.18),
                labelStyle: TextStyle(
                  color: selected ? theme.colorScheme.primary : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final app = AppStateScope.of(context);
    final entries = app.entries;
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppTheme>()!;
    final dates = entries
        .map((e) => DateTime(e.time.year, e.time.month, e.time.day))
        .toSet()
        .toList();
    dates.sort((a, b) => b.compareTo(a));
    final displayDates = dates.isEmpty ? [DateTime.now()] : dates;
    if (_pageIndex >= displayDates.length) {
      _pageIndex = 0;
    }
    final activeDate = displayDates.isEmpty ? DateTime.now() : displayDates[_pageIndex];

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
                        height: 460,
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() => _pageIndex = index);
                            app.setSelectedDate(displayDates[index]);
                          },
                          itemCount: displayDates.length,
                          itemBuilder: (context, index) => Center(
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: _mealStackForDate(displayDates[index], t, theme, appTheme, app),
                              ),
                            ),
                          ),
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
                      const SizedBox(height: 14),
                      _homeInfoCard(
                        appTheme: appTheme,
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18, color: Colors.black54),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('yyyy/MM/dd', Localizations.localeOf(context).toLanguageTag()).format(activeDate),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => app.finalizeDay(activeDate, Localizations.localeOf(context).toLanguageTag(), t),
                              child: Text(t.finalizeDay),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _activityCard(activeDate, t, appTheme, app, theme),
                      const SizedBox(height: 12),
                      _homeInfoCard(
                        appTheme: appTheme,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  t.dayCardCalorieLabel,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(0.14),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    app.dailyCalorieRangeLabelForDate(activeDate, t),
                                    style: TextStyle(fontWeight: FontWeight.w700, color: theme.colorScheme.primary),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${t.dayCardMealsLabel} ${app.dayMealLabels(activeDate, t)}',
                              style: const TextStyle(fontSize: 14, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _homeInfoCard(
                        appTheme: appTheme,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.dayCardSummaryLabel,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              app.daySummaryText(activeDate, t),
                              style: const TextStyle(fontSize: 14, color: Colors.black54),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              t.dayCardTomorrowLabel,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              app.dayTomorrowAdvice(activeDate, t),
                              style: const TextStyle(fontSize: 14, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _homeInfoCard(
                        appTheme: appTheme,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.weekSummaryTitle,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              app.weekSummaryText(activeDate, t),
                              style: const TextStyle(fontSize: 14, color: Colors.black54),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              t.nextWeekAdviceTitle,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              app.nextWeekAdviceText(activeDate, t),
                              style: const TextStyle(fontSize: 14, color: Colors.black54),
                            ),
                          ],
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
