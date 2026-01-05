import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import '../models/meal_entry.dart';
import '../state/app_state.dart';

class MealDetailScreen extends StatelessWidget {
  const MealDetailScreen({super.key, required this.entry});

  final MealEntry entry;

  Future<void> _editTime(BuildContext context) async {
    final app = AppStateScope.of(context);
    final date = await showDatePicker(
      context: context,
      initialDate: entry.time,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(entry.time),
    );
    if (time == null) return;
    final updated = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    app.updateEntryTime(entry, updated);
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    final app = AppStateScope.of(context);
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
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  String _aiSummary(MealEntry entry, AppLocalizations t) {
    final fat = entry.result?.macros['fat'] ?? '';
    final protein = entry.result?.macros['protein'] ?? '';
    final carbs = entry.result?.macros['carbs'] ?? '';
    final sodium = entry.result?.macros['sodium'] ?? '';
    final parts = <String>[];
    if (fat.contains(t.levelHigh) || fat.toLowerCase().contains('high')) parts.add(t.tagOily);
    if (protein.contains(t.levelHigh) || protein.toLowerCase().contains('high')) parts.add(t.tagProteinOk);
    if (protein.contains(t.levelLow) || protein.toLowerCase().contains('low')) parts.add(t.tagProteinLow);
    if (carbs.contains(t.levelHigh) || carbs.toLowerCase().contains('high')) parts.add(t.tagCarbHigh);
    if (sodium.contains(t.levelHigh) || sodium.toLowerCase().contains('high')) parts.add(t.dietitianSodiumHigh);
    if (parts.isEmpty) return t.dietitianBalanced;
    return parts.take(3).join('、');
  }

  Future<void> _editFoodName(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    final app = AppStateScope.of(context);
    final controller = TextEditingController(text: entry.overrideFoodName ?? entry.result?.foodName ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.editFoodName),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: t.foodNameLabel),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(t.cancel)),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(controller.text.trim()), child: Text(t.save)),
        ],
      ),
    );
    if (result != null) {
      final locale = Localizations.localeOf(context).toLanguageTag();
      await app.updateEntryFoodName(entry, result, locale);
    }
  }

  double _ratioFromValue(String value) {
    final v = value.toLowerCase();
    if (v.contains('高') || v.contains('high')) return 0.8;
    if (v.contains('低') || v.contains('low')) return 0.3;
    return 0.55;
  }

  Widget _ratioBar(String label, double ratio, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 10,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _portionSelector(BuildContext context, AppState app, AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${entry.portionPercent}%', style: const TextStyle(fontWeight: FontWeight.w600)),
        Slider(
          value: entry.portionPercent.toDouble(),
          min: 10,
          max: 100,
          divisions: 9,
          label: '${entry.portionPercent}%',
          onChanged: (value) {
            app.updateEntryPortionPercent(entry, value.round());
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final app = AppStateScope.of(context);
    final mealGroup = app.entriesForMeal(entry);
    final mealSummary = app.buildMealSummary(mealGroup, t);
    final formatter = DateFormat('yyyy/MM/dd HH:mm', Localizations.localeOf(context).toLanguageTag());
    final prefix = entry.result?.source == 'mock' ? '${t.mockPrefix} ' : '';

    return Scaffold(
      appBar: AppBar(
        title: Text(t.detailTitle),
        backgroundColor: const Color(0xFFF3F5FB),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _editTime(context),
            icon: const Icon(Icons.edit),
            tooltip: t.editTime,
          ),
          IconButton(
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline),
            tooltip: t.delete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Transform.rotate(
                    angle: -0.12,
                    child: Container(
                      width: 340,
                      height: 340,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          center: Alignment(-0.25, -0.45),
                          radius: 1.0,
                          colors: [Color(0xFFFFFFFF), Color(0xFFE9EEF5)],
                          stops: [0.6, 1.0],
                        ),
                        border: Border.all(color: Colors.black.withOpacity(0.1), width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 24,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const RadialGradient(
                                    center: Alignment(-0.2, -0.4),
                                    radius: 0.95,
                                    colors: [Color(0xFFFFFFFF), Color(0xFFF0F3F9)],
                                    stops: [0.55, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.all(22),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const RadialGradient(
                                    center: Alignment(0.0, 0.3),
                                    radius: 0.9,
                                    colors: [Color(0xFFF8FAFD), Color(0xFFDDE4EE)],
                                    stops: [0.4, 1.0],
                                  ),
                                  border: Border.all(color: const Color(0xFFE2E8F1), width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 10,
                                      spreadRadius: -4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withOpacity(0.75), width: 4),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 22,
                            top: 16,
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.55),
                              ),
                            ),
                          ),
                          Center(
                            child: ClipOval(
                              child: Image.memory(
                                entry.imageBytes,
                                width: 240,
                                height: 240,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(formatter.format(entry.time), style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 8),
                Text(t.portionLabel, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 6),
                _portionSelector(context, app, t),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.mealSummaryTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(
                        mealSummary?.advice ?? t.detailAiEmpty,
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${t.mealTotal}: ${mealSummary?.calorieRange ?? t.calorieUnknown}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (entry.result != null) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${prefix}${entry.overrideFoodName ?? entry.result!.foodName}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _editFoodName(context),
                              icon: const Icon(Icons.edit, size: 18),
                              tooltip: t.editFoodName,
                            ),
                          ],
                        ),
                      ],
                      Text(t.detailAiLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      if (entry.error != null)
                        Text(entry.error!, style: const TextStyle(color: Colors.red))
                      else
                        Text(_aiSummary(entry, t), style: const TextStyle(color: Colors.black54)),
                      if (entry.result != null) ...[
                        const SizedBox(height: 6),
                        Text('source: ${entry.result!.source}', style: const TextStyle(fontSize: 11, color: Colors.black45)),
                      ],
                      const SizedBox(height: 12),
                      Text(t.detailWhyLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      if (entry.result != null) ...[
                        _ratioBar(t.protein, _ratioFromValue(entry.result!.macros['protein'] ?? ''), const Color(0xFF8AD7A4)),
                        const SizedBox(height: 10),
                        _ratioBar(t.carbs, _ratioFromValue(entry.result!.macros['carbs'] ?? ''), const Color(0xFFF4C95D)),
                        const SizedBox(height: 10),
                        _ratioBar(t.fat, _ratioFromValue(entry.result!.macros['fat'] ?? ''), const Color(0xFFF08A7C)),
                        const SizedBox(height: 10),
                        if ((entry.result!.macros['sodium'] ?? '').isNotEmpty) ...[
                          _ratioBar(t.sodium, _ratioFromValue(entry.result!.macros['sodium'] ?? ''), const Color(0xFF8AB4F8)),
                          const SizedBox(height: 10),
                        ],
                        Text('${t.calorieLabel}: ${prefix}${entry.result!.calorieRange}', style: const TextStyle(color: Colors.black54)),
                      ] else
                        Text(t.detailAiEmpty, style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (entry.result != null) ...[
                        Text('${prefix}${entry.result!.foodName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                      ],
                      Text(t.nextMealTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text('${prefix}${entry.result?.suggestion ?? t.nextMealHint}', style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
