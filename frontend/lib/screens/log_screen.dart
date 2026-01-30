import 'package:flutter/material.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import 'package:intl/intl.dart';
import '../state/app_state.dart';
import '../models/meal_entry.dart';
import 'meal_items_screen.dart';
import '../widgets/record_sheet.dart';
import '../widgets/app_background.dart';
import '../design/text_styles.dart';

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
  String _lastJumpKey = '';
  bool _isSnapping = false;

  static const double _dateItemWidth = 78;
  static const double _dateItemGap = 6;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _currentMonth = DateTime(now.year, now.month, 1);
    _currentMonthDays = _daysInMonth(_currentMonth);
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
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

  double? _entryCalorieMid(MealEntry entry) {
    final range = _parseCalorieRange(entry.result?.calorieRange ?? '');
    if (range == null) return null;
    final weight = (entry.portionPercent) / 100.0;
    return ((range[0] + range[1]) / 2.0) * weight;
  }

  MealEntry? _topMealLast7Days(AppState app) {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 7));
    MealEntry? best;
    double bestScore = -1;
    for (final entry in app.entries) {
      if (entry.time.isBefore(cutoff)) continue;
      final score = _entryCalorieMid(entry);
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
    return List.generate(lastDay, (i) => DateTime(month.year, month.month, i + 1));
  }

  bool _isSameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;

  DateTime _defaultSelectedDateForMonth(AppState app, DateTime month) {
    final today = DateTime.now();
    if (_isSameMonth(today, month)) {
      return DateTime(today.year, today.month, today.day);
    }
    final dates = app.entries
        .where((entry) => entry.time.year == month.year && entry.time.month == month.month)
        .map((entry) => DateTime(entry.time.year, entry.time.month, entry.time.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    return dates.isNotEmpty ? dates.first : DateTime(month.year, month.month, 1);
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

  Widget _buildHighlightCard(BuildContext context, AppState app, AppLocalizations t) {
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
        child: Text(t.logTopMealEmpty, style: AppTextStyles.caption(context).copyWith(color: Colors.black54)),
      );
    }

    final title = _entryTitle(entry, t);
    final mid = _entryCalorieMid(entry);
    final kcalText = mid == null ? t.calorieUnknown : '${mid.round()} kcal';
    final dateLabel = '${entry.time.month}/${entry.time.day}';
    final mealLabel = _mealLabel(entry.type, t);

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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.logTopMealTitle, style: AppTextStyles.caption(context).copyWith(color: Colors.black54)),
                const SizedBox(height: 6),
                Text(title, style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(kcalText, style: AppTextStyles.title2(context).copyWith(fontWeight: FontWeight.w700)),
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
          const SizedBox(width: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(entry.imageBytes, width: 72, height: 72, fit: BoxFit.cover),
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
      child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF3C6F5B), fontWeight: FontWeight.w600)),
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
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Text(
            formatter.format(_currentMonth),
            textAlign: TextAlign.center,
            style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          onPressed: () => _shiftMonth(app, 1),
          icon: const Icon(Icons.chevron_right),
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
    final index = _centerIndexForOffset(_dateController.offset, viewportWidth, days.length);
    final target = _offsetForIndex(index, viewportWidth).clamp(0.0, _dateController.position.maxScrollExtent);
    final date = days[index];
    if (date.year != _selectedDate.year || date.month != _selectedDate.month || date.day != _selectedDate.day) {
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
    final target = _offsetForIndex(index, viewportWidth).clamp(0.0, _dateController.position.maxScrollExtent);
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
    final selectedLabel = hasData ? app.dailyCalorieRangeLabelForDate(date, t) : '—';
    final idleLabel = hasData ? _dailyAverageNumber(app, t, date) : '—';
    final bgColor = isCentered ? Theme.of(context).colorScheme.primary : Colors.transparent;
    final fgColor = isCentered ? Colors.white : (hasData ? Colors.black87 : Colors.black38);
    final borderColor = isCentered ? Colors.transparent : Colors.black12;
    return SizedBox(
      width: _dateItemExtent(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _dateItemGap, vertical: 4),
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
                Text('${date.month}/${date.day}', style: TextStyle(color: fgColor, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(isCentered ? selectedLabel : idleLabel, style: TextStyle(color: fgColor, fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _mealRow(BuildContext context, AppState app, MealEntry entry, List<MealEntry> group) {
    final t = AppLocalizations.of(context)!;
    final summary = _entryTitle(entry, t);
    final calorie = app.entryCalorieRangeLabel(entry, t);
    final tags = entry.result?.judgementTags ?? const <String>[];
    return GestureDetector(
      onTap: () {
        final initialIndex = group.indexOf(entry);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MealItemsScreen(
              group: group,
              initialIndex: initialIndex >= 0 ? (group.length - 1 - initialIndex) : null,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                entry.imageBytes,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(_timeLabel(entry.time), style: AppTextStyles.caption(context).copyWith(color: Colors.black54)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(summary, style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600)),
                      ),
                      Text(calorie, style: AppTextStyles.caption(context).copyWith(color: Colors.black54)),
                    ],
                  ),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(tags.join(' · '), style: AppTextStyles.caption(context).copyWith(color: Colors.black45)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mealSection(BuildContext context, AppState app, MealType type, List<List<MealEntry>> groups) {
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
          Text(_mealLabel(type, t), style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600)),
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
      _selectedDate = DateTime(overrideTime.year, overrideTime.month, overrideTime.day);
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
    final days = _currentMonthDays;
    final groupsByType = app.mealGroupsByTypeForDate(_selectedDate);
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(t.logTitle, style: AppTextStyles.title1(context)),
                    const SizedBox(height: 12),
                    _buildHighlightCard(context, app, t),
                    const SizedBox(height: 16),
                    _buildMonthHeader(context, app),
                    const SizedBox(height: 6),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final viewportWidth = constraints.maxWidth;
                        final jumpKey = '${_currentMonth.year}-${_currentMonth.month}-${_selectedDate.day}-${days.length}';
                        if (_lastJumpKey != jumpKey) {
                          _lastJumpKey = jumpKey;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            _jumpToSelected(_selectedDate, viewportWidth, days.length);
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
                                  _dateController.hasClients ? _dateController.offset : 0,
                                  viewportWidth,
                                  days.length,
                                );
                                return ListView.builder(
                                  controller: _dateController,
                                  scrollDirection: Axis.horizontal,
                                  itemCount: days.length,
                                  padding: EdgeInsets.symmetric(horizontal: leading),
                                  itemBuilder: (context, index) {
                                    final itemCenter = leading + index * extent + extent / 2;
                                    final distance = (center - itemCenter).abs();
                                    final factor = (distance / extent).clamp(0.0, 1.0);
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
                    _mealSection(context, app, MealType.breakfast, groupsByType[MealType.breakfast] ?? const []),
                    _mealSection(context, app, MealType.brunch, groupsByType[MealType.brunch] ?? const []),
                    _mealSection(context, app, MealType.lunch, groupsByType[MealType.lunch] ?? const []),
                    _mealSection(context, app, MealType.afternoonTea, groupsByType[MealType.afternoonTea] ?? const []),
                    _mealSection(context, app, MealType.dinner, groupsByType[MealType.dinner] ?? const []),
                    _mealSection(context, app, MealType.lateSnack, groupsByType[MealType.lateSnack] ?? const []),
                    _mealSection(context, app, MealType.other, groupsByType[MealType.other] ?? const []),
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
