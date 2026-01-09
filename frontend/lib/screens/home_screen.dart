import 'package:flutter/cupertino.dart';
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
  final PageController _pageController = PageController(viewportFraction: 1);
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


  Future<T?> _showPickerSheet<T>({
    required BuildContext context,
    required String title,
    required List<T> options,
    required int initialIndex,
    required String Function(T value) labelBuilder,
  }) async {
    T selected = options[initialIndex.clamp(0, options.length - 1)];
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => SafeArea(
        child: SizedBox(
          height: 280,
          child: Column(
            children: [
              const SizedBox(height: 6),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(8)),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(selected),
                      child: const Text('完成'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 40,
                  scrollController: FixedExtentScrollController(initialItem: initialIndex),
                  onSelectedItemChanged: (index) => selected = options[index],
                  children: [
                    for (final option in options)
                      Center(
                        child: Text(
                          labelBuilder(option),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Future<void> _selectExerciseType(
    BuildContext context,
    AppState app,
    DateTime date,
    AppLocalizations t,
  ) async {
    final options = [
      'none',
      'walking',
      'jogging',
      'cycling',
      'swimming',
      'strength',
      'yoga',
      'hiit',
      'basketball',
      'hiking',
    ];
    final current = app.dailyExerciseType(date);
    final initialIndex = options.indexOf(current);
    final result = await _showPickerSheet<String>(
      context: context,
      title: t.exerciseLabel,
      options: options,
      initialIndex: initialIndex == -1 ? 0 : initialIndex,
      labelBuilder: (value) => app.exerciseLabel(value, t),
    );
    if (result != null) {
      await app.updateDailyExerciseType(date, result);
    }
  }


  Future<void> _selectActivityLevel(
    BuildContext context,
    AppState app,
    DateTime date,
    AppLocalizations t,
  ) async {
    final options = ['sedentary', 'light', 'moderate', 'high'];
    final current = app.dailyActivityLevel(date);
    final initialIndex = options.indexOf(current);
    final result = await _showPickerSheet<String>(
      context: context,
      title: t.activityLevelLabel,
      options: options,
      initialIndex: initialIndex == -1 ? 0 : initialIndex,
      labelBuilder: (value) => app.activityLabel(value, t),
    );
    if (result != null) {
      await app.updateDailyActivity(date, result);
    }
  }


  Future<void> _selectExerciseMinutes(
    BuildContext context,
    AppState app,
    DateTime date,
    AppLocalizations t,
  ) async {
    final options = List.generate(37, (index) => index * 5);
    final current = app.dailyExerciseMinutes(date);
    final initialIndex = options.indexOf(current);
    final result = await _showPickerSheet<int>(
      context: context,
      title: t.exerciseMinutesLabel,
      options: options,
      initialIndex: initialIndex == -1 ? 0 : initialIndex,
      labelBuilder: (value) => '$value ${t.exerciseMinutesUnit}',
    );
    if (result != null) {
      await app.updateDailyExerciseMinutes(date, result);
    }
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
    final current = app.dailyActivityLevel(date);
    final exerciseType = app.dailyExerciseType(date);
    final exerciseMinutes = app.dailyExerciseMinutes(date);
    final exerciseCalories = app.dailyExerciseCalories(date).round();
    final exerciseLabel = app.exerciseLabel(exerciseType, t);
    final shortExercise = exerciseLabel.length > 3 ? exerciseLabel.substring(0, 3) : exerciseLabel;
    return _homeInfoCard(
      appTheme: appTheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.activityCardTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
              style: TextStyle(fontWeight: FontWeight.w700, color: theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectActivityLevel(context, app, date, t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Row(
                      children: [
                        Text(app.activityLabel(current, t), style: const TextStyle(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        const Icon(Icons.chevron_right, size: 18, color: Colors.black38),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => _selectExerciseType(context, app, date, t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Row(
                      children: [
                        Text(shortExercise, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        const Icon(Icons.chevron_right, size: 18, color: Colors.black38),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => _selectExerciseMinutes(context, app, date, t),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black12),
              ),
              child: Row(
                children: [
                  Text(t.exerciseMinutesLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('$exerciseMinutes ${t.exerciseMinutesUnit}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const Icon(Icons.chevron_right, size: 18, color: Colors.black38),
                ],
              ),
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
        padding: const EdgeInsets.symmetric(vertical: 16),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: appTheme.card,
                        borderRadius: BorderRadius.circular(appTheme.radiusCard),
                      ),
                      child: Text(t.latestMealEmpty, style: const TextStyle(color: Colors.black54)),
                    ),
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _homeInfoCard(
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
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _activityCard(activeDate, t, appTheme, app, theme),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _homeInfoCard(
                                appTheme: appTheme,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.dayCardCalorieLabel,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 8),
                                    Builder(
                                      builder: (context) {
                                        return Row(
                                          children: [
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
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    Builder(builder: (context) {
                                      final delta = app.dailyCalorieDeltaValue(activeDate);
                                      final isSurplus = delta != null && delta > 0;
                                      final pillColor = isSurplus ? Colors.redAccent : theme.colorScheme.primary;
                                      final icon = isSurplus ? Icons.warning_amber_rounded : Icons.trending_down;
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: pillColor.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(icon, size: 16, color: pillColor),
                                            const SizedBox(width: 6),
                                            Text(
                                              app.dailyCalorieDeltaLabel(activeDate, t),
                                              style: TextStyle(fontWeight: FontWeight.w600, color: pillColor),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${t.dayCardMealsLabel} ${app.dayMealLabels(activeDate, t)}',
                                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _homeInfoCard(
                                appTheme: appTheme,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.black54),
                                        const SizedBox(width: 6),
                                        Text(
                                          t.dayCardSummaryLabel,
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    if (!app.isDailySummaryReady(activeDate))
                                      Center(
                                        child: Icon(Icons.hourglass_empty, size: 26, color: Colors.black38),
                                      ),
                                    const SizedBox(height: 6),
                                    Text(
                                      app.daySummaryText(activeDate, t),
                                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _homeInfoCard(
                                appTheme: appTheme,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.lightbulb_outline, size: 16, color: Colors.black54),
                                        const SizedBox(width: 6),
                                        Text(
                                          t.dayCardTomorrowLabel,
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    if (!app.isDailySummaryReady(activeDate))
                                      Center(
                                        child: Icon(Icons.hourglass_empty, size: 26, color: Colors.black38),
                                      ),
                                    const SizedBox(height: 6),
                                    Text(
                                      app.dayTomorrowAdvice(activeDate, t),
                                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _homeInfoCard(
                                appTheme: appTheme,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.filter_alt_outlined, size: 16, color: Colors.black54),
                                        const SizedBox(width: 6),
                                        Text(
                                          t.weekSummaryTitle,
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    if (!app.isWeeklySummaryReady(activeDate))
                                      Center(
                                        child: Icon(Icons.hourglass_empty, size: 26, color: Colors.black38),
                                      ),
                                    const SizedBox(height: 6),
                                    Text(
                                      app.weekSummaryText(activeDate, t),
                                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _homeInfoCard(
                                appTheme: appTheme,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.filter_alt_outlined, size: 16, color: Colors.black54),
                                        const SizedBox(width: 6),
                                        Text(
                                          t.nextWeekAdviceTitle,
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    if (!app.isWeeklySummaryReady(activeDate))
                                      Center(
                                        child: Icon(Icons.hourglass_empty, size: 26, color: Colors.black38),
                                      ),
                                    const SizedBox(height: 6),
                                    Text(
                                      app.nextWeekAdviceText(activeDate, t),
                                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
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
    );
  }
}
