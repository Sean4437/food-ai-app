import 'package:flutter/material.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import 'package:intl/intl.dart';
import '../state/app_state.dart';
import '../models/meal_entry.dart';
import 'meal_items_screen.dart';
import '../widgets/record_sheet.dart';
import '../widgets/app_background.dart';
import '../design/text_styles.dart';

class LogScreen extends StatelessWidget {
  const LogScreen({super.key});

  String _weekdayLabel(DateTime date, AppLocalizations t) {
    switch (date.weekday) {
      case DateTime.monday:
        return t.weekdayMon;
      case DateTime.tuesday:
        return t.weekdayTue;
      case DateTime.wednesday:
        return t.weekdayWed;
      case DateTime.thursday:
        return t.weekdayThu;
      case DateTime.friday:
        return t.weekdayFri;
      case DateTime.saturday:
        return t.weekdaySat;
      case DateTime.sunday:
        return t.weekdaySun;
    }
    return t.weekdayMon;
  }

  List<int>? _parseCalorieRange(String text) {
    final match = RegExp(r'(\d+)\s*-\s*(\d+)').firstMatch(text);
    if (match == null) return null;
    final min = int.tryParse(match.group(1) ?? '');
    final max = int.tryParse(match.group(2) ?? '');
    if (min == null || max == null) return null;
    return [min, max];
  }

