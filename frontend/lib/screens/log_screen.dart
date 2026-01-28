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

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _currentMonth = DateTime(now.year, now.month, 1);
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
    if (result.foodItems.isNotEmpty) return result.foodItems.join(' + ');
    final summary = result.dishSummary?.trim();
    if (summary != null && summary.isNotEmpty) return summary;
    return result.foodName.isNotEmpty ? result.foodName : t.unknownFood;
  }

  List<DateTime> _daysInMonth(DateTime month) {
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    return List.generate(lastDay, (i) => DateTime(month.year, month.month, i + 1));
  }

  bool _isSameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;

  void _shiftMonth(int delta) {
    setState(() {
      final next = DateTime(_currentMonth.year, _currentMonth.month + delta, 1);
      _currentMonth = next;
      if (!_isSameMonth(_selectedDate, next)) {
        final today = DateTime.now();
        if (_isSameMonth(today, next)) {
          _selectedDate = DateTime(today.year, today.month, today.day);
        } else {
          _selectedDate = DateTime(next.year, next.month, 1);
        }
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

  Widget _buildMonthHeader(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final isZh = locale.startsWith('zh');
    final formatter = DateFormat(isZh ? 'yyyy年M月' : 'MMM yyyy', locale);
    return Row(
      children: [
        IconButton(
          onPressed: () => _shiftMonth(-1),
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
          onPressed: () => _shiftMonth(1),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Widget _buildDateCard(BuildContext context, AppState app, AppLocalizations t, DateTime date) {
    final isSelected = date.year == _selectedDate.year && date.month == _selectedDate.month && date.day == _selectedDate.day;
    final hasData = app.entriesForDate(date).isNotEmpty;
    final calorieLabel = hasData ? app.dailyCalorieRangeLabelForDate(date, t) : '—';
    final bgColor = isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent;
    final fgColor = isSelected ? Colors.white : (hasData ? Colors.black87 : Colors.black38);
    final borderColor = isSelected ? Colors.transparent : Colors.black12;

    return GestureDetector(
      onTap: () => setState(() => _selectedDate = date),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
            Text(calorieLabel, style: TextStyle(color: fgColor, fontSize: 11)),
          ],
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
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MealItemsScreen(group: group))),
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
    );
  }

  Widget _mealSection(BuildContext context, AppState app, MealType type, List<List<MealEntry>> groups) {
    final t = AppLocalizations.of(context)!;
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
          if (groups.isEmpty)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => showRecordSheet(context, app, fixedType: type),
                icon: const Icon(Icons.add, size: 18),
                label: Text(t.logAddMealPrompt),
              ),
            )
          else
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final app = AppStateScope.of(context);
    final days = _daysInMonth(_currentMonth);

    return AppBackground(
      child: SafeArea(
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
                  _buildMonthHeader(context),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 86,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: days.length,
                      itemBuilder: (context, index) => _buildDateCard(context, app, t, days[index]),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _mealSection(context, app, MealType.breakfast, app.mealGroupsForDate(_selectedDate, MealType.breakfast)),
                  _mealSection(context, app, MealType.brunch, app.mealGroupsForDate(_selectedDate, MealType.brunch)),
                  _mealSection(context, app, MealType.lunch, app.mealGroupsForDate(_selectedDate, MealType.lunch)),
                  _mealSection(context, app, MealType.afternoonTea, app.mealGroupsForDate(_selectedDate, MealType.afternoonTea)),
                  _mealSection(context, app, MealType.dinner, app.mealGroupsForDate(_selectedDate, MealType.dinner)),
                  _mealSection(context, app, MealType.lateSnack, app.mealGroupsForDate(_selectedDate, MealType.lateSnack)),
                  _mealSection(context, app, MealType.other, app.mealGroupsForDate(_selectedDate, MealType.other)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
