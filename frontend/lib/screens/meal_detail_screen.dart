import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:food_ai_app/gen/app_localizations.dart';
import '../models/meal_entry.dart';
import '../state/app_state.dart';
import '../widgets/plate_photo.dart';
import '../widgets/app_background.dart';
import '../design/text_styles.dart';

class MealDetailScreen extends StatelessWidget {
  const MealDetailScreen({super.key, required this.entry});

  final MealEntry entry;

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

  double _ratioFromPercent(double value) {
    final safe = value.clamp(0, 100).toDouble();
    return safe / 100.0;
  }

  String _displayValue(double percent) => '${percent.round()}%';

  Widget _nutrientValue(BuildContext context, String label, double value, double ratio, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          '$label ${_displayValue(value)}',
          style: AppTextStyles.caption(context).copyWith(color: Colors.black54),
        ),
      ],
    );
  }

  Widget _radarChart(BuildContext context, MealEntry entry, AppLocalizations t) {
    final protein = entry.result?.macros['protein'] ?? 55;
    final carbs = entry.result?.macros['carbs'] ?? 55;
    final fat = entry.result?.macros['fat'] ?? 55;
    final sodium = entry.result?.macros['sodium'] ?? 55;
    final proteinRatio = _ratioFromPercent(protein);
    final carbsRatio = _ratioFromPercent(carbs);
    final fatRatio = _ratioFromPercent(fat);
    final sodiumRatio = _ratioFromPercent(sodium);
    final values = [proteinRatio, carbsRatio, fatRatio, sodiumRatio];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        SizedBox(
          height: 160,
          child: CustomPaint(
            painter: _RadarPainter(values),
            child: Center(
              child: SizedBox(
                width: 130,
                height: 130,
                child: Stack(
                  children: [
                    Align(
                      alignment: const Alignment(0, -1.05),
                      child: _nutrientValue(
                        context,
                        t.protein,
                        protein,
                        proteinRatio,
                        Icons.eco,
                        const Color(0xFF7FCB99),
                      ),
                    ),
                    Align(
                      alignment: const Alignment(1.05, 0.1),
                      child: _nutrientValue(
                        context,
                        t.carbs,
                        carbs,
                        carbsRatio,
                        Icons.grass,
                        const Color(0xFFF1BE4B),
                      ),
                    ),
                    Align(
                      alignment: const Alignment(0, 1.05),
                      child: _nutrientValue(
                        context,
                        t.fat,
                        fat,
                        fatRatio,
                        Icons.local_pizza,
                        const Color(0xFFF08A7C),
                      ),
                    ),
                    Align(
                      alignment: const Alignment(-1.05, 0.1),
                      child: _nutrientValue(
                        context,
                        t.sodium,
                        sodium,
                        sodiumRatio,
                        Icons.opacity,
                        const Color(0xFF8AB4F8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _portionSelector(BuildContext context, AppState app, AppLocalizations t) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${entry.portionPercent}%', style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600)),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 8,
            activeTrackColor: theme.colorScheme.primary,
            inactiveTrackColor: theme.colorScheme.primary.withOpacity(0.2),
            thumbColor: theme.colorScheme.primary,
            overlayColor: theme.colorScheme.primary.withOpacity(0.12),
          ),
          child: Slider(
            value: entry.portionPercent.toDouble(),
            min: 10,
            max: 200,
            divisions: 19,
            label: '${entry.portionPercent}%',
            onChanged: (value) {
              app.updateEntryPortionPercent(entry, value.round());
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final app = AppStateScope.of(context);
    final theme = Theme.of(context);
    final plateAsset = app.profile.plateAsset.isEmpty ? kDefaultPlateAsset : app.profile.plateAsset;
    final mealGroup = app.entriesForMeal(entry);
    final mealSummary = app.buildMealSummary(mealGroup, t);
    final prefix = entry.result?.source == 'mock' ? '${t.mockPrefix} ' : '';

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(t.detailTitle),
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          actions: [
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
                  SizedBox(
                    height: 420,
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        Positioned(
                          top: 140,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(16, 130, 16, 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (entry.result != null) ...[
                                  Text(
                                    '${prefix}${entry.overrideFoodName ?? entry.result!.foodName}',
                                    style: AppTextStyles.title2(context),
                                  ),
                                  if ((entry.result!.dishSummary ?? '').trim().isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(entry.result!.dishSummary!, style: AppTextStyles.caption(context).copyWith(color: Colors.black54)),
                                  ],
                                ] else
                                  Text(t.unknownFood, style: AppTextStyles.title2(context)),
                                const SizedBox(height: 10),
                                Text('${t.portionLabel} ${entry.portionPercent}%', style: AppTextStyles.caption(context).copyWith(color: Colors.black54)),
                                const SizedBox(height: 6),
                                _portionSelector(context, app, t),
                              ],
                            ),
                          ),
                        ),
                        PlatePhoto(
                          imageBytes: entry.imageBytes,
                          plateAsset: plateAsset,
                          plateSize: 320,
                          imageSize: 230,
                          tilt: -0.08,
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
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.mealSummaryTitle,
                                    style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    mealSummary?.advice ?? t.detailAiEmpty,
                                    style: AppTextStyles.title1(context).copyWith(color: Colors.black87, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                mealSummary?.calorieRange ?? t.calorieUnknown,
                                style: TextStyle(fontWeight: FontWeight.w700, color: theme.colorScheme.primary),
                              ),
                            ),
                          ],
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
                        Text(t.detailWhyLabel, style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600)),
                        if (entry.error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(entry.error!, style: AppTextStyles.caption(context).copyWith(color: Colors.red)),
                          )
                        else if (entry.result != null)
                          _radarChart(context, entry, t)
                        else
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(t.detailAiEmpty, style: AppTextStyles.caption(context).copyWith(color: Colors.black54)),
                          ),
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

class _RadarPainter extends CustomPainter {
  _RadarPainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.32;
    final axes = values.length;
    final gridPaint = Paint()
      ..color = const Color(0xFFE6E9F2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final shapePaint = Paint()
      ..color = const Color(0xFFB5D8C6).withOpacity(0.6)
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = const Color(0xFFB5D8C6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 1; i <= 5; i++) {
      final r = radius * (i / 5);
      final path = Path();
      for (int j = 0; j < axes; j++) {
        final angle = (2 * math.pi / axes) * j - math.pi / 2;
        final point = Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
        if (j == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    final dataPath = Path();
    for (int j = 0; j < axes; j++) {
      final angle = (2 * math.pi / axes) * j - math.pi / 2;
      final point = Offset(
        center.dx + radius * values[j] * math.cos(angle),
        center.dy + radius * values[j] * math.sin(angle),
      );
      if (j == 0) {
        dataPath.moveTo(point.dx, point.dy);
      } else {
        dataPath.lineTo(point.dx, point.dy);
      }
    }
    dataPath.close();
    canvas.drawPath(dataPath, shapePaint);
    canvas.drawPath(dataPath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    if (oldDelegate.values.length != values.length) return true;
    for (int i = 0; i < values.length; i++) {
      if (oldDelegate.values[i] != values[i]) return true;
    }
    return false;
  }
}
