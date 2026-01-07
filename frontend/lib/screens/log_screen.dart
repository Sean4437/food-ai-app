import 'package:flutter/material.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import 'package:intl/intl.dart';
import '../state/app_state.dart';
import '../models/meal_entry.dart';
import 'meal_items_screen.dart';
import '../widgets/record_sheet.dart';

class LogScreen extends StatelessWidget {
  const LogScreen({super.key});

  String _timeLabel(DateTime time) {
    return '${time.month}/${time.day} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _mealLabel(MealType type, AppLocalizations t) {
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
                  Text('${prefix}${foodName}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    '${t.timeLabel}: ${_timeLabel(entry.time)} · ${portion} · ${prefix}${entry.result?.calorieRange ?? t.calorieUnknown}',
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
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
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('${t.mealTotal}: $calorie', style: const TextStyle(color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 4),
          Text(advice, style: const TextStyle(color: Colors.black54, fontSize: 12)),
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
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton(
                onPressed: () => showRecordSheet(context, app, fixedType: type),
                child: Text(t.addMeal),
              ),
            ],
          ),
          if (groups.isEmpty)
            Text(t.noMealPrompt, style: const TextStyle(color: Colors.black54)),
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

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(t.logTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                for (final date in displayDates) ...[
                  Text(
                    dateFormatter.format(date),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
                        Text(t.dailyCalorieRange, style: const TextStyle(color: Colors.black54)),
                        const SizedBox(height: 6),
                        Text(
                          app.dailyCalorieRangeLabelForDate(date, t),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _mealSection(context, app, MealType.breakfast, app.mealGroupsForDate(date, MealType.breakfast)),
                  _mealSection(context, app, MealType.lunch, app.mealGroupsForDate(date, MealType.lunch)),
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
    );
  }
}
