import 'dart:math' as math;
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import '../state/app_state.dart';
import '../models/meal_entry.dart';
import 'meal_items_screen.dart';
import '../widgets/record_sheet.dart';
import '../widgets/app_background.dart';
import '../design/text_styles.dart';
import '../design/app_theme.dart';
import '../widgets/daily_overview_cards.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

enum _LogSection {
  meals,
  water,
  weight,
}

enum _WaterManualAction {
  clear,
}

class _WaterQuickOption {
  const _WaterQuickOption({
    required this.icon,
    required this.labelZh,
    required this.labelEn,
    required this.ml,
  });

  final IconData icon;
  final String labelZh;
  final String labelEn;
  final int ml;
}

class _WaterBubbleSpec {
  const _WaterBubbleSpec({
    required this.x,
    required this.offset,
    required this.radius,
    required this.speed,
  });

  final double x;
  final double offset;
  final double radius;
  final double speed;
}

class _LogScreenState extends State<LogScreen> with TickerProviderStateMixin {
  late DateTime _selectedDate;
  late DateTime _currentMonth;
  late List<DateTime> _currentMonthDays;
  final ScrollController _dateController = ScrollController();
  final PageController _topCardController = PageController();
  int _topCardIndex = 0;
  String _lastJumpKey = '';
  bool _isSnapping = false;
  int _historyDays = 7;
  bool _historyDaysLoaded = false;
  bool _initialDateSynced = false;
  _LogSection _activeSection = _LogSection.meals;
  final bool _useSimpleWaterControls = true;
  late final AnimationController _waterWaveController;
  late final AnimationController _waterDropController;
  int _selectedWaterQuickIndex = 1;
  Timer? _waterRepeatTimer;
  bool _isWaterRepeatBusy = false;
  double _waterDragDelta = 0;

  static const List<_WaterQuickOption> _waterQuickOptions = [
    _WaterQuickOption(
      icon: Icons.local_cafe_outlined,
      labelZh: '小紙杯',
      labelEn: 'Small cup',
      ml: 180,
    ),
    _WaterQuickOption(
      icon: Icons.coffee_outlined,
      labelZh: '馬克杯',
      labelEn: 'Mug',
      ml: 300,
    ),
    _WaterQuickOption(
      icon: Icons.sports_bar_outlined,
      labelZh: '保溫瓶',
      labelEn: 'Thermos',
      ml: 500,
    ),
    _WaterQuickOption(
      icon: Icons.water_drop_outlined,
      labelZh: '寶特瓶',
      labelEn: 'Bottle',
      ml: 600,
    ),
  ];

  static const double _dateItemWidth = 78;
  static const double _dateItemGap = 6;
  static const double _topCardHeight = 210;
  static const double _bottomDockBaseHeight = 76;
  static const List<int> _historyDayOptions = [7, 14, 30];

