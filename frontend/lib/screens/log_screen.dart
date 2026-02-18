import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import 'package:intl/intl.dart';
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

class _LogScreenState extends State<LogScreen> {
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

  static const double _dateItemWidth = 78;
  static const double _dateItemGap = 6;
  static const double _topCardHeight = 210;
  static const List<int> _historyDayOptions = [7, 14, 30];

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
            color: Colors.black12.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: 16),
        _skeletonBar(180),
        const SizedBox(height: 8),
        Container(
          height: 92,
          decoration: BoxDecoration(
            color: Colors.black12.withOpacity(0.4),
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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_historyDaysLoaded) return;
    final app = AppStateScope.of(context);
    final saved = app.profile.calorieHistoryDays;
    _historyDays =
        _historyDayOptions.contains(saved) ? saved : _historyDayOptions.first;
    _historyDaysLoaded = true;
  }

  @override
  void dispose() {
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
              color: Colors.black.withOpacity(0.05),
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
            color: Colors.black.withOpacity(0.05),
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
                entry.imageBytes,
                photoWidth: 88,
                showPlaceholder: app.isNamePlaceholderImage(entry.imageBytes),
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

  List<int>? _averageTargetRange(
      AppState app, DateTime endDate, int days) {
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
      final value = app.dailyProteinConsumedGrams(date,
          excludeBeverages: true);
      points.add(_HistoryPoint(
          date: date, value: value <= 0 ? null : value));
    }
    return points;
  }

  double? _averageProteinHistory(
    AppState app,
    DateTime endDate,
    int days,
  ) {
    final points = _buildProteinHistoryPoints(app, endDate, days);
    final values =
        points.map((p) => p.value).whereType<double>().toList();
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
    final values =
        points.map((p) => p.value).whereType<double>().toList();
    if (values.isEmpty) return null;
    final sum = values.reduce((a, b) => a + b);
    return sum / values.length;
  }

  String _proteinSummaryText(
    AppState app,
    AppLocalizations t,
  ) {
    final currentAvg = _averageProteinHistory(
        app, _selectedDate, _historyDays);
    if (currentAvg == null) {
      return t.proteinTrendSummaryNoData;
    }
    final previousEnd =
        _selectedDate.subtract(Duration(days: _historyDays));
    final previousAvg =
        _averageProteinHistory(app, previousEnd, _historyDays);
    final avgRounded = currentAvg.round();
    if (previousAvg == null || previousAvg <= 0) {
      return t.proteinTrendSummaryNoPrev(avgRounded.toString());
    }
    final diff =
        ((currentAvg - previousAvg) / previousAvg * 100).round();
    final periodLabel = _historyCompareLabel(t);
    if (diff == 0) {
      return t.proteinTrendSummarySame(
          avgRounded.toString(), periodLabel);
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
    final previousEnd =
        _selectedDate.subtract(Duration(days: _historyDays));
    final previousAvg =
        _averageHistoryValue(app, previousEnd, _historyDays, t);
    final avgRounded = currentAvg.round();
    if (previousAvg == null || previousAvg <= 0) {
      return t.calorieTrendSummaryNoPrev(avgRounded.toString());
    }
    final diff =
        ((currentAvg - previousAvg) / previousAvg * 100).round();
    final periodLabel = _historyCompareLabel(t);
    if (diff == 0) {
      return t.calorieTrendSummarySame(
          avgRounded.toString(), periodLabel);
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
    final borderColor = Colors.black.withOpacity(0.08);
    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EEE9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
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
    final textColor =
        selected ? theme.colorScheme.primary : Colors.black54;
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
                    color: Colors.black.withOpacity(0.12),
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
    final points =
        _buildHistoryPoints(app, _selectedDate, _historyDays, t);
    final hasData = points.any((p) => p.value != null);
    final targetRange =
        _averageTargetRange(app, _selectedDate, _historyDays);
    final targetLabel = targetRange == null
        ? null
        : t.calorieTrendTargetLabel(
            targetRange[0].toString(), targetRange[1].toString());
    final dateFormat = DateFormat('M/d');
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
                    Text(dateFormat.format(points.first.date),
                        style: AppTextStyles.caption(context)
                            .copyWith(color: Colors.black45)),
                    Text(dateFormat.format(points.last.date),
                        style: AppTextStyles.caption(context)
                            .copyWith(color: Colors.black45)),
                  ],
                ),
                const SizedBox(height: 4),
                Divider(height: 1, color: Colors.black12.withOpacity(0.6)),
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
    final points =
        _buildProteinHistoryPoints(app, _selectedDate, _historyDays);
    final hasData = points.any((p) => p.value != null);
    final targetMid = _proteinTargetMid(app);
    final targetLabel = targetMid == null
        ? null
        : t.proteinTrendTargetLabel(targetMid.round().toString());
    final dateFormat = DateFormat('M/d');
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
                    Text(dateFormat.format(points.first.date),
                        style: AppTextStyles.caption(context)
                            .copyWith(color: Colors.black45)),
                    Text(dateFormat.format(points.last.date),
                        style: AppTextStyles.caption(context)
                            .copyWith(color: Colors.black45)),
                  ],
                ),
                const SizedBox(height: 4),
                Divider(height: 1, color: Colors.black12.withOpacity(0.6)),
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
    BorderRadius? borderRadius,
    double radius = 0,
    required double photoWidth,
    bool showPlaceholder = false,
  }) {
    final resolvedRadius = borderRadius ?? BorderRadius.circular(radius);
    return SizedBox(
      width: photoWidth,
      child: ClipRRect(
        borderRadius: resolvedRadius,
        child: showPlaceholder
            ? Container(
                color: const Color(0xFFF0F4F2),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  color: Color(0xFF7A9A8B),
                  size: 26,
                ),
              )
            : Image.memory(
                bytes,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
      ),
    );
  }

  Widget _buildMonthHeader(BuildContext context, AppState app) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final isZh = locale.startsWith('zh');
    final formatter = DateFormat(isZh ? 'yyyy年M月' : 'MMM yyyy', locale);
    return Row(
      children: [
        IconButton(
          onPressed: () => _shiftMonth(app, -1),
          icon: const Icon(Icons.chevron_left, color: Colors.black45, size: 18),
        ),
        Expanded(
          child: Text(
            formatter.format(_currentMonth),
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
                Text('${date.month}/${date.day}',
                    style:
                        TextStyle(color: fgColor, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(isCentered ? selectedLabel : idleLabel,
                    style: TextStyle(color: fgColor, fontSize: 11)),
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
        final initialIndex = group.indexOf(entry);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MealItemsScreen(
              group: group,
              initialIndex:
                  initialIndex >= 0 ? (group.length - 1 - initialIndex) : null,
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
              color: Colors.black.withOpacity(0.04),
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
                  entry.imageBytes,
                  photoWidth: 92,
                  showPlaceholder: app.isNamePlaceholderImage(entry.imageBytes),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
                for (final entry in group) _mealRow(context, app, entry, group),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _quickRecord(BuildContext context, AppState app) async {
    final t = AppLocalizations.of(context)!;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(_currentMonth.year - 1),
      lastDate: DateTime(_currentMonth.year + 1),
    );
    if (!mounted || pickedDate == null) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now()),
    );
    if (!mounted || pickedTime == null) return;
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
    if (!mounted || result == null) return;
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
    final days = _currentMonthDays;
    final groupsByType = app.mealGroupsByTypeForDate(_selectedDate);
    if (!app.trialChecked) {
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
        floatingActionButton: FloatingActionButton(
          heroTag: 'log_quick_record_fab',
          onPressed: () => _quickRecord(context, app),
          child: const Icon(Icons.add),
        ),
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
                    const SizedBox(height: 12),
                    Builder(builder: (context) {
                      final overview = DailyOverviewCards(
                        date: _selectedDate,
                        app: app,
                        t: t,
                        appTheme: appTheme,
                        theme: theme,
                        onSelectActivityLevel: () => _selectActivityLevel(
                            context, app, _selectedDate, t),
                        onSelectExerciseType: () => _selectExerciseType(
                            context, app, _selectedDate, t),
                        onSelectExerciseMinutes: () => _selectExerciseMinutes(
                            context, app, _selectedDate, t),
                      );
                      final pages = [
                        overview.calorieCard(context),
                        _buildCalorieHistoryCard(
                            context, app, t, appTheme, theme),
                        overview.proteinCard(context),
                        _buildProteinHistoryCard(
                            context, app, t, appTheme, theme),
                        _buildHighlightCard(context, app, t),
                      ];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: _topCardHeight,
                            child: PageView.builder(
                              controller: _topCardController,
                              onPageChanged: (index) =>
                                  setState(() => _topCardIndex = index),
                              itemCount: pages.length,
                              itemBuilder: (context, index) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                child: pages[index],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _pageDots(pages.length),
                        ],
                      );
                    }),
                    const SizedBox(height: 16),
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

    final xStep = points.length > 1
        ? chartRect.width / (points.length - 1)
        : 0.0;

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
          lineColor.withOpacity(0.28),
          lineColor.withOpacity(0.0),
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
        canvas.drawCircle(segment.first, 3, linePaint..style = PaintingStyle.fill);
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
    final labelY =
        ((yMin + yMax) / 2) - textPainter.height / 2;
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
      if (minValue == null || value < minValue!) {
        minValue = value;
        minIndex = i;
      }
      if (maxValue == null || value > maxValue!) {
        maxValue = value;
        maxIndex = i;
      }
    }
    if (minValue == null || maxValue == null) return;
    final xStep = points.length > 1
        ? chartRect.width / (points.length - 1)
        : 0.0;
    final minT = ((minValue! - minY) / (maxY - minY)).clamp(0.0, 1.0);
    final maxT = ((maxValue! - minY) / (maxY - minY)).clamp(0.0, 1.0);
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

    _drawValueLabel(canvas, chartRect, maxPoint, maxValue!.round().toString(),
        isAbove: true);
    if (minIndex != maxIndex) {
      _drawValueLabel(canvas, chartRect, minPoint,
          minValue!.round().toString(),
          isAbove: false);
    }
  }

  void _drawValueLabel(Canvas canvas, Rect chartRect, Offset point,
      String text,
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
    final dy = isAbove
        ? point.dy - painter.height - 6
        : point.dy + 6;
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

  void _drawDashedLine(
      Canvas canvas, Offset start, Offset end, Paint paint) {
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

