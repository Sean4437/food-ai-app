import 'package:flutter/material.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import '../state/app_state.dart';
import '../models/analysis_result.dart';
import '../widgets/app_background.dart';
import '../design/text_styles.dart';

enum MacroLevel { low, medium, high }

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  MacroLevel _levelFromPercent(double value) {
    if (value >= 70) return MacroLevel.high;
    if (value <= 35) return MacroLevel.low;
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

  List<String> _overallTags(AppState app, AnalysisResult result, AppLocalizations t) {
    final tags = <String>[];
    final fat = _levelFromPercent(app.macroPercentFromResult(result, 'fat'));
    final protein = _levelFromPercent(app.macroPercentFromResult(result, 'protein'));
    final carbs = _levelFromPercent(app.macroPercentFromResult(result, 'carbs'));

    if (fat == MacroLevel.high) tags.add(t.tagOily);
    if (protein == MacroLevel.high) tags.add(t.tagProteinOk);
    if (protein == MacroLevel.low) tags.add(t.tagProteinLow);
    if (carbs == MacroLevel.high) tags.add(t.tagCarbHigh);
    if (tags.isEmpty) tags.add(t.tagOk);
    return tags.take(3).toList();
  }

  String _statusLabel(AppState app, AnalysisResult result, AppLocalizations t) {
    int score = 0;
    final fat = _levelFromPercent(app.macroPercentFromResult(result, 'fat'));
    final protein = _levelFromPercent(app.macroPercentFromResult(result, 'protein'));
    final carbs = _levelFromPercent(app.macroPercentFromResult(result, 'carbs'));
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

  Widget _macroChip(BuildContext context, String label, MacroLevel level, AppLocalizations t) {
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
          Text(label, style: AppTextStyles.caption(context).copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          Text(_levelLabel(level, t), style: AppTextStyles.caption(context).copyWith(color: Colors.black54)),
        ],
      ),
    );
  }

  List<Widget> _macroChips(BuildContext context, AppState app, AnalysisResult result, AppLocalizations t) {
    final items = <MapEntry<String, double>>[
      MapEntry(t.protein, app.macroPercentFromResult(result, 'protein')),
      MapEntry(t.carbs, app.macroPercentFromResult(result, 'carbs')),
      MapEntry(t.fat, app.macroPercentFromResult(result, 'fat')),
    ];
    final sodium = app.macroPercentFromResult(result, 'sodium');
    if (sodium > 0) {
      items.add(MapEntry(t.sodium, sodium));
    }
    return [
      for (final item in items)
        _macroChip(context, item.key, _levelFromPercent(item.value), t),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final app = AppStateScope.of(context);
    final entry = app.latestEntryAny;
    final prefix = entry?.result?.source == 'mock' ? '${t.mockPrefix} ' : '';


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
                  Text(t.analysisTitle, style: AppTextStyles.title1(context)),
                  const SizedBox(height: 12),
                  if (entry == null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(t.analysisEmpty, style: AppTextStyles.caption(context).copyWith(color: Colors.black54)),
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
                            child: Image.memory(entry.imageBytes, height: 200, width: double.infinity, fit: BoxFit.cover),
                          ),
                          const SizedBox(height: 12),
                          if (entry.loading)
                            const Center(child: CircularProgressIndicator())
                          else if (entry.error != null)
                            Text(entry.error!, style: AppTextStyles.caption(context).copyWith(color: Colors.red))
                          else if (entry.result != null) ...[
                            Text('${prefix}${entry.result!.foodName}', style: AppTextStyles.title2(context)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(t.overallLabel, style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600)),
                                const SizedBox(width: 8),
                                Builder(
                                  builder: (context) {
                                    final label = _statusLabel(app, entry.result!, t);
                                    final color = _statusColor(label, t);
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(label, style: AppTextStyles.caption(context).copyWith(color: color)),
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
                                for (final tag in _overallTags(app, entry.result!, t))
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF3FF),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(tag, style: AppTextStyles.caption(context).copyWith(fontWeight: FontWeight.w600)),
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
                                  const Text('🔥', style: TextStyle(fontSize: 18)),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${t.calorieLabel}: ${prefix}${entry.result!.calorieRange}',
                                    style: AppTextStyles.caption(context),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(t.macroLabel, style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _macroChips(context, app, entry.result!, t),
                            ),
                            const SizedBox(height: 12),
                            Text('${prefix}${entry.result!.suggestion}', style: AppTextStyles.caption(context).copyWith(color: Colors.black54)),
                            const SizedBox(height: 6),
                            Text('source: ${entry.result!.source}', style: AppTextStyles.caption(context).copyWith(color: Colors.black45)),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
