import 'dart:ui' show lerpDouble;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import '../state/tab_state.dart';
import '../state/app_state.dart';
import '../models/meal_entry.dart';
import '../design/app_theme.dart';
import '../design/text_styles.dart';
import '../widgets/record_sheet.dart';
import '../widgets/plate_polygon_stack.dart';
import '../widgets/app_background.dart';
import '../widgets/daily_overview_cards.dart';
import 'day_meals_screen.dart';
import 'meal_items_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController(viewportFraction: 1);
  final PageController _statusCardController = PageController();
  int _pageIndex = 0;
  int _statusCardIndex = 0;
  final Map<DateTime, int> _dateSelectedMeal = {};
  String? _lastPlateAsset;
  static const double _statusCardHeight = 210;
  static const int _maxHomeDates = 14;
  static const int _maxPageDots = 5;

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
              color: appTheme.card.withValues(alpha: 0.5),
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
    _statusCardController.dispose();
    super.dispose();
  }

  Future<void> _openRecordSheet(AppState app,
      {bool preferNameInput = false}) async {
    final result = await showRecordSheet(
      context,
      app,
      preferNameInput: preferNameInput,
    );
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
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: AppTextStyles.caption(context)
              .copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }

  bool _isZh(BuildContext context) {
    return Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('zh');
  }

  Future<void> _focusStatusCard(int index) async {
    if (_statusCardIndex != index) {
      setState(() => _statusCardIndex = index);
    }
    if (!_statusCardController.hasClients) return;
    await _statusCardController.animateToPage(
      index,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _insightSheetSection({
    required String title,
    required String body,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.black54),
              const SizedBox(width: 6),
              Text(
                title,
                style: AppTextStyles.body(context)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body.trim().isEmpty ? '-' : body,
            style:
                AppTextStyles.caption(context).copyWith(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Future<void> _showDailyInsightSheet(
    AppState app,
    AppLocalizations t,
    DateTime date,
  ) async {
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppTheme>()!;
    final dateLabel = DateFormat(
      'yyyy/MM/dd E',
      Localizations.localeOf(context).toLanguageTag(),
    ).format(date);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: _homeInfoCard(
            appTheme: appTheme,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(t.summaryTitle, style: AppTextStyles.title2(context)),
                const SizedBox(height: 4),
                Text(
                  dateLabel,
                  style: AppTextStyles.caption(context)
                      .copyWith(color: Colors.black45),
                ),
                const SizedBox(height: 14),
                _insightSheetSection(
                  title: t.dayCardSummaryLabel,
                  body: app.daySummaryText(date, t),
                  icon: Icons.summarize_outlined,
                ),
                const SizedBox(height: 10),
                _insightSheetSection(
                  title: t.dayCardTomorrowLabel,
                  body: app.dayTomorrowAdvice(date, t),
                  icon: Icons.lightbulb_outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showSingleInsightSheet({
    required String title,
    required String dateLabel,
    required AppTheme appTheme,
    required String body,
    required IconData icon,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: _homeInfoCard(
            appTheme: appTheme,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(title, style: AppTextStyles.title2(context)),
                const SizedBox(height: 4),
                Text(
                  dateLabel,
                  style: AppTextStyles.caption(context)
                      .copyWith(color: Colors.black45),
                ),
                const SizedBox(height: 14),
                _insightSheetSection(
                  title: title,
                  body: body,
                  icon: icon,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showTodaySummarySheet(
    AppState app,
    AppLocalizations t,
    DateTime date,
  ) async {
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppTheme>()!;
    final dateLabel = DateFormat(
      'yyyy/MM/dd E',
      Localizations.localeOf(context).toLanguageTag(),
    ).format(date);
    await _showSingleInsightSheet(
      title: t.dayCardSummaryLabel,
      dateLabel: dateLabel,
      appTheme: appTheme,
      body: app.daySummaryText(date, t),
      icon: Icons.summarize_outlined,
    );
  }

  Future<void> _showTomorrowAdviceSheet(
    AppState app,
    AppLocalizations t,
    DateTime date,
  ) async {
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppTheme>()!;
    final dateLabel = DateFormat(
      'yyyy/MM/dd E',
      Localizations.localeOf(context).toLanguageTag(),
    ).format(date);
    await _showSingleInsightSheet(
      title: t.dayCardTomorrowLabel,
      dateLabel: dateLabel,
      appTheme: appTheme,
      body: app.dayTomorrowAdvice(date, t),
      icon: Icons.lightbulb_outline,
    );
  }

  Future<void> _showWeeklyInsightSheet(
    AppState app,
    AppLocalizations t,
    DateTime date,
  ) async {
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppTheme>()!;
    final dateLabel = DateFormat(
      'yyyy/MM/dd E',
      Localizations.localeOf(context).toLanguageTag(),
    ).format(date);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: _homeInfoCard(
            appTheme: appTheme,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(t.weekSummaryTitle, style: AppTextStyles.title2(context)),
                const SizedBox(height: 4),
                Text(
                  dateLabel,
                  style: AppTextStyles.caption(context)
                      .copyWith(color: Colors.black45),
                ),
                const SizedBox(height: 14),
                _insightSheetSection(
                  title: t.weekSummaryTitle,
                  body: app.weekSummaryText(date, t),
                  icon: Icons.calendar_view_week_outlined,
                ),
                const SizedBox(height: 10),
                _insightSheetSection(
                  title: t.nextWeekAdviceTitle,
                  body: app.nextWeekAdviceText(date, t),
                  icon: Icons.next_week_outlined,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleFinalizeDay(
    AppState app,
    AppLocalizations t,
    DateTime activeDate,
  ) async {
    final success = await app.finalizeDay(
      activeDate,
      Localizations.localeOf(context).toLanguageTag(),
      t,
    );
    if (!mounted || !success) return;
    await _focusStatusCard(2);
    if (!mounted) return;
    await _showDailyInsightSheet(app, t, activeDate);
  }

  Future<void> _openOverflow(
    String action,
    AppState app,
    AppLocalizations t,
    DateTime activeDate,
  ) async {
    final tabState = TabScope.of(context);
    final isZh = _isZh(context);
    if (action == 'settings') {
      tabState.setIndex(6); // Settings tab
    } else if (action == 'week_plan') {
      tabState.setIndex(4); // Week plan tab
    } else if (action == 'custom') {
      tabState.setIndex(5); // Custom tab
    } else if (action == 'today_summary') {
      await _focusStatusCard(2);
      if (!mounted) return;
      await _showTodaySummarySheet(app, t, activeDate);
    } else if (action == 'tomorrow_advice') {
      await _focusStatusCard(3);
      if (!mounted) return;
      await _showTomorrowAdviceSheet(app, t, activeDate);
    } else if (action == 'weekly_summary') {
      await _focusStatusCard(4);
      if (!mounted) return;
      await _showWeeklyInsightSheet(app, t, activeDate);
    } else if (action == 'reset_mock') {
      app.setMockSubscriptionActive(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isZh
              ? '\u5df2\u6e05\u9664\u6e2c\u8a66\u8a02\u95b1'
              : 'Test subscription cleared'),
        ),
      );
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
                      child: Text(_isZh(context) ? '?謘?' : 'Cancel'),
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
                      child: Text(_isZh(context) ? '?堆?' : 'Done'),
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
      images: displayGroups
          .map((group) => app.displayImageBytesForEntry(group.first))
          .toList(),
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
          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
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
        border:
            Border.all(color: Colors.black.withValues(alpha: 0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _statusCardDots(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == _statusCardIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 18 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF3C6F5B) : Colors.black12,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }

  List<DateTime> _recentDisplayDates(List<MealEntry> entries) {
    final dates = entries
        .map((e) => DateTime(e.time.year, e.time.month, e.time.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    if (dates.length <= _maxHomeDates) return dates;
    return dates.take(_maxHomeDates).toList();
  }

  List<int> _visiblePageDotIndices(int totalCount, int activeIndex) {
    if (totalCount <= _maxPageDots) {
      return List<int>.generate(totalCount, (index) => index);
    }
    const halfWindow = _maxPageDots ~/ 2;
    var start = activeIndex - halfWindow;
    if (start < 0) start = 0;
    final maxStart = totalCount - _maxPageDots;
    if (start > maxStart) start = maxStart;
    return List<int>.generate(_maxPageDots, (index) => start + index);
  }

  Widget _pageDots(int totalCount, ThemeData theme) {
    final visibleIndices = _visiblePageDotIndices(totalCount, _pageIndex);
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Row(
            key: ValueKey<String>(visibleIndices.join('-')),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final actualIndex in visibleIndices)
                TweenAnimationBuilder<double>(
                  key: ValueKey<int>(actualIndex),
                  tween: Tween<double>(
                    begin: 0,
                    end: _pageIndex == actualIndex ? 1 : 0,
                  ),
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    final isActive = _pageIndex == actualIndex;
                    final width = lerpDouble(8, 24, value) ?? 8;
                    final height = lerpDouble(8, 10, value) ?? 8;
                    final scale = lerpDouble(1, 1.08, value) ?? 1;
                    final color = Color.lerp(
                          Colors.black26,
                          theme.colorScheme.primary,
                          value,
                        ) ??
                        Colors.black26;
                    return Transform.scale(
                      scale: scale,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: width,
                        height: height,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.22),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${_pageIndex + 1} / $totalCount',
          style: AppTextStyles.caption(context)
              .copyWith(color: Colors.black45, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _dailySummaryCard(
    AppState app,
    AppLocalizations t,
    AppTheme appTheme,
    DateTime date,
  ) {
    return _homeInfoCard(
      appTheme: appTheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.summarize_outlined,
                  size: 16, color: Colors.black54),
              const SizedBox(width: 6),
              Text(
                t.dayCardSummaryLabel,
                style: AppTextStyles.title2(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!app.isDailySummaryReady(date))
            const Center(
              child:
                  Icon(Icons.hourglass_empty, size: 24, color: Colors.black45),
            ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              app.daySummaryText(date, t),
              style: AppTextStyles.caption(context)
                  .copyWith(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tomorrowAdviceCard(
    AppState app,
    AppLocalizations t,
    AppTheme appTheme,
    DateTime date,
  ) {
    return _homeInfoCard(
      appTheme: appTheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline,
                  size: 16, color: Colors.black54),
              const SizedBox(width: 6),
              Text(
                t.dayCardTomorrowLabel,
                style: AppTextStyles.title2(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!app.isDailySummaryReady(date))
            const Center(
              child:
                  Icon(Icons.hourglass_empty, size: 24, color: Colors.black45),
            ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              app.dayTomorrowAdvice(date, t),
              style: AppTextStyles.caption(context)
                  .copyWith(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _weeklyInsightCard(
    AppState app,
    AppLocalizations t,
    AppTheme appTheme,
    DateTime date,
  ) {
    return _homeInfoCard(
      appTheme: appTheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_view_week_outlined,
                  size: 16, color: Colors.black54),
              const SizedBox(width: 6),
              Text(
                t.weekSummaryTitle,
                style: AppTextStyles.title2(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!app.isWeeklySummaryReady(date))
            const Center(
              child:
                  Icon(Icons.hourglass_empty, size: 24, color: Colors.black45),
            ),
          const SizedBox(height: 4),
          Text(
            app.weekSummaryText(date, t),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style:
                AppTextStyles.caption(context).copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.next_week_outlined,
                  size: 16, color: Colors.black54),
              const SizedBox(width: 6),
              Text(
                t.nextWeekAdviceTitle,
                style: AppTextStyles.title2(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              app.nextWeekAdviceText(date, t),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(context)
                  .copyWith(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusCardCarousel(
    BuildContext context,
    AppState app,
    AppLocalizations t,
    AppTheme appTheme,
    ThemeData theme,
    DateTime activeDate,
  ) {
    final overview = DailyOverviewCards(
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
    );
    final pages = [
      overview.calorieCard(context),
      overview.proteinCard(context),
      _dailySummaryCard(app, t, appTheme, activeDate),
      _tomorrowAdviceCard(app, t, appTheme, activeDate),
      _weeklyInsightCard(app, t, appTheme, activeDate),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _statusCardHeight,
          child: PageView.builder(
            controller: _statusCardController,
            onPageChanged: (index) => setState(() => _statusCardIndex = index),
            itemCount: pages.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: pages[index],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _statusCardDots(pages.length),
      ],
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
    final recentDates = _recentDisplayDates(entries);
    final hasLoggedDates = recentDates.isNotEmpty;
    final displayDates = hasLoggedDates ? recentDates : [DateTime.now()];
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
                    onSelected: (value) {
                      _openOverflow(value, app, t, activeDate);
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'today_summary',
                        child: Text(t.dayCardSummaryLabel),
                      ),
                      PopupMenuItem(
                        value: 'tomorrow_advice',
                        child: Text(t.dayCardTomorrowLabel),
                      ),
                      PopupMenuItem(
                        value: 'weekly_summary',
                        child: Text(t.weekSummaryTitle),
                      ),
                      PopupMenuItem(
                        value: 'week_plan',
                        child: Text(_isZh(context)
                            ? '\u0037\u5929\u898f\u5283'
                            : '7-day plan'),
                      ),
                      PopupMenuItem(
                        value: 'custom',
                        child: Text(t.customTabTitle),
                      ),
                      PopupMenuItem(
                        value: 'settings',
                        child: Text(t.settingsTitle),
                      ),
                      if (kIsWeb && app.mockSubscriptionActive)
                        PopupMenuItem(
                          value: 'reset_mock',
                          child: Text(
                            _isZh(context)
                                ? '\u5df2\u6e05\u9664\u6e2c\u8a66\u8a02\u95b1'
                                : 'Reset test subscription',
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () =>
                            _openRecordSheet(app, preferNameInput: true),
                        icon: const Icon(Icons.edit_note),
                        label: Text(
                          _isZh(context) ? '輸入餐點' : 'Log by name',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          TabScope.of(context).setIndex(4);
                        },
                        icon: const Icon(Icons.calendar_view_week_rounded),
                        label: Text(
                          _isZh(context) ? '\u770b\u0037\u5929\u9910\u55ae' : 'View 7-day plan',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (!hasLoggedDates)
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
                    _pageDots(displayDates.length, theme),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _homeInfoCard(
                        appTheme: appTheme,
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 18, color: Colors.black54),
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
                                '$dateLabel $weekdayLabel',
                                style: AppTextStyles.title2(context),
                              );
                            }),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                _handleFinalizeDay(app, t, activeDate);
                              },
                              child: Text(t.finalizeDay),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _statusCardCarousel(
                        context,
                        app,
                        t,
                        appTheme,
                        theme,
                        activeDate,
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
