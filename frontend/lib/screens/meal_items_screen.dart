import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:food_ai_app/gen/app_localizations.dart';
import '../models/meal_entry.dart';
import '../state/app_state.dart';
import 'day_meals_screen.dart';
import '../widgets/plate_photo.dart';

class MealItemsScreen extends StatefulWidget {
  const MealItemsScreen({
    super.key,
    required this.group,
    this.autoReturnToDayMeals = false,
    this.autoReturnDate,
    this.autoReturnMealId,
  });

  final List<MealEntry> group;
  final bool autoReturnToDayMeals;
  final DateTime? autoReturnDate;
  final String? autoReturnMealId;

  @override
  State<MealItemsScreen> createState() => _MealItemsScreenState();
}

class _MealItemsScreenState extends State<MealItemsScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.86);
  int _pageIndex = 0;
  Timer? _autoTimer;
  bool _autoTimerStarted = false;

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.autoReturnToDayMeals || _autoTimerStarted) return;
    final mealId = widget.autoReturnMealId;
    final date = widget.autoReturnDate;
    if (mealId == null || date == null) return;
    _autoTimerStarted = true;
    final app = AppStateScope.of(context);
    _autoTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      final last = app.mealInteractionAt(mealId);
      if (last == null) return;
      if (DateTime.now().difference(last) < const Duration(minutes: 1)) return;
      timer.cancel();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DayMealsScreen(date: date, initialMealId: mealId),
        ),
      );
    });
  }

  Widget _itemCard(BuildContext context, AppState app, MealEntry entry, String plateAsset) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => _showImagePreview(context, entry),
      child: SizedBox(
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.overrideFoodName ?? entry.result?.foodName ?? t.unknownFood,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _editFoodName(context, app, entry),
                          icon: const Icon(Icons.edit, size: 20),
                          tooltip: t.editFoodName,
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('${t.portionLabel}${entry.portionPercent}%', style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 6),
                    _portionSelector(context, app, entry, theme, t),
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
    );
  }

  Future<void> _showImagePreview(BuildContext context, MealEntry entry) async {
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black.withOpacity(0.85),
        insetPadding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(entry.imageBytes, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editFoodName(BuildContext context, AppState app, MealEntry entry) async {
    final t = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: entry.overrideFoodName ?? entry.result?.foodName ?? '');
    final locale = Localizations.localeOf(context).toLanguageTag();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.editFoodName),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: t.foodNameLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(t.save),
          ),
        ],
      ),
    );
    if (result == null) return;
    await app.updateEntryFoodName(entry, result, locale);
  }

  double _ratioFromValue(String value) {
    final v = value.toLowerCase();
    if (v.contains('偏高')) return 0.7;
    if (v.contains('偏低')) return 0.4;
    if (v.contains('高') || v.contains('high')) return 0.8;
    if (v.contains('低') || v.contains('low')) return 0.3;
    return 0.55;
  }

  String _displayValue(String rawValue, double ratio) {
    final match = RegExp(r'\d+(\.\d+)?').firstMatch(rawValue);
    if (match != null) {
      return rawValue.trim();
    }
    return '${(ratio * 100).round()}%';
  }

  Widget _nutrientValue(String label, String value, double ratio, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          '$label ${_displayValue(value, ratio)}',
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _portionSelector(
    BuildContext context,
    AppState app,
    MealEntry entry,
    ThemeData theme,
    AppLocalizations t,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${t.portionLabel}${entry.portionPercent}%', style: const TextStyle(fontWeight: FontWeight.w600)),
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
            max: 100,
            divisions: 9,
            label: '${entry.portionPercent}%',
            onChanged: (value) {
              app.updateEntryPortionPercent(entry, value.round());
            },
          ),
        ),
      ],
    );
  }

  Widget _radarChart(MealEntry entry, AppLocalizations t) {
    final protein = entry.result?.macros['protein'] ?? t.levelMedium;
    final carbs = entry.result?.macros['carbs'] ?? t.levelMedium;
    final fat = entry.result?.macros['fat'] ?? t.levelMedium;
    final sodium = entry.result?.macros['sodium'] ?? t.levelMedium;
    final proteinRatio = _ratioFromValue(protein);
    final carbsRatio = _ratioFromValue(carbs);
    final fatRatio = _ratioFromValue(fat);
    final sodiumRatio = _ratioFromValue(sodium);
    final values = [proteinRatio, carbsRatio, fatRatio, sodiumRatio];

    return SizedBox(
      height: 320,
      child: CustomPaint(
        painter: _RadarPainter(values),
        child: Center(
          child: SizedBox(
            width: 240,
            height: 240,
            child: Stack(
              children: [
                Align(
                  alignment: const Alignment(0, -1.35),
                  child: _nutrientValue(t.protein, protein, proteinRatio, Icons.eco, const Color(0xFF7FCB99)),
                ),
                Align(
                  alignment: const Alignment(1.35, 0.1),
                  child: _nutrientValue(t.carbs, carbs, carbsRatio, Icons.grass, const Color(0xFFF1BE4B)),
                ),
                Align(
                  alignment: const Alignment(0, 1.35),
                  child: _nutrientValue(t.fat, fat, fatRatio, Icons.local_pizza, const Color(0xFFF08A7C)),
                ),
                Align(
                  alignment: const Alignment(-1.35, 0.1),
                  child: _nutrientValue(t.sodium, sodium, sodiumRatio, Icons.opacity, const Color(0xFF8AB4F8)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _nutritionTitle(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return code == 'en' ? 'Nutrition' : '營養成分';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final app = AppStateScope.of(context);
    final theme = Theme.of(context);
    final plateAsset = app.profile.plateAsset.isEmpty ? kDefaultPlateAsset : app.profile.plateAsset;
    final sorted = List<MealEntry>.from(widget.group)..sort((a, b) => b.time.compareTo(a.time));
    if (_pageIndex >= sorted.length) {
      _pageIndex = 0;
    }
    final currentEntry = sorted.isEmpty ? null : sorted[_pageIndex];
    final mealSummary = sorted.isEmpty ? null : app.buildMealSummary(sorted, t);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.mealItemsTitle),
        backgroundColor: const Color(0xFFF3F5FB),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 420,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _pageIndex = index),
                itemCount: sorted.length,
                itemBuilder: (context, index) => _itemCard(context, app, sorted[index], plateAsset),
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.mealSummaryTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Text(
                              mealSummary?.advice ?? t.detailAiEmpty,
                              style: const TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.w600),
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
            if (currentEntry?.result != null)
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
                    Text(_nutritionTitle(context), style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _radarChart(currentEntry!, t),
                  ],
                ),
              ),
          ],
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
    final radius = math.min(size.width, size.height) * 0.38;
    final axes = values.length;
    final gridPaint = Paint()
      ..color = const Color(0xFFE6E9F2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final axisColors = [
      const Color(0xFF7FCB99), // protein
      const Color(0xFFF1BE4B), // carbs
      const Color(0xFFF08A7C), // fat
      const Color(0xFF8AB4F8), // sodium
    ];
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

    for (int j = 0; j < axes; j++) {
      final angle = (2 * math.pi / axes) * j - math.pi / 2;
      final prevAngle = (2 * math.pi / axes) * (j - 1) - math.pi / 2;
      final nextAngle = (2 * math.pi / axes) * (j + 1) - math.pi / 2;
      final value = values[j].clamp(0.1, 1.0);
      final color = axisColors[j % axisColors.length];
      final edge = Offset(
        center.dx + radius * value * math.cos(angle),
        center.dy + radius * value * math.sin(angle),
      );
      final left = Offset(
        center.dx + radius * value * math.cos((angle + prevAngle) / 2),
        center.dy + radius * value * math.sin((angle + prevAngle) / 2),
      );
      final right = Offset(
        center.dx + radius * value * math.cos((angle + nextAngle) / 2),
        center.dy + radius * value * math.sin((angle + nextAngle) / 2),
      );
      final wedge = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(left.dx, left.dy)
        ..lineTo(edge.dx, edge.dy)
        ..lineTo(right.dx, right.dy)
        ..close();
      final fillPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withOpacity(0.05),
            color.withOpacity(0.25 + 0.45 * value),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.fill;
      canvas.drawPath(wedge, fillPaint);
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
