import "dart:math" as math;
import "package:flutter/material.dart";
import "package:food_ai_app/gen/app_localizations.dart";
import "../design/text_styles.dart";

enum NutritionChartStyle {
  radar,
  bars,
  donut,
}

enum NutritionValueMode {
  percent,
  amount,
}

class NutritionChart extends StatelessWidget {
  const NutritionChart({
    super.key,
    required this.macros,
    required this.style,
    required this.t,
    this.valueMode = NutritionValueMode.percent,
  });

  final Map<String, double> macros;
  final NutritionChartStyle style;
  final AppLocalizations t;
  final NutritionValueMode valueMode;

  static const _axisColors = [
    Color(0xFF7FCB99), // protein
    Color(0xFFF1BE4B), // carbs
    Color(0xFFF08A7C), // fat
    Color(0xFF8AB4F8), // sodium
  ];

  double _ratioFromValue(double value) {
    if (value <= 1) return value;
    return (value.clamp(0, 100)) / 100;
  }

  double _normalizedPercent(double value) {
    return value <= 1 ? (value * 100) : value;
  }

  double _amountFromPercent(String key, double percent) {
    final ratio = (percent.clamp(0, 100)) / 100;
    switch (key) {
      case "protein":
        return 30 * ratio;
      case "carbs":
        return 80 * ratio;
      case "fat":
        return 25 * ratio;
      case "sodium":
        return 800 * ratio;
      default:
        return 0;
    }
  }

  String _displayValue(_MacroPoint point) {
    final percent = _normalizedPercent(point.rawValue);
    if (valueMode == NutritionValueMode.percent) {
      return "${percent.round()}%";
    }
    final amount = _amountFromPercent(point.key, percent);
    final unit = point.unit;
    final valueText = amount.round().toString();
    return unit == "mg" ? "~${valueText}mg" : "~${valueText}g";
  }

  List<_MacroPoint> _macroPoints() {
    final protein = macros["protein"] ?? 55;
    final carbs = macros["carbs"] ?? 55;
    final fat = macros["fat"] ?? 55;
    final sodium = macros["sodium"] ?? 55;
    final proteinRatio = _ratioFromValue(protein);
    final carbsRatio = _ratioFromValue(carbs);
    final fatRatio = _ratioFromValue(fat);
    final sodiumRatio = _ratioFromValue(sodium);
    return [
      _MacroPoint("protein", t.protein, protein, proteinRatio, _axisColors[0], Icons.eco, "g"),
      _MacroPoint("carbs", t.carbs, carbs, carbsRatio, _axisColors[1], Icons.grass, "g"),
      _MacroPoint("fat", t.fat, fat, fatRatio, _axisColors[2], Icons.local_pizza, "g"),
      _MacroPoint("sodium", t.sodium, sodium, sodiumRatio, _axisColors[3], Icons.opacity, "mg"),
    ];
  }

  static String formatValue({
    required String key,
    required double value,
    required NutritionValueMode mode,
  }) {
    final percent = value <= 1 ? (value * 100) : value;
    if (mode == NutritionValueMode.percent) {
      return "${percent.round()}%";
    }
    final ratio = (percent.clamp(0, 100)) / 100;
    final amount = () {
      switch (key) {
        case "protein":
          return 30 * ratio;
        case "carbs":
          return 80 * ratio;
        case "fat":
          return 25 * ratio;
        case "sodium":
          return 800 * ratio;
        default:
          return 0;
      }
    }();
    final unit = key == "sodium" ? "mg" : "g";
    return unit == "mg" ? "~${amount.round()}mg" : "~${amount.round()}g";
  }

  @override
  Widget build(BuildContext context) {
    final points = _macroPoints();
    switch (style) {
      case NutritionChartStyle.bars:
        return _BarsChart(points: points, displayValue: _displayValue);
      case NutritionChartStyle.donut:
        return _DonutChart(points: points, displayValue: _displayValue);
      case NutritionChartStyle.radar:
      default:
        return _RadarChart(points: points, displayValue: _displayValue);
    }
  }
}

class _MacroPoint {
  _MacroPoint(this.key, this.label, this.rawValue, this.ratio, this.color, this.icon, this.unit);

  final String key;
  final String label;
  final double rawValue;
  final double ratio;
  final Color color;
  final IconData icon;
  final String unit;
}

class _RadarChart extends StatelessWidget {
  const _RadarChart({
    required this.points,
    required this.displayValue,
  });