  _TopMealInfo? _weeklyTopMeal(AppState app, AppLocalizations t) {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 7));
    final recent = app.entries.where((entry) => entry.time.isAfter(cutoff)).toList();
    if (recent.isEmpty) return null;
    final dates = recent
        .map((entry) => DateTime(entry.time.year, entry.time.month, entry.time.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    _TopMealInfo? best;
    double bestScore = -1;
    for (final date in dates) {
      for (final type in MealType.values) {
        final groups = app.mealGroupsForDate(date, type);
        for (final group in groups) {
          final summary = app.buildMealSummary(group, t);
          if (summary == null) continue;
          final range = _parseCalorieRange(summary.calorieRange);
          if (range == null) continue;
          final score = (range[0] + range[1]) / 2.0;
          if (score > bestScore) {
            bestScore = score;
            best = _TopMealInfo(
              date: date,
              type: type,
              timeLabel: _groupTimeLabel(group),
              calorieRange: summary.calorieRange,
            );
          }
        }
      }
    }
    return best;
  }

  String _timeLabel(DateTime time) {
    return '${time.month}/${time.day} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
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
      default:
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

  String _mockPrefix(MealEntry entry, AppLocalizations t) {
    return entry.result?.source == 'mock' ? '${t.mockPrefix} ' : '';
  }

  Widget _mealRow(BuildContext context, AppState app, MealEntry entry, List<MealEntry> group) {
    final t = AppLocalizations.of(context)!;
    final prefix = _mockPrefix(entry, t);
    final foodName = entry.overrideFoodName ?? entry.result?.foodName ?? t.unknownFood;
    final portion = '${t.portionLabel} ${entry.portionPercent}%';
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MealItemsScreen(group: group))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(entry.imageBytes, width: 72, height: 72, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${prefix}${foodName}', style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    '${t.timeLabel}: ${_timeLabel(entry.time)} · ${portion} · ${prefix}${entry.result?.calorieRange ?? t.calorieUnknown}',
                    style: AppTextStyles.caption(context).copyWith(color: Colors.black54),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.black45),
              onPressed: () => _confirmDelete(context, app, entry),
              tooltip: t.delete,
            ),
            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }

  Widget _mealGroupCard(BuildContext context, AppState app, List<MealEntry> group) {
    final t = AppLocalizations.of(context)!;
    final summary = app.buildMealSummary(group, t);
    final title = '${t.mealSummaryTitle} · ${_groupTimeLabel(group)}';
    final calorie = summary?.calorieRange ?? t.calorieUnknown;
    final advice = summary?.advice ?? t.detailAiEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.caption(context).copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('${t.mealTotal}: $calorie', style: AppTextStyles.caption(context).copyWith(color: Colors.black54)),
          const SizedBox(height: 4),
          Text(advice, style: AppTextStyles.caption(context).copyWith(color: Colors.black54)),
          const SizedBox(height: 10),
          Column(children: [for (final entry in group) _mealRow(context, app, entry, group)]),
        ],
      ),
    );
  }

  Widget _mealSection(
    BuildContext context,
    AppState app,
    MealType type,
    List<List<MealEntry>> groups,
  ) {
    final t = AppLocalizations.of(context)!;
    final title = _mealLabel(type, t);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton(
                onPressed: () => showRecordSheet(context, app, fixedType: type),
                child: Text(t.addMeal),
              ),
            ],
          ),
          if (groups.isEmpty)
            Text(t.noMealPrompt, style: AppTextStyles.caption(context).copyWith(color: Colors.black54)),
          if (groups.isNotEmpty) ...[
            const SizedBox(height: 8),
            Column(
              children: [
                for (final group in groups) _mealGroupCard(context, app, group),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, AppState app, MealEntry entry) async {
    final t = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.delete),
        content: Text(t.deleteConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(t.cancel)),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: Text(t.delete)),
        ],
      ),
    );
    if (result == true) {
      app.removeEntry(entry);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final app = AppStateScope.of(context);
    final entries = app.entries;
    final dateFormatter = DateFormat('yyyy/MM/dd', Localizations.localeOf(context).toLanguageTag());
    final dates = entries
        .map((e) => DateTime(e.time.year, e.time.month, e.time.day))
        .toSet()
        .toList();
    dates.sort((a, b) => b.compareTo(a));
    final displayDates = dates.isEmpty ? [DateTime.now()] : dates;
    final topMeal = _weeklyTopMeal(app, t);

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
                if (topMeal != null) ...[
                  Container(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.weekTopMealTitle, style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text(
                          '${_weekdayLabel(topMeal.date, t)} · ${_mealLabel(topMeal.type, t)} · ${topMeal.timeLabel} · ${topMeal.calorieRange}',
                          style: AppTextStyles.caption(context).copyWith(color: Colors.black54),
                        ),
                        const SizedBox(height: 10),
                        Text(t.recentGuidanceTitle, style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text(
                          app.weekSummaryText(DateTime.now(), t),
                          style: AppTextStyles.caption(context).copyWith(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                for (final date in displayDates) ...[
                  Text(
                    dateFormatter.format(date),
                    style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.dailyCalorieRange, style: AppTextStyles.caption(context).copyWith(color: Colors.black54)),
                        const SizedBox(height: 6),
                        Text(
                          app.dailyCalorieRangeLabelForDate(date, t),
                          style: AppTextStyles.title2(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _mealSection(context, app, MealType.breakfast, app.mealGroupsForDate(date, MealType.breakfast)),
                  _mealSection(context, app, MealType.brunch, app.mealGroupsForDate(date, MealType.brunch)),
                  _mealSection(context, app, MealType.lunch, app.mealGroupsForDate(date, MealType.lunch)),
                  _mealSection(context, app, MealType.afternoonTea, app.mealGroupsForDate(date, MealType.afternoonTea)),
                  _mealSection(context, app, MealType.dinner, app.mealGroupsForDate(date, MealType.dinner)),
                  _mealSection(context, app, MealType.lateSnack, app.mealGroupsForDate(date, MealType.lateSnack)),
                  _mealSection(context, app, MealType.other, app.mealGroupsForDate(date, MealType.other)),
                  const SizedBox(height: 16),
                ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopMealInfo {
  _TopMealInfo({
    required this.date,
    required this.type,
    required this.timeLabel,
    required this.calorieRange,
  });

  final DateTime date;
  final MealType type;
  final String timeLabel;
  final String calorieRange;
}
