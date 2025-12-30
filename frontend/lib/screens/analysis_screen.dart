import 'package:flutter/material.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import '../state/app_state.dart';
import '../models/analysis_result.dart';

enum MacroLevel { low, medium, high }

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  MacroLevel _levelFromValue(String value) {
    final v = value.toLowerCase();
    if (v.contains('高') || v.contains('high')) return MacroLevel.high;
    if (v.contains('低') || v.contains('low')) return MacroLevel.low;
    return MacroLevel.medium;
  }

  Color _levelColor(MacroLevel level) {
    switch (level) {
      case MacroLevel.low:
        return const Color(0xFF8AD7A4);
      case MacroLevel.medium:
        return const Color(0xFFF4C95D);
      case MacroLevel.high:
        return const Color(0xFFF08A7C);
    }
  }

  String _levelLabel(MacroLevel level, AppLocalizations t) {
    switch (level) {
      case MacroLevel.low:
        return t.levelLow;
      case MacroLevel.medium:
        return t.levelMedium;
      case MacroLevel.high:
        return t.levelHigh;
    }
  }

  List<String> _overallTags(AnalysisResult result, AppLocalizations t) {
    final tags = <String>[];
    final fat = _levelFromValue(result.macros['fat'] ?? '');
    final protein = _levelFromValue(result.macros['protein'] ?? '');
    final carbs = _levelFromValue(result.macros['carbs'] ?? '');

    if (fat == MacroLevel.high) tags.add(t.tagOily);
    if (protein == MacroLevel.high) tags.add(t.tagProteinOk);
    if (protein == MacroLevel.low) tags.add(t.tagProteinLow);
    if (carbs == MacroLevel.high) tags.add(t.tagCarbHigh);
    if (tags.isEmpty) tags.add(t.tagOk);
    return tags.take(3).toList();
  }

  String _statusLabel(AnalysisResult result, AppLocalizations t) {
    int score = 0;
    final fat = _levelFromValue(result.macros['fat'] ?? '');
    final protein = _levelFromValue(result.macros['protein'] ?? '');
    final carbs = _levelFromValue(result.macros['carbs'] ?? '');
    if (fat == MacroLevel.high) score += 1;
    if (carbs == MacroLevel.high) score += 1;
    if (protein == MacroLevel.low) score += 1;
    if (score >= 2) return t.statusOver;
    if (score == 1) return t.statusWarn;
    return t.statusOk;
  }

  Color _statusColor(String label, AppLocalizations t) {
    if (label == t.statusOver) return const Color(0xFFF08A7C);
    if (label == t.statusWarn) return const Color(0xFFF4C95D);
    return const Color(0xFF8AD7A4);
  }

  Widget _macroChip(String label, MacroLevel level, AppLocalizations t) {
    final color = _levelColor(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          Text(_levelLabel(level, t), style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final app = AppStateScope.of(context);
    final entry = app.latestEntry;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(t.analysisTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                if (entry == null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(t.analysisEmpty, style: const TextStyle(color: Colors.black54)),
                  ),
                if (entry != null)
                  Container(
                    padding: const EdgeInsets.all(12),
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
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(entry.image, height: 200, width: double.infinity, fit: BoxFit.cover),
                        ),
                        const SizedBox(height: 12),
                        if (entry.loading)
                          const Center(child: CircularProgressIndicator())
                        else if (entry.error != null)
                          Text(entry.error!, style: const TextStyle(color: Colors.red))
                        else if (entry.result != null) ...[
                          Row(
                            children: [
                              Text(t.overallLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 8),
                              Builder(
                                builder: (context) {
                                  final label = _statusLabel(entry.result!, t);
                                  final color = _statusColor(label, t);
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(label, style: TextStyle(fontSize: 11, color: color)),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final tag in _overallTags(entry.result!, t))
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF3FF),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(tag, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F8FC),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.local_fire_department, color: Color(0xFFF4C95D)),
                                const SizedBox(width: 8),
                                Text(
                                  '${t.calorieLabel}：${entry.result!.calorieRange}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(t.macroLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _macroChip(t.protein, _levelFromValue(entry.result!.macros['protein'] ?? ''), t),
                              _macroChip(t.carbs, _levelFromValue(entry.result!.macros['carbs'] ?? ''), t),
                              _macroChip(t.fat, _levelFromValue(entry.result!.macros['fat'] ?? ''), t),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(entry.result!.suggestion, style: const TextStyle(color: Colors.black54)),
                        ],
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
