import 'package:flutter/material.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import 'package:intl/intl.dart';
import '../state/app_state.dart';
import '../models/meal_entry.dart';
import 'meal_detail_screen.dart';
import '../widgets/record_sheet.dart';

class LogScreen extends StatelessWidget {
  const LogScreen({super.key});

  Widget _mealRow(BuildContext context, AppState app, MealEntry entry) {
    final t = AppLocalizations.of(context)!;
    final prefix = _mockPrefix(entry, t);
    final foodName = entry.overrideFoodName ?? entry.result?.foodName ?? t.unknownFood;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MealDetailScreen(entry: entry))),
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
                    '${t.timeLabel}：${_timeLabel(entry.time, t)} · ${prefix}${entry.result?.calorieRange ?? t.calorieUnknown}',
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

  String _timeLabel(DateTime time, AppLocalizations t) {
    final locale = t.localeName;
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

  String _mealAdviceLine(List<MealEntry> entries, AppLocalizations t) {
    int proteinLow = 0;
    int fatHigh = 0;
    int carbHigh = 0;
    int sodiumHigh = 0;
    for (final entry in entries) {
      final result = entry.result;
      if (result == null) continue;
      final fat = result.macros['fat'] ?? '';
      final protein = result.macros['protein'] ?? '';
      final carbs = result.macros['carbs'] ?? '';
      final sodium = result.macros['sodium'] ?? '';
      if (protein.contains(t.levelLow) || protein.toLowerCase().contains('low')) proteinLow++;
      if (fat.contains(t.levelHigh) || fat.toLowerCase().contains('high')) fatHigh++;
      if (carbs.contains(t.levelHigh) || carbs.toLowerCase().contains('high')) carbHigh++;
      if (sodium.contains(t.levelHigh) || sodium.toLowerCase().contains('high')) sodiumHigh++;
    }
    final advice = <String>[];
    if (proteinLow > 0) advice.add(t.dietitianProteinLow);
    if (fatHigh > 0) advice.add(t.dietitianFatHigh);
    if (carbHigh > 0) advice.add(t.dietitianCarbHigh);
    if (sodiumHigh > 0) advice.add(t.dietitianSodiumHigh);
    final line = advice.isEmpty ? t.dietitianBalanced : advice.take(2).join('；');
    return '${t.dietitianPrefix}$line';
  }

  String _mockPrefix(MealEntry entry, AppLocalizations t) {
    return entry.result?.source == 'mock' ? '${t.mockPrefix} ' : '';
  }

  Widget _mealSection(
    BuildContext context,
    AppState app,
    MealType type,
    List<MealEntry> entries,
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
          if (entries.isEmpty)
            Text(t.noMealPrompt, style: const TextStyle(color: Colors.black54)),
          if (entries.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(_mealAdviceLine(entries, t), style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 8),
            Column(
              children: [
                for (final entry in entries) _mealRow(context, app, entry),
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
                  _mealSection(
                    context,
                    app,
                    MealType.breakfast,
                    app.entriesForDate(date).where((e) => e.type == MealType.breakfast).toList(),
                  ),
                  _mealSection(
                    context,
                    app,
                    MealType.lunch,
                    app.entriesForDate(date).where((e) => e.type == MealType.lunch).toList(),
                  ),
                  _mealSection(
                    context,
                    app,
                    MealType.dinner,
                    app.entriesForDate(date).where((e) => e.type == MealType.dinner).toList(),
                  ),
                  _mealSection(
                    context,
                    app,
                    MealType.lateSnack,
                    app.entriesForDate(date).where((e) => e.type == MealType.lateSnack).toList(),
                  ),
                  _mealSection(
                    context,
                    app,
                    MealType.other,
                    app.entriesForDate(date).where((e) => e.type == MealType.other).toList(),
                  ),
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