  final List<_MacroPoint> points;
  final String Function(_MacroPoint) displayValue;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: CustomPaint(
        painter: _RadarPainter(points: points),
        child: Center(
          child: SizedBox(
            width: 240,
            height: 240,
            child: Stack(
              children: [
                Align(
                  alignment: const Alignment(0, -1.35),
                  child: _nutrientValue(context, points[0], displayValue, TextAlign.center),
                ),
                Align(
                  alignment: const Alignment(1.45, 0.05),
                  child: _nutrientStack(context, points[1], displayValue, TextAlign.left),
                ),
                Align(
                  alignment: const Alignment(0, 1.35),
                  child: _nutrientValue(context, points[2], displayValue, TextAlign.center),
                ),
                Align(
                  alignment: const Alignment(-1.45, 0.05),
                  child: _nutrientStack(context, points[3], displayValue, TextAlign.right),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _nutrientValue(
    BuildContext context,
    _MacroPoint point,
    String Function(_MacroPoint) displayValue,
    TextAlign align,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(point.icon, size: 16, color: point.color),
        const SizedBox(width: 6),
        Text(
          "${point.label} ${displayValue(point)}",
          style: AppTextStyles.caption(context).copyWith(color: Colors.black54),
          textAlign: align,
        ),
      ],
    );
  }

  Widget _nutrientStack(
    BuildContext context,
    _MacroPoint point,
    String Function(_MacroPoint) displayValue,
    TextAlign align,
  ) {
    return Column(
      crossAxisAlignment: align == TextAlign.right ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Icon(point.icon, size: 16, color: point.color),
        const SizedBox(height: 4),
        Text(
          "${point.label} ${displayValue(point)}",
          style: AppTextStyles.caption(context).copyWith(color: Colors.black54),
          textAlign: align,
        ),
      ],
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({required this.points});

  final List<_MacroPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.38;
    final axes = points.length;
    final gridPaint = Paint()
      ..color = const Color(0xFFE6E9F2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
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
      final nextAngle = (2 * math.pi / axes) * (j + 1) - math.pi / 2;
      final value = points[j].ratio.clamp(0.1, 1.0);
      final nextValue = points[(j + 1) % axes].ratio.clamp(0.1, 1.0);
      final color = points[j].color;
      final edge = Offset(
        center.dx + radius * value * math.cos(angle),
        center.dy + radius * value * math.sin(angle),
      );
      final nextEdge = Offset(
        center.dx + radius * nextValue * math.cos(nextAngle),
        center.dy + radius * nextValue * math.sin(nextAngle),
      );
      final wedge = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(edge.dx, edge.dy)
        ..lineTo(nextEdge.dx, nextEdge.dy)
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
        center.dx + radius * points[j].ratio * math.cos(angle),
        center.dy + radius * points[j].ratio * math.sin(angle),
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
    if (oldDelegate.points.length != points.length) return true;
    for (int i = 0; i < points.length; i++) {
      if (oldDelegate.points[i].ratio != points[i].ratio) return true;
    }
    return false;
  }
}

class _BarsChart extends StatelessWidget {
  const _BarsChart({required this.points, required this.displayValue});

  final List<_MacroPoint> points;
  final String Function(_MacroPoint) displayValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: points
          .map(
            (point) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: _MacroBar(point: point, displayValue: displayValue),
            ),
          )
          .toList(),
    );
  }
}

class _MacroBar extends StatelessWidget {
  const _MacroBar({
    required this.point,
    required this.displayValue,
  });

  final _MacroPoint point;
  final String Function(_MacroPoint) displayValue;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final barHeight = 28.0;
        final radius = BorderRadius.circular(12);
        final fillWidth = constraints.maxWidth * point.ratio;
        return ClipRRect(
          borderRadius: radius,
          child: Stack(
            children: [
              Container(
                height: barHeight,
                decoration: BoxDecoration(
                  color: point.color.withOpacity(0.18),
                  borderRadius: radius,
                ),
              ),
              Container(
                height: barHeight,
                width: fillWidth,
                decoration: BoxDecoration(
                  color: point.color,
                  borderRadius: radius,
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      Icon(point.icon, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          point.label,
                          style: AppTextStyles.caption(context).copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        displayValue(point),
                        style: AppTextStyles.caption(context).copyWith(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DonutChart extends StatelessWidget {
  const _DonutChart({required this.points, required this.displayValue});

  final List<_MacroPoint> points;
  final String Function(_MacroPoint) displayValue;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: points
          .map(
            (point) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: point.ratio,
                        strokeWidth: 8,
                        backgroundColor: point.color.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(point.color),
                      ),
                      Text(
                        displayValue(point),
                        style: AppTextStyles.caption(context).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(point.icon, size: 14, color: point.color),
                    const SizedBox(width: 4),
                    Text(point.label, style: AppTextStyles.caption(context).copyWith(color: Colors.black54)),
                  ],
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}
