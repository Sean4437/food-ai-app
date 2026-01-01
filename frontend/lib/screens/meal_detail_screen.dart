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

  double _ratioFromValue(String value) {
    final v = value.toLowerCase();
    if (v.contains('\u9ad8') || v.contains('high')) return 0.8;
    if (v.contains('\u4f4e') || v.contains('low')) return 0.3;
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.memory(entry.imageBytes, height: 220, fit: BoxFit.cover),
                ),
                const SizedBox(height: 12),
                Text(formatter.format(entry.time), style: const TextStyle(color: Colors.black54)),
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
                        Text('${prefix}${entry.result!.foodName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                      ],
                      Text(t.detailAiLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text('${prefix}${entry.result?.suggestion ?? t.detailAiEmpty}', style: const TextStyle(color: Colors.black54)),
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
                        Text('${t.calorieLabel}：${prefix}${entry.result!.calorieRange}', style: const TextStyle(color: Colors.black54)),
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
                      Text(t.nextMealHint, style: const TextStyle(color: Colors.black54)),
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