  double _fabBottomPadding(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final dockCompensation =
        math.max(46.0, _bottomDockBaseHeight - bottomInset + 6);
    return dockCompensation;
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

  String _withEmoji(String emoji, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return trimmed;
    if (trimmed.startsWith(emoji)) return trimmed;
    return '$emoji $trimmed';
  }

  String _tagWithEmoji(String tag) {
    final normalized = tag.trim();
    switch (normalized) {
      case '偏油':
        return '🍟 $tag';
      case '清淡':
        return '🥗 $tag';
      case '碳水偏多':
        return '🍚 $tag';
      case '蛋白不足':
        return '🥩 $tag';
      default:
        return tag;
    }
  }

  List<String> _displayTags(MealEntry entry, AppLocalizations t) {
    final raw = entry.result?.judgementTags ?? const <String>[];
    final tags = <String>[];
    for (final tag in raw) {
      final normalized = tag.trim().toLowerCase();
      if (normalized.isEmpty) continue;
      if (normalized == 'custom') {
        tags.add('📌 ${t.customTabTitle}');
        continue;
      }
      tags.add(_tagWithEmoji(tag));
    }
    final source =
        (entry.result?.nutritionSource ?? entry.result?.source ?? '').trim();
    if (tags.isEmpty && source == 'custom') {
      tags.add('📌 ${t.customTabTitle}');
    }
    return tags;
  }

  Widget _buildSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _skeletonBar(120, height: 22),
        const SizedBox(height: 12),
        Container(
          height: 90,
          decoration: BoxDecoration(
            color: Colors.black12.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: 16),
        _skeletonBar(180),
        const SizedBox(height: 8),
        Container(
          height: 92,
          decoration: BoxDecoration(
            color: Colors.black12.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: 16),
        _skeletonBar(160),
        const SizedBox(height: 10),
        _skeletonBar(240),
        const SizedBox(height: 10),
        _skeletonBar(200),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _currentMonth = DateTime(now.year, now.month, 1);
    _currentMonthDays = _daysInMonth(_currentMonth);
    _waterWaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
    _waterDropController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = AppStateScope.of(context);
    if (!_initialDateSynced) {
      _syncInitialDateFromEntries(app);
      _initialDateSynced = true;
    }
    if (_historyDaysLoaded) return;
    final saved = app.profile.calorieHistoryDays;
    _historyDays =
        _historyDayOptions.contains(saved) ? saved : _historyDayOptions.first;
    _historyDaysLoaded = true;
  }

  void _syncInitialDateFromEntries(AppState app) {
    DateTime next = app.selectedDate;
    final selectedEntries = app.entriesForDate(next);
    if (selectedEntries.isEmpty && app.entries.isNotEmpty) {
      final latest =
          app.entries.reduce((a, b) => a.time.isAfter(b.time) ? a : b);
      next = DateTime(latest.time.year, latest.time.month, latest.time.day);
    } else {
      next = DateTime(next.year, next.month, next.day);
    }
    _selectedDate = next;
    _currentMonth = DateTime(next.year, next.month, 1);
    _currentMonthDays = _daysInMonth(_currentMonth);
  }

  @override
  void dispose() {
    _stopWaterRepeat();
    _waterWaveController.dispose();
    _waterDropController.dispose();
    _dateController.dispose();
    _topCardController.dispose();
    super.dispose();
  }

  Widget _pageDots(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == _topCardIndex;
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

  String _mealLabel(MealType type, AppLocalizations t) {
    switch (type) {
      case MealType.breakfast:
        return t.breakfast;
      case MealType.brunch:
        return t.brunch;
      case MealType.lunch:
        return t.lunch;
      case MealType.afternoonTea:
        return t.afternoonTea;
      case MealType.dinner:
        return t.dinner;
      case MealType.lateSnack:
        return t.lateSnack;
      case MealType.other:
        return t.other;
    }
  }

  String _timeLabel(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _shortDateLabel(DateTime date) {
    return '${date.month}/${date.day}';
  }

  String _monthLabel(DateTime date, String localeTag) {
    if (localeTag.startsWith('zh')) {
      return '${date.year}年${date.month}月';
    }
    const enMonths = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = date.month >= 1 && date.month <= 12
        ? enMonths[date.month - 1]
        : date.month.toString();
    return '$month ${date.year}';
  }

  List<int>? _parseCalorieRange(String text) {
    final match = RegExp(r'(\d+)\s*-\s*(\d+)').firstMatch(text);
    if (match == null) return null;
    final min = int.tryParse(match.group(1) ?? '');
    final max = int.tryParse(match.group(2) ?? '');
    if (min == null || max == null) return null;
    return [min, max];
  }

  double? _entryCalorieMid(AppState app, MealEntry entry) {
    return app.entryCalorieMid(entry);
  }

  MealEntry? _topMealLast7Days(AppState app) {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 7));
    MealEntry? best;
    double bestScore = -1;
    for (final entry in app.entries) {
      if (entry.time.isBefore(cutoff)) continue;
      final score = _entryCalorieMid(app, entry);
      if (score == null) continue;
      if (score > bestScore) {
        bestScore = score;
        best = entry;
      }
    }
    return best;
  }

  String _entryTitle(MealEntry entry, AppLocalizations t) {
    final override = entry.overrideFoodName?.trim();
    if (override != null && override.isNotEmpty) return override;
    final result = entry.result;
    if (result == null) return entry.filename;
    return result.foodName.isNotEmpty ? result.foodName : t.unknownFood;
  }

  List<DateTime> _daysInMonth(DateTime month) {
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    return List.generate(
        lastDay, (i) => DateTime(month.year, month.month, i + 1));
  }

  bool _isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  DateTime _defaultSelectedDateForMonth(AppState app, DateTime month) {
    final today = DateTime.now();
    if (_isSameMonth(today, month)) {
      return DateTime(today.year, today.month, today.day);
    }
    final dates = app.entries
        .where((entry) =>
            entry.time.year == month.year && entry.time.month == month.month)
        .map((entry) =>
            DateTime(entry.time.year, entry.time.month, entry.time.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    return dates.isNotEmpty
        ? dates.first
        : DateTime(month.year, month.month, 1);
  }

  void _shiftMonth(AppState app, int delta) {
    setState(() {
      final next = DateTime(_currentMonth.year, _currentMonth.month + delta, 1);
      _currentMonth = next;
      _currentMonthDays = _daysInMonth(_currentMonth);
      if (!_isSameMonth(_selectedDate, next)) {
        _selectedDate = _defaultSelectedDateForMonth(app, next);
      }
    });
  }

  Widget _buildHighlightCard(
      BuildContext context, AppState app, AppLocalizations t) {
    final entry = _topMealLast7Days(app);
    if (entry == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Text(t.logTopMealEmpty,
            style:
                AppTextStyles.caption(context).copyWith(color: Colors.black54)),
      );
    }

    final title = _entryTitle(entry, t);
    final mid = _entryCalorieMid(app, entry);
    final kcalText = _withEmoji(
        '🔥', mid == null ? t.calorieUnknown : '${mid.round()} kcal');
    final dateLabel = '${entry.time.month}/${entry.time.day}';
    final mealLabel = _mealLabel(entry.type, t);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _withEmoji('🍽️', t.logTopMealTitle),
                        style: AppTextStyles.caption(context)
                            .copyWith(color: Colors.black54),
                      ),
                      const SizedBox(height: 6),
                      Text(title,
                          style: AppTextStyles.body(context)
                              .copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(kcalText,
                          style: AppTextStyles.title2(context)
                              .copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: [
                          _chip(mealLabel),
                          _chip(t.logRecentDaysTag(dateLabel)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              _squarePhoto(
                app.displayImageBytesForEntry(entry),
                imageUrl: _catalogImageForEntry(app, entry, preferThumb: true),
                photoWidth: 88,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_HistoryPoint> _buildHistoryPoints(
      AppState app, DateTime endDate, int days, AppLocalizations t) {
    final base = DateTime(endDate.year, endDate.month, endDate.day);
    final start = base.subtract(Duration(days: days - 1));
    final points = <_HistoryPoint>[];
    for (var i = 0; i < days; i++) {
      final date = start.add(Duration(days: i));
      final label = app.dailyCalorieRangeLabelForDate(date, t);
      final value = app.calorieRangeMid(label);
      points.add(_HistoryPoint(date: date, value: value));
    }
    return points;
  }

  List<int>? _averageTargetRange(AppState app, DateTime endDate, int days) {
    final base = DateTime(endDate.year, endDate.month, endDate.day);
    final start = base.subtract(Duration(days: days - 1));
    var minSum = 0;
    var maxSum = 0;
    var count = 0;
    for (var i = 0; i < days; i++) {
      final date = start.add(Duration(days: i));
      final label = app.targetCalorieRangeValue(date) ?? '';
      final range = _parseCalorieRange(label);
      if (range == null) continue;
      minSum += range[0];
      maxSum += range[1];
      count += 1;
    }
    if (count == 0) return null;
    return [
      (minSum / count).round(),
      (maxSum / count).round(),
    ];
  }

  double? _proteinTargetMid(AppState app) {
    final range = app.proteinTargetRangeGrams();
    if (range == null) return null;
    return (range[0] + range[1]) / 2;
  }

  List<_HistoryPoint> _buildProteinHistoryPoints(
    AppState app,
    DateTime endDate,
    int days,
  ) {
    final base = DateTime(endDate.year, endDate.month, endDate.day);
    final start = base.subtract(Duration(days: days - 1));
    final points = <_HistoryPoint>[];
    for (var i = 0; i < days; i++) {
      final date = start.add(Duration(days: i));
      final entries = app.entriesForDate(date);
      if (entries.isEmpty) {
        points.add(_HistoryPoint(date: date, value: null));
        continue;
      }
      final value = app.dailyProteinConsumedGrams(date, excludeBeverages: true);
      points.add(_HistoryPoint(date: date, value: value <= 0 ? null : value));
    }
    return points;
  }

  double? _averageProteinHistory(
    AppState app,
    DateTime endDate,
    int days,
  ) {
    final points = _buildProteinHistoryPoints(app, endDate, days);
    final values = points.map((p) => p.value).whereType<double>().toList();
    if (values.isEmpty) return null;
    final sum = values.reduce((a, b) => a + b);
    return sum / values.length;
  }

  double? _averageHistoryValue(
    AppState app,
    DateTime endDate,
    int days,
    AppLocalizations t,
  ) {
    final points = _buildHistoryPoints(app, endDate, days, t);
    final values = points.map((p) => p.value).whereType<double>().toList();
    if (values.isEmpty) return null;
    final sum = values.reduce((a, b) => a + b);
    return sum / values.length;
  }

  String _proteinSummaryText(
    AppState app,
    AppLocalizations t,
  ) {
    final currentAvg = _averageProteinHistory(app, _selectedDate, _historyDays);
    if (currentAvg == null) {
      return t.proteinTrendSummaryNoData;
    }
    final previousEnd = _selectedDate.subtract(Duration(days: _historyDays));
    final previousAvg = _averageProteinHistory(app, previousEnd, _historyDays);
    final avgRounded = currentAvg.round();
    if (previousAvg == null || previousAvg <= 0) {
      return t.proteinTrendSummaryNoPrev(avgRounded.toString());
    }
    final diff = ((currentAvg - previousAvg) / previousAvg * 100).round();
    final periodLabel = _historyCompareLabel(t);
    if (diff == 0) {
      return t.proteinTrendSummarySame(avgRounded.toString(), periodLabel);
    }
    if (diff > 0) {
      return t.proteinTrendSummaryHigher(
          avgRounded.toString(), periodLabel, diff.toString());
    }
    return t.proteinTrendSummaryLower(
        avgRounded.toString(), periodLabel, diff.abs().toString());
  }

  String _historySummaryTitle(AppLocalizations t) {
    switch (_historyDays) {
      case 14:
        return t.calorieTrendSummaryTwoWeeksTitle;
      case 30:
        return t.calorieTrendSummaryMonthTitle;
      default:
        return t.calorieTrendSummaryWeekTitle;
    }
  }

  String _historyCompareLabel(AppLocalizations t) {
    switch (_historyDays) {
      case 14:
        return t.calorieTrendCompareLastTwoWeeks;
      case 30:
        return t.calorieTrendCompareLastMonth;
      default:
        return t.calorieTrendCompareLastWeek;
    }
  }

  String _historySummaryText(
    AppState app,
    AppLocalizations t,
  ) {
    final currentAvg =
        _averageHistoryValue(app, _selectedDate, _historyDays, t);
    if (currentAvg == null) {
      return t.calorieTrendSummaryNoData;
    }
    final previousEnd = _selectedDate.subtract(Duration(days: _historyDays));
    final previousAvg = _averageHistoryValue(app, previousEnd, _historyDays, t);
    final avgRounded = currentAvg.round();
    if (previousAvg == null || previousAvg <= 0) {
      return t.calorieTrendSummaryNoPrev(avgRounded.toString());
    }
    final diff = ((currentAvg - previousAvg) / previousAvg * 100).round();
    final periodLabel = _historyCompareLabel(t);
    if (diff == 0) {
      return t.calorieTrendSummarySame(avgRounded.toString(), periodLabel);
    }
    if (diff > 0) {
      return t.calorieTrendSummaryHigher(
          avgRounded.toString(), periodLabel, diff.toString());
    }
    return t.calorieTrendSummaryLower(
        avgRounded.toString(), periodLabel, diff.abs().toString());
  }

  Widget _buildHistoryRangeSelector(
      AppState app, ThemeData theme, AppTheme appTheme) {
    final borderColor = Colors.black.withValues(alpha: 0.08);
    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EEE9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < _historyDayOptions.length; i++) ...[
            _buildHistoryRangeChip(
              app,
              _historyDayOptions[i],
              theme,
              appTheme,
            ),
            if (i != _historyDayOptions.length - 1)
              Container(
                width: 1,
                height: 14,
                color: borderColor,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryRangeChip(
    AppState app,
    int days,
    ThemeData theme,
    AppTheme appTheme,
  ) {
    final selected = _historyDays == days;
    final color = selected ? Colors.white : Colors.transparent;
    final textColor = selected ? theme.colorScheme.primary : Colors.black54;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () {
        if (_historyDays == days) return;
        setState(() => _historyDays = days);
        app.updateField((profile) {
          profile.calorieHistoryDays = days;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          '$days',
          style: AppTextStyles.body(context).copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildCalorieHistoryCard(
    BuildContext context,
    AppState app,
    AppLocalizations t,
    AppTheme appTheme,
    ThemeData theme,
  ) {
    final points = _buildHistoryPoints(app, _selectedDate, _historyDays, t);
    final hasData = points.any((p) => p.value != null);
    final targetRange = _averageTargetRange(app, _selectedDate, _historyDays);
    final targetLabel = targetRange == null
        ? null
        : t.calorieTrendTargetLabel(
            targetRange[0].toString(), targetRange[1].toString());
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                t.calorieHistoryTitle,
                style: AppTextStyles.title2(context),
              ),
              const Spacer(),
              _buildHistoryRangeSelector(app, theme, appTheme),
            ],
          ),
          const SizedBox(height: 6),
          Transform.translate(
            offset: const Offset(0, 0),
            child: Column(
              children: [
                SizedBox(
                  height: 82,
                  child: hasData
                      ? _CalorieHistoryChart(
                          points: points,
                          lineColor: theme.colorScheme.primary,
                          targetMin: targetRange?[0].toDouble(),
                          targetMax: targetRange?[1].toDouble(),
                          targetLabel: targetLabel,
                        )
                      : Center(
                          child: Text(
                            t.noEntries,
                            style: AppTextStyles.caption(context)
                                .copyWith(color: Colors.black54),
                          ),
                        ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_shortDateLabel(points.first.date),
                        style: AppTextStyles.caption(context)
                            .copyWith(color: Colors.black45)),
                    Text(_shortDateLabel(points.last.date),
                        style: AppTextStyles.caption(context)
                            .copyWith(color: Colors.black45)),
                  ],
                ),
                const SizedBox(height: 4),
                Divider(
                    height: 1, color: Colors.black12.withValues(alpha: 0.6)),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _historySummaryTitle(t),
                      style: AppTextStyles.body(context)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _historySummaryText(app, t),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body(context)
                            .copyWith(fontSize: 12, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProteinHistoryCard(
    BuildContext context,
    AppState app,
    AppLocalizations t,
    AppTheme appTheme,
    ThemeData theme,
  ) {
    final points = _buildProteinHistoryPoints(app, _selectedDate, _historyDays);
    final hasData = points.any((p) => p.value != null);
    final targetMid = _proteinTargetMid(app);
    final targetLabel = targetMid == null
        ? null
        : t.proteinTrendTargetLabel(targetMid.round().toString());
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                t.proteinTrendTitle,
                style: AppTextStyles.title2(context),
              ),
              const Spacer(),
              _buildHistoryRangeSelector(app, theme, appTheme),
            ],
          ),
          const SizedBox(height: 6),
          Transform.translate(
            offset: const Offset(0, 0),
            child: Column(
              children: [
                SizedBox(
                  height: 82,
                  child: hasData
                      ? _CalorieHistoryChart(
                          points: points,
                          lineColor: theme.colorScheme.primary,
                          targetMin: targetMid,
                          targetMax: targetMid,
                          targetLabel: targetLabel,
                        )
                      : Center(
                          child: Text(
                            t.noEntries,
                            style: AppTextStyles.caption(context)
                                .copyWith(color: Colors.black54),
                          ),
                        ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_shortDateLabel(points.first.date),
                        style: AppTextStyles.caption(context)
                            .copyWith(color: Colors.black45)),
                    Text(_shortDateLabel(points.last.date),
                        style: AppTextStyles.caption(context)
                            .copyWith(color: Colors.black45)),
                  ],
                ),
                const SizedBox(height: 4),
                Divider(
                    height: 1, color: Colors.black12.withValues(alpha: 0.6)),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _historySummaryTitle(t),
                      style: AppTextStyles.body(context)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _proteinSummaryText(app, t),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body(context)
                            .copyWith(fontSize: 12, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F2EE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF3C6F5B),
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _squarePhoto(
    Uint8List bytes, {
    String? imageUrl,
    BorderRadius? borderRadius,
    double radius = 0,
    required double photoWidth,
  }) {
    final resolvedRadius = borderRadius ?? BorderRadius.circular(radius);
    final normalizedUrl = imageUrl?.trim() ?? '';
    final cacheSize = (photoWidth * 2).round();
    Widget memoryImage() {
      if (bytes.isEmpty) {
        return Container(
          color: const Color(0xFFEAF2EE),
          alignment: Alignment.center,
          child: const Icon(Icons.image_not_supported_outlined,
              size: 20, color: Color(0xFF7A8A84)),
        );
      }
      return Image.memory(
        bytes,
        width: photoWidth,
        height: photoWidth,
        fit: BoxFit.cover,
        cacheWidth: cacheSize,
        cacheHeight: cacheSize,
        errorBuilder: (_, __, ___) => Container(
          color: const Color(0xFFEAF2EE),
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_outlined,
              size: 20, color: Color(0xFF7A8A84)),
        ),
      );
    }

    return SizedBox(
      width: photoWidth,
      height: photoWidth,
      child: ClipRRect(
        borderRadius: resolvedRadius,
        child: normalizedUrl.isNotEmpty
            ? Image.network(
                normalizedUrl,
                width: photoWidth,
                height: photoWidth,
                fit: BoxFit.cover,
                cacheWidth: cacheSize,
                cacheHeight: cacheSize,
                errorBuilder: (_, __, ___) => memoryImage(),
              )
            : memoryImage(),
      ),
    );
  }

  String? _catalogImageForEntry(
    AppState app,
    MealEntry entry, {
    required bool preferThumb,
  }) {
    if (!app.isNamePlaceholderImage(entry.imageBytes)) {
      return null;
    }
    final thumb = entry.result?.catalogThumbUrl?.trim() ?? '';
    final full = entry.result?.catalogImageUrl?.trim() ?? '';
    if (preferThumb && thumb.isNotEmpty) return thumb;
    if (full.isNotEmpty) return full;
    if (thumb.isNotEmpty) return thumb;
    return null;
  }

  Widget _buildMonthHeader(BuildContext context, AppState app) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final monthLabel = _monthLabel(_currentMonth, locale);
    return Row(
      children: [
        IconButton(
          onPressed: () => _shiftMonth(app, -1),
          icon: const Icon(Icons.chevron_left, color: Colors.black45, size: 18),
        ),
        Expanded(
          child: Text(
            monthLabel,
            textAlign: TextAlign.center,
            style: AppTextStyles.body(context)
                .copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          onPressed: () => _shiftMonth(app, 1),
          icon:
              const Icon(Icons.chevron_right, color: Colors.black45, size: 18),
        ),
      ],
    );
  }

  double _dateItemExtent() => _dateItemWidth + _dateItemGap * 2;

  int _indexForDate(DateTime date) => date.day - 1;

  int _centerIndexForOffset(double offset, double viewportWidth, int count) {
    final extent = _dateItemExtent();
    final leading = _leadingPadding(viewportWidth);
    final center = offset + viewportWidth / 2;
    final index = ((center - leading - extent / 2) / extent).round();
    return index.clamp(0, count - 1);
  }

  double _offsetForIndex(int index, double viewportWidth) {
    final extent = _dateItemExtent();
    final leading = _leadingPadding(viewportWidth);
    return (leading + index * extent + extent / 2) - viewportWidth / 2;
  }

  double _leadingPadding(double viewportWidth) {
    final extent = _dateItemExtent();
    final padding = (viewportWidth - extent) / 2;
    return padding < 0 ? 0 : padding;
  }

  void _snapToClosest(AppState app, double viewportWidth, List<DateTime> days) {
    if (!_dateController.hasClients) return;
    if (_isSnapping) return;
    final index = _centerIndexForOffset(
        _dateController.offset, viewportWidth, days.length);
    final target = _offsetForIndex(index, viewportWidth)
        .clamp(0.0, _dateController.position.maxScrollExtent);
    final date = days[index];
    if (date.year != _selectedDate.year ||
        date.month != _selectedDate.month ||
        date.day != _selectedDate.day) {
      setState(() => _selectedDate = date);
    }
    if ((_dateController.offset - target).abs() < 0.5) {
      return;
    }
    _isSnapping = true;
    _dateController
        .animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    )
        .whenComplete(() {
      if (!mounted) return;
      _isSnapping = false;
    });
  }

  void _jumpToSelected(DateTime date, double viewportWidth, int count) {
    if (!_dateController.hasClients) return;
    final index = _indexForDate(date).clamp(0, count - 1);
    final target = _offsetForIndex(index, viewportWidth)
        .clamp(0.0, _dateController.position.maxScrollExtent);
    _dateController.jumpTo(target);
  }

  String _dailyAverageNumber(AppState app, AppLocalizations t, DateTime date) {
    final label = app.dailyCalorieRangeLabelForDate(date, t);
    final range = _parseCalorieRange(label);
    if (range == null) return '—';
    final mid = ((range[0] + range[1]) / 2).round();
    return mid.toString();
  }

  Widget _buildDateCard(
    BuildContext context,
    AppState app,
    AppLocalizations t,
    DateTime date, {
    required double scale,
    required bool isCentered,
  }) {
    final hasData = app.entriesForDate(date).isNotEmpty;
    final selectedLabel =
        hasData ? app.dailyCalorieRangeLabelForDate(date, t) : '—';
    final idleLabel = hasData ? _dailyAverageNumber(app, t, date) : '—';
    final bgColor =
        isCentered ? Theme.of(context).colorScheme.primary : Colors.transparent;
    final fgColor =
        isCentered ? Colors.white : (hasData ? Colors.black87 : Colors.black38);
    final borderColor = isCentered ? Colors.transparent : Colors.black12;
    return SizedBox(
      width: _dateItemExtent(),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: _dateItemGap, vertical: 4),
        child: Transform.scale(
          scale: scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${date.month}/${date.day}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: fgColor, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    isCentered ? selectedLabel : idleLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: fgColor, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _mealRow(BuildContext context, AppState app, MealEntry entry,
      List<MealEntry> group) {
    final t = AppLocalizations.of(context)!;
    final summary = _entryTitle(entry, t);
    final mid = app.entryCalorieMid(entry);
    final calorie =
        _withEmoji('🔥', mid == null ? '—' : mid.round().toString());
    final tags = _displayTags(entry, t);
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MealItemsScreen(
              group: group,
              initialEntryId: entry.id,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: const BoxConstraints(minHeight: 88),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _squarePhoto(
                  app.displayImageBytesForEntry(entry),
                  imageUrl:
                      _catalogImageForEntry(app, entry, preferThumb: true),
                  photoWidth: 92,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _timeLabel(entry.time),
                              style: AppTextStyles.caption(context)
                                  .copyWith(color: Colors.black54),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                summary,
                                style: AppTextStyles.body(context)
                                    .copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Text(calorie,
                                style: AppTextStyles.caption(context)
                                    .copyWith(color: Colors.black54)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (tags.isNotEmpty)
                          Text(
                            tags.join(' · '),
                            style: AppTextStyles.caption(context)
                                .copyWith(color: Colors.black45),
                          )
                        else
                          const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _mealSection(BuildContext context, AppState app, MealType type,
      List<List<MealEntry>> groups) {
    final t = AppLocalizations.of(context)!;
    if (groups.isEmpty) {
      return const SizedBox.shrink();
    }
    try {
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_mealLabel(type, t),
                style: AppTextStyles.body(context)
                    .copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Column(
              children: [
                for (final group in groups)
                  for (final entry in group)
                    _mealRow(context, app, entry, group),
              ],
            ),
          ],
        ),
      );
    } catch (err, stack) {
      debugPrint('LogScreen meal section failed: $err');
      debugPrintStack(stackTrace: stack);
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          t.noEntries,
          style: AppTextStyles.caption(context).copyWith(color: Colors.black54),
        ),
      );
    }
  }

  Widget _buildTopCards(
    BuildContext context,
    AppState app,
    AppLocalizations t,
    AppTheme appTheme,
    ThemeData theme,
  ) {
    try {
      final overview = DailyOverviewCards(
        date: _selectedDate,
        app: app,
        t: t,
        appTheme: appTheme,
        theme: theme,
        onSelectActivityLevel: () =>
            _selectActivityLevel(context, app, _selectedDate, t),
        onSelectExerciseType: () =>
            _selectExerciseType(context, app, _selectedDate, t),
        onSelectExerciseMinutes: () =>
            _selectExerciseMinutes(context, app, _selectedDate, t),
      );
      final pages = [
        overview.calorieCard(context),
        _buildCalorieHistoryCard(context, app, t, appTheme, theme),
        overview.proteinCard(context),
        _buildProteinHistoryCard(context, app, t, appTheme, theme),
        _buildHighlightCard(context, app, t),
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: _topCardHeight,
            child: PageView.builder(
              controller: _topCardController,
              onPageChanged: (index) => setState(() => _topCardIndex = index),
              itemCount: pages.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: pages[index],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _pageDots(pages.length),
        ],
      );
    } catch (err, stack) {
      debugPrint('LogScreen top cards failed: $err');
      debugPrintStack(stackTrace: stack);
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          t.noEntries,
          style: AppTextStyles.caption(context).copyWith(color: Colors.black54),
        ),
      );
    }
  }

  bool get _isZh => Localizations.localeOf(context).languageCode == 'zh';

  String _sectionLabel(_LogSection section) {
    if (_isZh) {
      switch (section) {
        case _LogSection.meals:
          return '飲食';
        case _LogSection.water:
          return '喝水';
        case _LogSection.weight:
          return '體重';
      }
    }
    switch (section) {
      case _LogSection.meals:
        return 'Meals';
      case _LogSection.water:
        return 'Water';
      case _LogSection.weight:
        return 'Weight';
    }
  }

  String _hydrationSourceLabel(String tag) {
    if (_isZh) {
      switch (tag) {
        case 'formula':
          return '飲料公式';
        case 'catalog':
          return '資料庫';
        case 'ai':
          return 'AI';
        default:
          return '其他';
      }
    }
    switch (tag) {
      case 'formula':
        return 'Formula';
      case 'catalog':
        return 'Catalog';
      case 'ai':
        return 'AI';
      default:
        return 'Other';
    }
  }

  Widget _buildSectionSwitcher(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: CupertinoSlidingSegmentedControl<_LogSection>(
        groupValue: _activeSection,
        thumbColor:
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.16),
        children: {
          for (final section in _LogSection.values)
            section: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                _sectionLabel(section),
                style: AppTextStyles.caption(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
        },
        onValueChanged: (next) {
          if (next == null) return;
          setState(() => _activeSection = next);
        },
      ),
    );
  }

  Widget _buildWaterMetricChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.black54),
          const SizedBox(width: 6),
          Text(
            '$label $value',
            style: AppTextStyles.caption(context).copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _WaterQuickOption get _selectedWaterQuickOption {
    final safeIndex = _selectedWaterQuickIndex.clamp(
      0,
      _waterQuickOptions.length - 1,
    );
    return _waterQuickOptions[safeIndex];
  }

  void _shiftWaterQuickIndex(int delta) {
    if (_waterQuickOptions.isEmpty) return;
    final next = (_selectedWaterQuickIndex + delta)
        .clamp(0, _waterQuickOptions.length - 1);
    if (next == _selectedWaterQuickIndex) return;
    setState(() => _selectedWaterQuickIndex = next);
  }

  void _setWaterQuickIndex(int index) {
    final safe = index.clamp(0, _waterQuickOptions.length - 1);
    if (safe == _selectedWaterQuickIndex) return;
    setState(() => _selectedWaterQuickIndex = safe);
  }

  void _onWaterShutterDragUpdate(DragUpdateDetails details) {
    _waterDragDelta += details.delta.dx;
    const threshold = 22.0;
    if (_waterDragDelta <= -threshold) {
      _waterDragDelta = 0;
      _shiftWaterQuickIndex(1);
    } else if (_waterDragDelta >= threshold) {
      _waterDragDelta = 0;
      _shiftWaterQuickIndex(-1);
    }
  }

  void _stopWaterRepeat() {
    _waterRepeatTimer?.cancel();
    _waterRepeatTimer = null;
    _isWaterRepeatBusy = false;
  }

  void _startWaterRepeat(AppState app) {
    _stopWaterRepeat();
    _waterRepeatTimer = Timer.periodic(const Duration(milliseconds: 420), (_) {
      if (_isWaterRepeatBusy) return;
      _isWaterRepeatBusy = true;
      _addWaterByAmount(app, _selectedWaterQuickOption.ml).whenComplete(() {
        _isWaterRepeatBusy = false;
      });
    });
  }

  Widget _buildWaterQuickPill(
    BuildContext context, {
    required int index,
    required _WaterQuickOption option,
  }) {
    final isSelected = index == _selectedWaterQuickIndex;
    final accent = Theme.of(context).colorScheme.primary;
    final label = _isZh ? option.labelZh : option.labelEn;
    return GestureDetector(
      onTap: () => _setWaterQuickIndex(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: isSelected
              ? accent.withValues(alpha: 0.18)
              : Colors.black.withValues(alpha: 0.04),
          border: Border.all(
            color: isSelected
                ? accent.withValues(alpha: 0.55)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(option.icon,
                size: 16, color: isSelected ? accent : Colors.black54),
            const SizedBox(width: 6),
            Text(
              '$label +${option.ml}',
              style: AppTextStyles.caption(context).copyWith(
                color: Colors.black87,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterBottle(
    BuildContext context, {
    required double progress,
  }) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final safeProgress = progress.clamp(0.0, 1.0);
    final percentText = '${(safeProgress * 100).round()}%';

    return AnimatedBuilder(
      animation: Listenable.merge([
        _waterWaveController,
        _waterDropController,
      ]),
      builder: (context, child) {
        final wavePhase = _waterWaveController.value * math.pi * 2;
        final dropT = Curves.easeIn.transform(_waterDropController.value);
        final showDrop =
            _waterDropController.value > 0 && _waterDropController.value < 1;
        final dropOpacity = (1.0 - _waterDropController.value).clamp(0.0, 1.0);

        return SizedBox(
          width: 92,
          height: 230,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                children: [
                  Container(
                    width: 42,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: accent.withValues(alpha: 0.5)),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                        border:
                            Border.all(color: accent.withValues(alpha: 0.55)),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(color: accent.withValues(alpha: 0.08)),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: AnimatedFractionallySizedBox(
                                duration: const Duration(milliseconds: 650),
                                curve: Curves.easeOutCubic,
                                heightFactor: safeProgress,
                                widthFactor: 1,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            accent.withValues(alpha: 0.58),
                                            accent.withValues(alpha: 0.88),
                                          ],
                                        ),
                                      ),
                                    ),
                                    CustomPaint(
                                      painter: _WaterWavePainter(
                                        phase: wavePhase,
                                        color: Colors.white
                                            .withValues(alpha: 0.35),
                                      ),
                                    ),
                                    CustomPaint(
                                      painter: _WaterBubblePainter(
                                        phase: wavePhase,
                                        color: Colors.white,
                                        fillProgress: safeProgress,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.72),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  percentText,
                                  style:
                                      AppTextStyles.caption(context).copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (showDrop)
                Positioned(
                  top: 10 + (dropT * 56),
                  left: 38,
                  child: Opacity(
                    opacity: dropOpacity,
                    child: Icon(
                      Icons.water_drop,
                      size: 16,
                      color: accent,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWaterSection(BuildContext context, AppState app) {
    final manualIntake = app.manualDailyWaterIntakeMl(_selectedDate);
    final beverageIntake = app.beverageHydrationIntakeMl(_selectedDate);
    final intake = app.dailyWaterIntakeMl(_selectedDate);
    final target = app.dailyWaterTargetMl(_selectedDate);
    final beverageEntries = app.beverageHydrationEntries(_selectedDate);
    final progress = (target <= 0 ? 0.0 : (intake / target)).clamp(0.0, 1.0);
    final remaining = math.max(0, target - intake);
    final smartFillMl = remaining;
    final showBeverageChip = beverageIntake > 0;
    final selectedOption = _selectedWaterQuickOption;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWaterBottle(context, progress: progress),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isZh ? '今日喝水' : 'Today Water',
                      style: AppTextStyles.body(context).copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      switchInCurve: Curves.easeOutBack,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) {
                        final offsetTween = Tween<Offset>(
                          begin: const Offset(0, 0.14),
                          end: Offset.zero,
                        );
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: offsetTween.animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        '$intake / $target ml',
                        key: ValueKey('water-$intake-$target'),
                        style: AppTextStyles.title2(context).copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isZh ? '還差 $remaining ml' : 'Remaining $remaining ml',
                      style: AppTextStyles.caption(context)
                          .copyWith(color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildWaterMetricChip(
                          context,
                          icon: Icons.water_drop_outlined,
                          label: _isZh ? '手動' : 'Manual',
                          value: '$manualIntake ml',
                        ),
                        if (showBeverageChip)
                          _buildWaterMetricChip(
                            context,
                            icon: Icons.local_drink_outlined,
                            label: _isZh ? '飲料' : 'Beverage',
                            value: '$beverageIntake ml',
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_useSimpleWaterControls) ...[
                      Text(
                        _isZh ? '快速加水' : 'Quick add',
                        style: AppTextStyles.caption(context).copyWith(
                          color: Colors.black54,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _waterQuickOptions.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) => _buildWaterQuickPill(
                            context,
                            index: index,
                            option: _waterQuickOptions[index],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.black.withValues(alpha: 0.03),
                        ),
                        child: Text(
                          _isZh
                              ? '目前選擇：${selectedOption.labelZh} +${selectedOption.ml} ml'
                              : 'Selected: ${selectedOption.labelEn} +${selectedOption.ml} ml',
                          style: AppTextStyles.caption(context).copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: AppTextStyles.body(context).copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          onPressed: () =>
                              _addWaterByAmount(app, selectedOption.ml),
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          label: Text(
                            _isZh
                                ? '加入 +${selectedOption.ml} ml'
                                : 'Add +${selectedOption.ml} ml',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () => _showWaterMoreActionsSheet(
                            context,
                            app,
                            smartFillMl,
                          ),
                          icon: const Icon(Icons.tune_rounded, size: 18),
                          label: Text(_isZh ? '更多操作' : 'More actions'),
                        ),
                      ),
                    ] else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isZh ? '常用容器' : 'Quick containers',
                            style: AppTextStyles.caption(context).copyWith(
                              color: Colors.black54,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.08),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.18),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${_isZh ? selectedOption.labelZh : selectedOption.labelEn} +${selectedOption.ml} ml',
                                  style: AppTextStyles.body(context).copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onHorizontalDragUpdate:
                                      _onWaterShutterDragUpdate,
                                  onHorizontalDragEnd: (_) =>
                                      _waterDragDelta = 0,
                                  onHorizontalDragCancel: () =>
                                      _waterDragDelta = 0,
                                  onTap: () =>
                                      _addWaterByAmount(app, selectedOption.ml),
                                  onLongPressStart: (_) {
                                    _addWaterByAmount(app, selectedOption.ml);
                                    _startWaterRepeat(app);
                                  },
                                  onLongPressEnd: (_) => _stopWaterRepeat(),
                                  onLongPressCancel: _stopWaterRepeat,
                                  child: Center(
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 180),
                                      curve: Curves.easeOutCubic,
                                      width: 118,
                                      height: 118,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.66),
                                          width: 2,
                                        ),
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.74),
                                            Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.28),
                                            blurRadius: 18,
                                            offset: const Offset(0, 9),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.water_drop_rounded,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '+${selectedOption.ml} ml',
                                            style: AppTextStyles.title2(context)
                                                .copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _isZh ? '點一下加入' : 'Tap to add',
                                            style:
                                                AppTextStyles.caption(context)
                                                    .copyWith(
                                              color: Colors.white
                                                  .withValues(alpha: 0.84),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _isZh
                                      ? '左右滑動切換容量，長按可連續加水'
                                      : 'Swipe to switch. Long press to repeat.',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.caption(context)
                                      .copyWith(color: Colors.black54),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  height: 40,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: _waterQuickOptions.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 8),
                                    itemBuilder: (context, index) =>
                                        _buildWaterQuickPill(
                                      context,
                                      index: index,
                                      option: _waterQuickOptions[index],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (smartFillMl > 0)
                            SizedBox(
                              width: double.infinity,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.28),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(52),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    textStyle:
                                        AppTextStyles.body(context).copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  onPressed: () =>
                                      _addWaterByAmount(app, smartFillMl),
                                  icon: const Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 19,
                                  ),
                                  label: Text(
                                    _isZh
                                        ? '補滿 +$smartFillMl ml'
                                        : 'Top up +$smartFillMl ml',
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(46),
                                    shape: const StadiumBorder(),
                                  ),
                                  onPressed: () =>
                                      _showCustomWaterInputDialog(context, app),
                                  icon:
                                      const Icon(Icons.edit_outlined, size: 18),
                                  label: Text(_isZh ? '自訂容量' : 'Custom'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              PopupMenuButton<_WaterManualAction>(
                                tooltip: _isZh ? '更多操作' : 'More actions',
                                onSelected: (action) async {
                                  if (action != _WaterManualAction.clear) {
                                    return;
                                  }
                                  final confirm =
                                      await _confirmClearManualWater(context);
                                  if (!confirm || !mounted) return;
                                  await app.updateDailyWaterIntake(
                                    _selectedDate,
                                    0,
                                  );
                                },
                                itemBuilder: (menuContext) => [
                                  PopupMenuItem<_WaterManualAction>(
                                    value: _WaterManualAction.clear,
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _isZh
                                              ? '清空手動補水'
                                              : 'Clear manual water',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                child: Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(23),
                                  ),
                                  child: const Icon(
                                    Icons.more_horiz,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isZh ? '今日飲料補水明細' : 'Beverage hydration timeline',
                style: AppTextStyles.body(context)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (beverageEntries.isEmpty)
                Text(
                  _isZh ? '今天還沒有飲料紀錄。' : 'No beverage entries today.',
                  style: AppTextStyles.caption(context)
                      .copyWith(color: Colors.black54),
                )
              else
                Column(
                  children: [
                    for (final item in beverageEntries.take(8))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(
                                  Icons.local_drink_outlined,
                                  size: 18,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.body(context)
                                          .copyWith(
                                              fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_timeLabel(item.time)} | ${item.estimatedVolumeMl} ml | ${_isZh ? '係數' : 'ratio'} ${(item.hydrationRatio * 100).round()}%',
                                      style: AppTextStyles.caption(context)
                                          .copyWith(color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '+${item.effectiveMl} ml',
                                    style: AppTextStyles.body(context).copyWith(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      _hydrationSourceLabel(item.sourceTag),
                                      style: AppTextStyles.caption(context)
                                          .copyWith(
                                              fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _addWaterByAmount(AppState app, int ml) async {
    if (ml <= 0) return;
    await app.addDailyWaterIntake(_selectedDate, ml);
    if (!mounted) return;
    _waterDropController
      ..stop()
      ..reset()
      ..forward();
  }

  Future<void> _showWaterMoreActionsSheet(
    BuildContext context,
    AppState app,
    int smartFillMl,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 8),
                if (smartFillMl > 0)
                  ListTile(
                    leading: const Icon(Icons.bolt_outlined),
                    title: Text(
                      _isZh ? '補滿 +$smartFillMl ml' : 'Top up +$smartFillMl ml',
                    ),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _addWaterByAmount(app, smartFillMl);
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: Text(_isZh ? '自訂容量' : 'Custom amount'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _showCustomWaterInputDialog(context, app);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: Text(
                    _isZh ? '清空手動補水' : 'Clear manual water',
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    final confirm = await _confirmClearManualWater(context);
                    if (!confirm || !mounted) return;
                    await app.updateDailyWaterIntake(_selectedDate, 0);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _confirmClearManualWater(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_isZh ? '清空手動補水？' : 'Clear manual water?'),
        content: Text(
          _isZh
              ? '只會清空手動補水，不會刪除飲料補水紀錄。'
              : 'Only manual water is cleared. Beverage hydration stays.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(_isZh ? '取消' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(_isZh ? '清空' : 'Clear'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _showCustomWaterInputDialog(
      BuildContext context, AppState app) async {
    final controller = TextEditingController();
    final input = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(_isZh ? '自訂喝水容量 (ml)' : 'Custom water amount (ml)'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: _isZh ? '例如 420' : 'e.g. 420',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(_isZh ? '取消' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final parsed = int.tryParse(controller.text.trim());
                if (parsed == null) return;
                Navigator.of(dialogContext).pop(parsed.clamp(50, 2000));
              },
              child: Text(_isZh ? '加入' : 'Add'),
            ),
          ],
        );
      },
    );
    if (!mounted || input == null) return;
    await _addWaterByAmount(app, input);
  }

  Future<void> _showWeightInputDialog(
      BuildContext context, AppState app) async {
    final initial = app.dailyWeightRecordKg(_selectedDate) ??
        app.latestWeightBaselineKg(_selectedDate);
    final controller = TextEditingController(text: initial.toStringAsFixed(1));
    final input = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(_isZh ? '輸入體重（kg）' : 'Enter Weight (kg)'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: _isZh ? '例如 68.5' : 'e.g. 68.5',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(_isZh ? '取消' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final parsed = double.tryParse(controller.text.trim());
                if (parsed == null || parsed <= 0) return;
                Navigator.of(dialogContext).pop(parsed);
              },
              child: Text(_isZh ? '儲存' : 'Save'),
            ),
          ],
        );
      },
    );
    if (input == null) return;
    await app.updateDailyWeightRecordKg(_selectedDate, input);
  }

  Future<void> _adjustWeightForDate(AppState app, double delta) async {
    final base = app.dailyWeightRecordKg(_selectedDate) ??
        app.latestWeightBaselineKg(_selectedDate);
    final next = (base + delta).clamp(20.0, 300.0);
    await app.updateDailyWeightRecordKg(_selectedDate, next);
  }

  Widget _buildWeightStatChip(
    BuildContext context, {
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption(context)
                .copyWith(color: Colors.black54, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.caption(context).copyWith(
              color: valueColor ?? Colors.black87,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightSection(BuildContext context, AppState app) {
    final theme = Theme.of(context);
    final recorded = app.dailyWeightRecordKg(_selectedDate);
    final baseline = app.latestWeightBaselineKg(_selectedDate);
    final displayWeight = recorded ?? baseline;

    double? previousWeight;
    for (var i = 1; i <= 30; i++) {
      final probe =
          app.dailyWeightRecordKg(_selectedDate.subtract(Duration(days: i)));
      if (probe != null) {
        previousWeight = probe;
        break;
      }
    }

    final trendRaw = app.recentWeightRecords(_selectedDate, days: 7);
    final trendMap = <String, double>{
      for (final point in trendRaw)
        '${point.key.year}-${point.key.month}-${point.key.day}': point.value,
    };
    final trendPoints = List<_HistoryPoint>.generate(7, (index) {
      final day = _selectedDate.subtract(Duration(days: 6 - index));
      final key = '${day.year}-${day.month}-${day.day}';
      return _HistoryPoint(date: day, value: trendMap[key]);
    });
    final trendValues = trendPoints
        .where((point) => point.value != null)
        .map((point) => point.value!)
        .toList(growable: false);

    final avgWeight = trendValues.isEmpty
        ? null
        : trendValues.reduce((a, b) => a + b) / trendValues.length;
    final minWeight = trendValues.isEmpty ? null : trendValues.reduce(math.min);
    final maxWeight = trendValues.isEmpty ? null : trendValues.reduce(math.max);

    final deltaPrev =
        previousWeight == null ? null : (displayWeight - previousWeight);
    final deltaAvg = avgWeight == null ? null : (displayWeight - avgWeight);
    final deltaRef = deltaPrev ?? deltaAvg ?? 0.0;
    final isStable = deltaRef.abs() < 0.05;
    final trendColor = isStable
        ? Colors.black54
        : (deltaRef > 0 ? Colors.deepOrange : const Color(0xFF2B8F6A));
    final trendLabel = isStable
        ? (_isZh ? '持平中' : 'Stable')
        : (deltaRef > 0
            ? (_isZh ? '上升中' : 'Trending up')
            : (_isZh ? '下降中' : 'Trending down'));

    String deltaText(double? value) {
      if (value == null) return _isZh ? '暫無資料' : 'N/A';
      final sign = value > 0 ? '+' : '';
      return '$sign${value.toStringAsFixed(1)} kg';
    }

    final gaugeMin = (minWeight ?? displayWeight) - 0.6;
    final gaugeMax = (maxWeight ?? displayWeight) + 0.6;
    final gaugeProgress = gaugeMax <= gaugeMin
        ? 0.5
        : ((displayWeight - gaugeMin) / (gaugeMax - gaugeMin)).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 84,
                height: 190,
                child: Column(
                  children: [
                    Icon(Icons.monitor_weight_outlined,
                        color: theme.colorScheme.primary, size: 22),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: gaugeProgress,
                                widthFactor: 1,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        theme.colorScheme.primary
                                            .withValues(alpha: 0.5),
                                        theme.colorScheme.primary,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.78),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${(gaugeProgress * 100).round()}%',
                                  style: AppTextStyles.caption(context)
                                      .copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isZh ? '今日體重' : 'Today Weight',
                      style: AppTextStyles.body(context)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${displayWeight.toStringAsFixed(1)} kg',
                      style: AppTextStyles.title2(context),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: trendColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            trendLabel,
                            style: AppTextStyles.caption(context).copyWith(
                              color: trendColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildWeightStatChip(
                          context,
                          label: _isZh ? '較昨天' : 'vs yesterday',
                          value: deltaText(deltaPrev),
                          valueColor: deltaPrev == null
                              ? Colors.black87
                              : (deltaPrev > 0
                                  ? Colors.deepOrange
                                  : const Color(0xFF2B8F6A)),
                        ),
                        _buildWeightStatChip(
                          context,
                          label: _isZh ? '較7日均值' : 'vs 7-day avg',
                          value: deltaText(deltaAvg),
                          valueColor: deltaAvg == null
                              ? Colors.black87
                              : (deltaAvg > 0
                                  ? Colors.deepOrange
                                  : const Color(0xFF2B8F6A)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isZh ? '近7天趨勢' : 'Last 7 days trend',
                style: AppTextStyles.body(context)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (trendValues.isEmpty)
                Text(
                  _isZh ? '還沒有體重資料。' : 'No weight data yet.',
                  style: AppTextStyles.caption(context)
                      .copyWith(color: Colors.black54),
                )
              else ...[
                SizedBox(
                  height: 140,
                  child: _CalorieHistoryChart(
                    points: trendPoints,
                    lineColor: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildWeightStatChip(
                      context,
                      label: _isZh ? '最低' : 'Min',
                      value:
                          '${(minWeight ?? displayWeight).toStringAsFixed(1)} kg',
                    ),
                    _buildWeightStatChip(
                      context,
                      label: _isZh ? '平均' : 'Avg',
                      value:
                          '${(avgWeight ?? displayWeight).toStringAsFixed(1)} kg',
                    ),
                    _buildWeightStatChip(
                      context,
                      label: _isZh ? '最高' : 'Max',
                      value:
                          '${(maxWeight ?? displayWeight).toStringAsFixed(1)} kg',
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isZh ? '快速記錄' : 'Quick actions',
                style: AppTextStyles.body(context)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => _adjustWeightForDate(app, -0.1),
                    child: const Text('-0.1'),
                  ),
                  OutlinedButton(
                    onPressed: () => _adjustWeightForDate(app, 0.1),
                    child: const Text('+0.1'),
                  ),
                  FilledButton.tonal(
                    onPressed: () => _showWeightInputDialog(context, app),
                    child: Text(_isZh ? '手動輸入' : 'Input'),
                  ),
                  TextButton(
                    onPressed: () =>
                        app.updateDailyWeightRecordKg(_selectedDate, null),
                    child: Text(_isZh ? '清除今日' : 'Clear today'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _quickRecord(
    BuildContext context,
    AppState app, {
    bool preferNameInput = false,
  }) async {
    final t = AppLocalizations.of(context)!;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(_currentMonth.year - 1),
      lastDate: DateTime(_currentMonth.year + 1),
    );
    if (!context.mounted || pickedDate == null) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now()),
    );
    if (!context.mounted || pickedTime == null) return;
    final overrideTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    final result = await showRecordSheet(
      context,
      app,
      overrideTime: overrideTime,
    );
    if (!context.mounted || result == null) return;
    setState(() {
      _selectedDate =
          DateTime(overrideTime.year, overrideTime.month, overrideTime.day);
      _currentMonth = DateTime(overrideTime.year, overrideTime.month, 1);
      _currentMonthDays = _daysInMonth(_currentMonth);
      _lastJumpKey = '';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.logSuccess)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final app = AppStateScope.of(context);
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppTheme>()!;
    var effectiveDate = _selectedDate;
    var effectiveMonth = _currentMonth;
    var effectiveDays = _currentMonthDays;
    var groupsByType = app.mealGroupsByTypeForDate(effectiveDate);
    var hasAnyGroup = groupsByType.values.any((groups) => groups.isNotEmpty);
    if (_activeSection == _LogSection.meals &&
        !hasAnyGroup &&
        app.entries.isNotEmpty) {
      final latest =
          app.entries.reduce((a, b) => a.time.isAfter(b.time) ? a : b);
      effectiveDate =
          DateTime(latest.time.year, latest.time.month, latest.time.day);
      effectiveMonth = DateTime(effectiveDate.year, effectiveDate.month, 1);
      effectiveDays = _daysInMonth(effectiveMonth);
      groupsByType = app.mealGroupsByTypeForDate(effectiveDate);
      hasAnyGroup = groupsByType.values.any((groups) => groups.isNotEmpty);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _selectedDate = effectiveDate;
        _currentMonth = effectiveMonth;
        _currentMonthDays = effectiveDays;
        _lastJumpKey = '';
      });
    }
    final days = effectiveDays;
    if (!app.trialChecked && app.isSupabaseSignedIn) {
      return AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: _buildSkeleton(),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: _activeSection == _LogSection.meals
            ? Padding(
                padding: EdgeInsets.only(bottom: _fabBottomPadding(context)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'log_quick_name_fab',
                      onPressed: () => _quickRecord(
                        context,
                        app,
                        preferNameInput: true,
                      ),
                      child: const Icon(Icons.edit_note),
                    ),
                    const SizedBox(height: 10),
                    FloatingActionButton(
                      heroTag: 'log_quick_record_fab',
                      onPressed: () => _quickRecord(context, app),
                      child: const Icon(Icons.add),
                    ),
                  ],
                ),
              )
            : null,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(_withEmoji('📔', t.logTitle),
                        style: AppTextStyles.title1(context)),
                    const SizedBox(height: 10),
                    _buildSectionSwitcher(context),
                    const SizedBox(height: 12),
                    if (_activeSection == _LogSection.meals) ...[
                      _buildTopCards(context, app, t, appTheme, theme),
                      const SizedBox(height: 16),
                    ],
                    _buildMonthHeader(context, app),
                    const SizedBox(height: 6),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final viewportWidth = constraints.maxWidth;
                        final jumpKey =
                            '${_currentMonth.year}-${_currentMonth.month}-${_selectedDate.day}-${days.length}';
                        if (_lastJumpKey != jumpKey) {
                          _lastJumpKey = jumpKey;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            _jumpToSelected(
                                _selectedDate, viewportWidth, days.length);
                          });
                        }
                        return SizedBox(
                          height: 92,
                          child: NotificationListener<ScrollEndNotification>(
                            onNotification: (_) {
                              if (_isSnapping) return false;
                              _snapToClosest(app, viewportWidth, days);
                              return false;
                            },
                            child: AnimatedBuilder(
                              animation: _dateController,
                              builder: (context, child) {
                                final extent = _dateItemExtent();
                                final leading = _leadingPadding(viewportWidth);
                                final center = _dateController.hasClients
                                    ? _dateController.offset + viewportWidth / 2
                                    : viewportWidth / 2;
                                final centerIndex = _centerIndexForOffset(
                                  _dateController.hasClients
                                      ? _dateController.offset
                                      : 0,
                                  viewportWidth,
                                  days.length,
                                );
                                return ListView.builder(
                                  controller: _dateController,
                                  scrollDirection: Axis.horizontal,
                                  itemCount: days.length,
                                  padding:
                                      EdgeInsets.symmetric(horizontal: leading),
                                  itemBuilder: (context, index) {
                                    final itemCenter =
                                        leading + index * extent + extent / 2;
                                    final distance =
                                        (center - itemCenter).abs();
                                    final factor =
                                        (distance / extent).clamp(0.0, 1.0);
                                    final scale = 1.1 - 0.16 * factor;
                                    return _buildDateCard(
                                      context,
                                      app,
                                      t,
                                      days[index],
                                      scale: scale,
                                      isCentered: index == centerIndex,
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_activeSection == _LogSection.meals) ...[
                      _mealSection(context, app, MealType.breakfast,
                          groupsByType[MealType.breakfast] ?? const []),
                      _mealSection(context, app, MealType.brunch,
                          groupsByType[MealType.brunch] ?? const []),
                      _mealSection(context, app, MealType.lunch,
                          groupsByType[MealType.lunch] ?? const []),
                      _mealSection(context, app, MealType.afternoonTea,
                          groupsByType[MealType.afternoonTea] ?? const []),
                      _mealSection(context, app, MealType.dinner,
                          groupsByType[MealType.dinner] ?? const []),
                      _mealSection(context, app, MealType.lateSnack,
                          groupsByType[MealType.lateSnack] ?? const []),
                      _mealSection(context, app, MealType.other,
                          groupsByType[MealType.other] ?? const []),
                      if (!hasAnyGroup)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Colors.black45,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  t.noEntries,
                                  style: AppTextStyles.caption(context)
                                      .copyWith(color: Colors.black54),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ] else if (_activeSection == _LogSection.water)
                      _buildWaterSection(context, app)
                    else
                      _buildWeightSection(context, app),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryPoint {
  final DateTime date;
  final double? value;

  const _HistoryPoint({required this.date, required this.value});
}

class _WaterWavePainter extends CustomPainter {
  const _WaterWavePainter({
    required this.phase,
    required this.color,
  });

  final double phase;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final amplitude = math.max(2.0, size.height * 0.045);
    final midY = size.height * 0.18;
    final path = Path()..moveTo(0, midY);

    for (double x = 0; x <= size.width; x += 1.0) {
      final y =
          midY + math.sin((x / size.width) * math.pi * 2 + phase) * amplitude;
      path.lineTo(x, y);
    }

    path
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WaterWavePainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.color != color;
  }
}

class _WaterBubblePainter extends CustomPainter {
  const _WaterBubblePainter({
    required this.phase,
    required this.color,
    required this.fillProgress,
  });

  final double phase;
  final Color color;
  final double fillProgress;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || fillProgress <= 0.01) return;

    final normalizedPhase = (phase / (math.pi * 2)).remainder(1.0);
    const specs = <_WaterBubbleSpec>[
      _WaterBubbleSpec(x: 0.20, offset: 0.00, radius: 2.8, speed: 0.70),
      _WaterBubbleSpec(x: 0.34, offset: 0.16, radius: 2.1, speed: 0.88),
      _WaterBubbleSpec(x: 0.50, offset: 0.36, radius: 3.2, speed: 0.62),
      _WaterBubbleSpec(x: 0.66, offset: 0.58, radius: 2.4, speed: 0.95),
      _WaterBubbleSpec(x: 0.80, offset: 0.79, radius: 1.9, speed: 1.10),
    ];

    for (final spec in specs) {
      final rawT =
          ((normalizedPhase * spec.speed) + spec.offset).remainder(1.0);
      final rise = Curves.easeOut.transform(rawT);
      final y = size.height - (size.height * rise);
      final sway = math.sin((rawT * math.pi * 2) + spec.offset * 7) * 3.4;
      final x = (size.width * spec.x + sway)
          .clamp(spec.radius + 1, size.width - spec.radius - 1)
          .toDouble();
      final alpha = (0.08 + (1 - rawT) * 0.20) * (0.45 + fillProgress * 0.55);
      final bubblePaint = Paint()
        ..color = color.withValues(alpha: alpha.clamp(0.06, 0.30))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), spec.radius, bubblePaint);

      final highlightPaint = Paint()
        ..color = Colors.white.withValues(
          alpha: (alpha * 0.8).clamp(0.04, 0.22),
        )
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(x - spec.radius * 0.28, y - spec.radius * 0.28),
        spec.radius * 0.34,
        highlightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaterBubblePainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.color != color ||
        oldDelegate.fillProgress != fillProgress;
  }
}

class _CalorieHistoryChart extends StatelessWidget {
  const _CalorieHistoryChart({
    required this.points,
    required this.lineColor,
    this.targetMin,
    this.targetMax,
    this.targetLabel,
  });

  final List<_HistoryPoint> points;
  final Color lineColor;
  final double? targetMin;
  final double? targetMax;
  final String? targetLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth.toDouble()
            : 0.0;
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight.toDouble()
            : 0.0;
        return CustomPaint(
          size: Size(width, height),
          painter: _CalorieHistoryPainter(
            points: points,
            lineColor: lineColor,
            targetMin: targetMin,
            targetMax: targetMax,
            targetLabel: targetLabel,
          ),
        );
      },
    );
  }
}

class _CalorieHistoryPainter extends CustomPainter {
  _CalorieHistoryPainter({
    required this.points,
    required this.lineColor,
    this.targetMin,
    this.targetMax,
    this.targetLabel,
  });

  final List<_HistoryPoint> points;
  final Color lineColor;
  final double? targetMin;
  final double? targetMax;
  final String? targetLabel;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final nonNull = points.where((p) => p.value != null).toList();
    if (nonNull.isEmpty) return;

    var minValue = nonNull.first.value!;
    var maxValue = nonNull.first.value!;
    for (final point in nonNull.skip(1)) {
      final value = point.value!;
      minValue = math.min(minValue, value);
      maxValue = math.max(maxValue, value);
    }

    final range = (maxValue - minValue).abs();
    final paddingValue =
        range == 0 ? math.max(10, maxValue * 0.12) : range * 0.2;
    final minY = minValue - paddingValue;
    final maxY = maxValue + paddingValue;
    final chartRect = Rect.fromLTWH(
      6,
      4,
      size.width - 12,
      size.height - 10,
    );

    final xStep =
        points.length > 1 ? chartRect.width / (points.length - 1) : 0.0;

    final segments = <List<Offset>>[];
    var current = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final value = points[i].value;
      if (value == null) {
        if (current.isNotEmpty) {
          segments.add(current);
          current = <Offset>[];
        }
        continue;
      }
      final x = chartRect.left + xStep * i;
      final t = ((value - minY) / (maxY - minY)).clamp(0.0, 1.0);
      final y = chartRect.bottom - t * chartRect.height;
      current.add(Offset(x, y));
    }
    if (current.isNotEmpty) segments.add(current);

    final areaPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          lineColor.withValues(alpha: 0.28),
          lineColor.withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(chartRect)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final segment in segments) {
      if (segment.length == 1) {
        canvas.drawCircle(
            segment.first, 3, linePaint..style = PaintingStyle.fill);
        linePaint.style = PaintingStyle.stroke;
        continue;
      }
      final path = _smoothPath(segment);
      final areaPath = Path.from(path)
        ..lineTo(segment.last.dx, chartRect.bottom)
        ..lineTo(segment.first.dx, chartRect.bottom)
        ..close();
      canvas.drawPath(areaPath, areaPaint);
      canvas.drawPath(path, linePaint);
    }

    _drawTargetLines(canvas, chartRect, minY, maxY);

    _drawHighLowLabels(canvas, chartRect, minY, maxY);
  }

  void _drawTargetLines(
      Canvas canvas, Rect chartRect, double minY, double maxY) {
    if (targetMin == null || targetMax == null) return;
    final paint = Paint()
      ..color = Colors.black26
      ..strokeWidth = 1;
    final minT = ((targetMin! - minY) / (maxY - minY)).clamp(0.0, 1.0);
    final maxT = ((targetMax! - minY) / (maxY - minY)).clamp(0.0, 1.0);
    final yMin = chartRect.bottom - minT * chartRect.height;
    final yMax = chartRect.bottom - maxT * chartRect.height;
    if ((yMin - yMax).abs() < 0.5) {
      _drawDashedLine(canvas, Offset(chartRect.left, yMin),
          Offset(chartRect.right, yMin), paint);
    } else {
      _drawDashedLine(canvas, Offset(chartRect.left, yMin),
          Offset(chartRect.right, yMin), paint);
      _drawDashedLine(canvas, Offset(chartRect.left, yMax),
          Offset(chartRect.right, yMax), paint);
    }

    if (targetLabel == null) return;
    final textPainter = TextPainter(
      text: TextSpan(
        text: targetLabel,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.black45,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: chartRect.width);
    final labelY = ((yMin + yMax) / 2) - textPainter.height / 2;
    textPainter.paint(canvas, Offset(chartRect.left, labelY));
  }

  void _drawHighLowLabels(
      Canvas canvas, Rect chartRect, double minY, double maxY) {
    double? minValue;
    double? maxValue;
    int? minIndex;
    int? maxIndex;
    for (var i = 0; i < points.length; i++) {
      final value = points[i].value;
      if (value == null) continue;
      if (minValue == null || value < minValue) {
        minValue = value;
        minIndex = i;
      }
      if (maxValue == null || value > maxValue) {
        maxValue = value;
        maxIndex = i;
      }
    }
    if (minValue == null || maxValue == null) return;
    final xStep =
        points.length > 1 ? chartRect.width / (points.length - 1) : 0.0;
    final minT = ((minValue - minY) / (maxY - minY)).clamp(0.0, 1.0);
    final maxT = ((maxValue - minY) / (maxY - minY)).clamp(0.0, 1.0);
    final minPoint = Offset(
      chartRect.left + xStep * (minIndex ?? 0),
      chartRect.bottom - minT * chartRect.height,
    );
    final maxPoint = Offset(
      chartRect.left + xStep * (maxIndex ?? 0),
      chartRect.bottom - maxT * chartRect.height,
    );

    final fillPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    void drawPoint(Offset p) {
      canvas.drawCircle(p, 5, fillPaint);
      canvas.drawCircle(p, 5, strokePaint);
    }

    drawPoint(maxPoint);
    if (minIndex != maxIndex) drawPoint(minPoint);

    _drawValueLabel(canvas, chartRect, maxPoint, maxValue.round().toString(),
        isAbove: true);
    if (minIndex != maxIndex) {
      _drawValueLabel(canvas, chartRect, minPoint, minValue.round().toString(),
          isAbove: false);
    }
  }

  void _drawValueLabel(Canvas canvas, Rect chartRect, Offset point, String text,
      {required bool isAbove}) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    var dx = point.dx - painter.width / 2;
    dx = dx.clamp(chartRect.left, chartRect.right - painter.width);
    final dy = isAbove ? point.dy - painter.height - 6 : point.dy + 6;
    painter.paint(canvas, Offset(dx, dy));
  }

  Path _smoothPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    if (points.length < 2) return path;
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = i == 0 ? points[i] : points[i - 1];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = (i + 2 < points.length) ? points[i + 2] : p2;

      final cp1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
      );
      final cp2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
      );
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }
    return path;
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 4.0;
    const dashGap = 4.0;
    final distance = (end.dx - start.dx).abs();
    var x = start.dx;
    while (x < start.dx + distance) {
      final x2 = math.min(x + dashWidth, start.dx + distance);
      canvas.drawLine(Offset(x, start.dy), Offset(x2, start.dy), paint);
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _CalorieHistoryPainter oldDelegate) {
    if (oldDelegate.lineColor != lineColor) return true;
    if (oldDelegate.targetMin != targetMin ||
        oldDelegate.targetMax != targetMax ||
        oldDelegate.targetLabel != targetLabel) {
      return true;
    }
    if (oldDelegate.points.length != points.length) return true;
    for (var i = 0; i < points.length; i++) {
      final oldPoint = oldDelegate.points[i];
      final newPoint = points[i];
      if (oldPoint.value != newPoint.value ||
          !oldPoint.date.isAtSameMomentAs(newPoint.date)) {
        return true;
      }
    }
    return false;
  }
}
