import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:food_ai_app/gen/app_localizations.dart';

enum NutritionChartStyle {
  radar,
  bars,
  donut,
}

class NutritionChart extends StatelessWidget {
  const NutritionChart({
    super.key,
    required this.macros,
    required this.style,
    required this.t,
  });

  final Map<String, String> macros;
  final NutritionChartStyle style;
  final AppLocalizations t;

  static const _axisColors = [
    Color(0xFF7FCB99), // protein
    Color(0xFFF1BE4B), // carbs
    Color(0xFFF08A7C), // fat
    Color(0xFF8AB4F8), // sodium
  ];

  double _ratioFromValue(String value) {
    final v = value.toLowerCase();
    if (v.contains('偏高') || v.contains('slightly high')) return 0.7;
    if (v.contains('偏低') || v.contains('slightly low')) return 0.4;
    if (v.contains('高') || v.contains('high')) return 0.8;
    if (v.contains('低') || v.contains('low')) return 0.3;
    if (v.contains('中') || v.contains('medium')) return 0.55;
    return 0.55;
  }

  String _displayValue(String rawValue, double ratio) {
    final match = RegExp(r'\d+(\.\d+)?').firstMatch(rawValue);
    if (match != null) {
      return rawValue.trim();
    }
    return '${(ratio * 100).round()}%';
  }

  List<_MacroPoint> _macroPoints() {
    final protein = macros['protein'] ?? t.levelMedium;
    final carbs = macros['carbs'] ?? t.levelMedium;
    final fat = macros['fat'] ?? t.levelMedium;
    final sodium = macros['sodium'] ?? t.levelMedium;
    final proteinRatio = _ratioFromValue(protein);
    final carbsRatio = _ratioFromValue(carbs);
    final fatRatio = _ratioFromValue(fat);
    final sodiumRatio = _ratioFromValue(sodium);
    return [
      _MacroPoint(t.protein, protein, proteinRatio, _axisColors[0], Icons.eco),
      _MacroPoint(t.carbs, carbs, carbsRatio, _axisColors[1], Icons.grass),
      _MacroPoint(t.fat, fat, fatRatio, _axisColors[2], Icons.local_pizza),
      _MacroPoint(t.sodium, sodium, sodiumRatio, _axisColors[3], Icons.opacity),
    ];
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
  _MacroPoint(this.label, this.rawValue, this.ratio, this.color, this.icon);

  final String label;
  final String rawValue;
  final double ratio;
  final Color color;
  final IconData icon;
}

class _RadarChart extends StatelessWidget {
  const _RadarChart({
    required this.points,
    required this.displayValue,
  });

  final List<_MacroPoint> points;
  final String Function(String, double) displayValue;

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
                  child: _nutrientValue(points[0], displayValue, TextAlign.center),
                ),
                Align(
                  alignment: const Alignment(1.45, 0.05),
                  child: _nutrientStack(points[1], displayValue, TextAlign.left),
                ),
                Align(
                  alignment: const Alignment(0, 1.35),
                  child: _nutrientValue(points[2], displayValue, TextAlign.center),
                ),
                Align(
                  alignment: const Alignment(-1.45, 0.05),
                  child: _nutrientStack(points[3], displayValue, TextAlign.right),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _nutrientValue(_MacroPoint point, String Function(String, double) displayValue, TextAlign align) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(point.icon, size: 16, color: point.color),
        const SizedBox(width: 6),
        Text(
          '${point.label} ${displayValue(point.rawValue, point.ratio)}',
          style: const TextStyle(fontSize: 11, color: Colors.black54),
          textAlign: align,
        ),
      ],
    );
  }

  Widget _nutrientStack(_MacroPoint point, String Function(String, double) displayValue, TextAlign align) {
    return Column(
      crossAxisAlignment: align == TextAlign.right ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Icon(point.icon, size: 16, color: point.color),
        const SizedBox(height: 4),
        Text(
          '${point.label} ${displayValue(point.rawValue, point.ratio)}',
          style: const TextStyle(fontSize: 11, color: Colors.black54),
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
  final String Function(String, double) displayValue;

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
  final String Function(String, double) displayValue;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final barHeight = 20.0;
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        displayValue(point.rawValue, point.ratio),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
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
  final String Function(String, double) displayValue;

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
                        displayValue(point.rawValue, point.ratio),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
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
                    Text(point.label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                  ],
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}
