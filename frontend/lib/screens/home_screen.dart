import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import '../state/app_state.dart';
import '../models/meal_entry.dart';
import '../design/app_theme.dart';
import '../design/text_styles.dart';
import '../widgets/record_sheet.dart';
import '../widgets/plate_photo.dart';
import '../widgets/plate_polygon_stack.dart';
import '../widgets/app_background.dart';
import '../widgets/daily_overview_cards.dart';
import 'day_meals_screen.dart';
import 'meal_items_screen.dart';
import 'custom_foods_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController(viewportFraction: 1);
  int _pageIndex = 0;
  final Map<DateTime, int> _dateSelectedMeal = {};
  String? _lastPlateAsset;

  Widget _emojiIcon(String emoji, {double size = 16}) {
    return Text(emoji, style: TextStyle(fontSize: size, height: 1));
  }

  Widget _skeletonBar(double width, {double height = 12}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildSkeleton(AppTheme appTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _skeletonBar(140, height: 18)),
              const SizedBox(width: 12),
              _skeletonBar(72, height: 22),
            ],
          ),
          const SizedBox(height: 10),
          _skeletonBar(120),
          const SizedBox(height: 16),
          Container(
            height: 360,
            decoration: BoxDecoration(
              color: appTheme.card.withOpacity(0.5),
              borderRadius: BorderRadius.circular(appTheme.radiusCard),
            ),
          ),
          const SizedBox(height: 14),
          _skeletonBar(200),
          const SizedBox(height: 10),
          _skeletonBar(240),
          const SizedBox(height: 10),
          _skeletonBar(180),
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = AppStateScope.of(context);
    final plateAsset = app.profile.plateAsset.isEmpty
        ? kDefaultPlateAsset
        : app.profile.plateAsset;
    if (_lastPlateAsset != plateAsset) {
      _lastPlateAsset = plateAsset;
      precacheImage(AssetImage(plateAsset), context);
    }
  }

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
          builder: (_) =>
              DayMealsScreen(date: result.date, initialMealId: mealId),
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
      child: Text(label,
          style: AppTextStyles.caption(context)
              .copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }

  void _openOverflow(String action, AppState app, AppLocalizations t) {
    if (action == 'settings') {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
    } else if (action == 'custom') {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CustomFoodsScreen()));
    } else if (action == 'reset_mock') {
      app.setMockSubscriptionActive(false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Test subscription cleared')));
    }
  }

  int _streakDays(AppState app) {
    if (app.entries.isEmpty) return 0;
    final loggedDates = app.entries
        .map((e) => DateTime(e.time.year, e.time.month, e.time.day))
        .toSet();
    var day = DateTime.now();
    day = DateTime(day.year, day.month, day.day);
    var count = 0;
    while (loggedDates.contains(day)) {
      count += 1;
      day = day.subtract(const Duration(days: 1));
    }
    return count;
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
                decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(8)),
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
                        style: AppTextStyles.body(context)
                            .copyWith(fontWeight: FontWeight.w600),
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
                  scrollController:
                      FixedExtentScrollController(initialItem: initialIndex),
                  onSelectedItemChanged: (index) => selected = options[index],
                  children: [
                    for (final option in options)
                      Center(
                        child: Text(
                          labelBuilder(option),
                          style: AppTextStyles.body(context),
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
    final plateAsset = app.profile.plateAsset.isEmpty
        ? kDefaultPlateAsset
        : app.profile.plateAsset;
    final key = DateTime(date.year, date.month, date.day);
    final displayGroups = List<List<MealEntry>>.from(groups);
    final selectedIndex =
        (_dateSelectedMeal[key] ?? 0).clamp(0, displayGroups.length - 1);
    return PlatePolygonStack(
      images: displayGroups.map((group) => group.first.imageBytes).toList(),
      plateAsset: plateAsset,
      selectedIndex: selectedIndex,
      onSelect: (index) => setState(() => _dateSelectedMeal[key] = index),
      onOpen: (index) {
        final group = displayGroups[index];
        final mealId = group.first.mealId ?? group.first.id;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DayMealsScreen(date: date, initialMealId: mealId),
          ),
        );
      },
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
        child: Text(t.latestMealEmpty,
            style:
                AppTextStyles.caption(context).copyWith(color: Colors.black54)),
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final app = AppStateScope.of(context);
    final entries = app.entries;
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppTheme>()!;
    if (!app.trialChecked) {
      return AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: _buildSkeleton(appTheme),
          ),
        ),
      );
    }
    final dates = entries
        .map((e) => DateTime(e.time.year, e.time.month, e.time.day))
        .toSet()
        .toList();
    dates.sort((a, b) => b.compareTo(a));
    final displayDates = dates.isEmpty ? [DateTime.now()] : dates;
    if (_pageIndex >= displayDates.length) {
      _pageIndex = 0;
    }
    final activeDate =
        displayDates.isEmpty ? DateTime.now() : displayDates[_pageIndex];
    final nickname = app.profile.name.trim().isEmpty
        ? t.profileName
        : app.profile.name.trim();
    final streakDays = _streakDays(app);

    return AppBackground(
      child: SafeArea(
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
                        Text(t.greetingTitle(nickname),
                            style: AppTextStyles.title2(context)),
                        const SizedBox(height: 4),
                        Text(t.streakLabel(streakDays),
                            style: AppTextStyles.caption(context)
                                .copyWith(color: Colors.black54)),
                      ],
                    ),
                  ),
                  _statusPill(t.aiSuggest, theme.colorScheme.primary),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz),
                    onSelected: (value) => _openOverflow(value, app, t),
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'settings', child: Text(t.settingsTitle)),
                      PopupMenuItem(value: 'custom', child: Text(t.customTabTitle)),
                      if (kIsWeb)
                        const PopupMenuItem(
                            value: 'reset_mock', child: Text('Reset test subscription')),
                    ],
                  ),
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
                    child: Text(t.latestMealEmpty,
                        style: AppTextStyles.caption(context)
                            .copyWith(color: Colors.black54)),
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
                              child: _mealStackForDate(
                                  displayDates[index], t, theme, appTheme, app),
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
                            color: _pageIndex == index
                                ? theme.colorScheme.primary
                                : Colors.black26,
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
                            _emojiIcon('📅', size: 18),
                            const SizedBox(width: 8),
                            Builder(builder: (context) {
                              final localeTag = Localizations.localeOf(context)
                                  .toLanguageTag();
                              final dateLabel =
                                  DateFormat('yyyy/MM/dd', localeTag)
                                      .format(activeDate);
                              final weekdayLabel =
                                  DateFormat('E', localeTag).format(activeDate);
                              return Text(
                                '$dateLabel（$weekdayLabel）',
                                style: AppTextStyles.title2(context),
                              );
                            }),
                            const Spacer(),
                            TextButton(
                              onPressed: () => app.finalizeDay(
                                  activeDate,
                                  Localizations.localeOf(context)
                                      .toLanguageTag(),
                                  t),
                              child: Text(t.finalizeDay),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        height: 200,
                        child: DailyOverviewCards(
                          date: activeDate,
                          app: app,
                          t: t,
                          appTheme: appTheme,
                          theme: theme,
                          onSelectActivityLevel: () =>
                              _selectActivityLevel(context, app, activeDate, t),
                          onSelectExerciseType: () =>
                              _selectExerciseType(context, app, activeDate, t),
                          onSelectExerciseMinutes: () =>
                              _selectExerciseMinutes(context, app, activeDate, t),
                        ),
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
                                      _emojiIcon('💬', size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        t.dayCardSummaryLabel,
                                        style: AppTextStyles.title2(context),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  if (!app.isDailySummaryReady(activeDate))
                                    Center(
                                      child: _emojiIcon('⏳', size: 24),
                                    ),
                                  const SizedBox(height: 6),
                                  Text(
                                    app.daySummaryText(activeDate, t),
                                    style: AppTextStyles.caption(context)
                                        .copyWith(color: Colors.black54),
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
                                      _emojiIcon('💡', size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        t.dayCardTomorrowLabel,
                                        style: AppTextStyles.title2(context),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  if (!app.isDailySummaryReady(activeDate))
                                    Center(
                                      child: _emojiIcon('⏳', size: 24),
                                    ),
                                  const SizedBox(height: 6),
                                  Text(
                                    app.dayTomorrowAdvice(activeDate, t),
                                    style: AppTextStyles.caption(context)
                                        .copyWith(color: Colors.black54),
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
                                      _emojiIcon('📅', size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        t.weekSummaryTitle,
                                        style: AppTextStyles.title2(context),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  if (!app.isWeeklySummaryReady(activeDate))
                                    Center(
                                      child: _emojiIcon('⏳', size: 24),
                                    ),
                                  const SizedBox(height: 6),
                                  Text(
                                    app.weekSummaryText(activeDate, t),
                                    style: AppTextStyles.caption(context)
                                        .copyWith(color: Colors.black54),
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
                                      _emojiIcon('🔮', size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        t.nextWeekAdviceTitle,
                                        style: AppTextStyles.title2(context),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  if (!app.isWeeklySummaryReady(activeDate))
                                    Center(
                                      child: _emojiIcon('⏳', size: 24),
                                    ),
                                  const SizedBox(height: 6),
                                  Text(
                                    app.nextWeekAdviceText(activeDate, t),
                                    style: AppTextStyles.caption(context)
                                        .copyWith(color: Colors.black54),
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
            ],
          ),
        ),
      ),
    );
  }
}
