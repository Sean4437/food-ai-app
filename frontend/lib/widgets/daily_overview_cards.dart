import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import '../design/app_theme.dart';
import '../design/text_styles.dart';
import '../state/app_state.dart';

const _gaugeStartGrey = Color(0xFFC8D0CD);
const _gaugeMidOrange = Color(0xFFFFB067);

Color _gaugeColorAt(
  double t,
  Color green,
  double minValue,
  double maxValue,
  double cap,
) {
  final minT = (minValue / cap).clamp(0.0, 1.0);
  final maxT = (maxValue / cap).clamp(0.0, 1.0);
  if (t <= minT) {
    final local = minT == 0 ? 1.0 : (t / minT);
    return Color.lerp(_gaugeStartGrey, green, local)!;
  }
  if (t <= maxT) {
    return green;
  }
  final local = (t - maxT) / (1.0 - maxT == 0 ? 1 : (1.0 - maxT));
  if (local <= 0.2) {
    return Color.lerp(green, _gaugeMidOrange, local / 0.2)!;
  }
  return Color.lerp(_gaugeMidOrange, Colors.redAccent, (local - 0.2) / 0.8)!;
}

Color _gaugeColorForValue(
  double value,
  int? min,
  int? max,
  Color green, {
  double capPadding = 500,
}
) {
  if (max == null || max <= 0) return Colors.black54;
  final cap = (max + capPadding).toDouble();
  final minValue = (min ?? 0).toDouble();
  final maxValue = max.toDouble();
  final t = (value.clamp(0.0, cap)) / cap;
  return _gaugeColorAt(t, green, minValue, maxValue, cap);
}

class DailyOverviewCards extends StatelessWidget {
  const DailyOverviewCards({
    super.key,
    required this.date,
    required this.app,
    required this.t,
    required this.appTheme,
    required this.theme,
    required this.onSelectActivityLevel,
    required this.onSelectExerciseType,
    required this.onSelectExerciseMinutes,
  });

  final DateTime date;
  final AppState app;
  final AppLocalizations t;
  final AppTheme appTheme;
  final ThemeData theme;
  final VoidCallback onSelectActivityLevel;
  final VoidCallback onSelectExerciseType;
  final VoidCallback onSelectExerciseMinutes;

  Widget calorieCard(BuildContext context) => _calorieCard(context);
  Widget proteinCard(BuildContext context) => _proteinCard(context);

  Widget _emojiIcon(String emoji, {double size = 16}) {
    return Text(emoji, style: TextStyle(fontSize: size, height: 1));
  }

  Widget _calorieGauge({
    required double consumed,
    required int? min,
    required int? max,
    required Color primary,
    required double innerRadius,
    double capPadding = 500,
    double size = 120,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CalorieGaugePainter(
          consumed: consumed,
          min: min,
          max: max,
          primary: primary,
          innerRadius: innerRadius,
          capPadding: capPadding,
        ),
      ),
    );
  }

  List<int>? _parseRange(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final match = RegExp(r'(\d+)\s*-\s*(\d+)').firstMatch(value);
    if (match == null) return null;
    final minVal = int.tryParse(match.group(1) ?? '');
    final maxVal = int.tryParse(match.group(2) ?? '');
    if (minVal == null || maxVal == null) return null;
    return [minVal, maxVal];
  }

  Widget _infoCard({required Widget child, double borderOpacity = 0.08}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appTheme.card,
        borderRadius: BorderRadius.circular(appTheme.radiusCard),
        border: borderOpacity <= 0
            ? null
            : Border.all(
                color: Colors.black.withOpacity(borderOpacity),
                width: 1,
              ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _activityControls(BuildContext context) {
    final current = app.dailyActivityLevel(date);
    final exerciseType = app.dailyExerciseType(date);
    final exerciseMinutes = app.dailyExerciseMinutes(date);
    final exerciseLabel = app.exerciseLabel(exerciseType, t);
    final shortExercise = exerciseLabel.length > 3
        ? exerciseLabel.substring(0, 3)
        : exerciseLabel;
    const menuWidth = 130.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: menuWidth,
          child: InkWell(
            onTap: onSelectActivityLevel,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black12),
              ),
              child: Row(
                children: [
                  Text(
                    app.activityLabel(current, t),
                    style: AppTextStyles.caption(context)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right,
                      color: Colors.black45, size: 18),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: menuWidth,
          child: InkWell(
            onTap: onSelectExerciseType,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black12),
              ),
              child: Row(
                children: [
                  Text(
                    shortExercise,
                    style: AppTextStyles.caption(context).copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right,
                      color: Colors.black45, size: 18),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: menuWidth,
          child: InkWell(
            onTap: onSelectExerciseMinutes,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black12),
              ),
              child: Row(
                children: [
                  Text(
                    t.exerciseMinutesLabel,
                    style: AppTextStyles.caption(context)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    '$exerciseMinutes ${t.exerciseMinutesUnit}',
                    style: AppTextStyles.caption(context)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Icon(Icons.chevron_right,
                      color: Colors.black45, size: 18),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }


  Widget _calorieCard(BuildContext context) {
    final consumed = app.dailyConsumedCalorieMid(date);
    final targetRange = _parseRange(app.targetCalorieRangeValue(date));
    final targetMin = targetRange != null ? targetRange[0] : null;
    final targetMax = targetRange != null ? targetRange[1] : null;
    final hasTarget =
        targetMin != null && targetMax != null && targetMax > 0;
    final remaining = hasTarget ? (targetMax! - consumed) : null;
    final isOver = remaining != null && remaining < 0;
    final remainingText = !hasTarget
        ? '---'
        : isOver
            ? t.suggestRemainingOver((-remaining!).round())
            : t.suggestRemainingLeft(remaining!.round());
    const gaugeSize = 156.0;
    const innerSize = 73.0;
    const innerRadius = innerSize / 2;
    final gaugeKey = ValueKey('gauge-${date.toIso8601String()}');
    final titleStyle = AppTextStyles.title2(context);
    final titleHeight = _measureTextHeight(
      t.dayCardCalorieLabel,
      titleStyle,
    );
    const titleGap = 6.0;
    return _infoCard(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Text(
              t.dayCardCalorieLabel,
              style: titleStyle,
            ),
          ),
          Positioned.fill(
            top: titleHeight + titleGap,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Transform.translate(
                      offset: const Offset(0, -10),
                      child: _activityControls(context),
                    ),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          TweenAnimationBuilder<double>(
                            key: gaugeKey,
                            tween: Tween(begin: 0, end: consumed),
                            duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutCubic,
                          builder: (context, animatedConsumed, child) {
                            final gaugeColor = _gaugeColorForValue(
                              animatedConsumed,
                              targetMin,
                              targetMax,
                              theme.colorScheme.primary,
                            );
                            return Transform.translate(
                              offset: const Offset(20, -10),
                              child: SizedBox(
                                width: gaugeSize,
                                  height: gaugeSize,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      _calorieGauge(
                                        consumed: animatedConsumed,
                                        min: targetMin,
                                        max: targetMax,
                                        primary: theme.colorScheme.primary,
                                        innerRadius: innerRadius,
                                        size: gaugeSize,
                                      ),
                                      Container(
                                        width: innerSize,
                                        height: innerSize,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.12),
                                              blurRadius: 12,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          animatedConsumed.round().toString(),
                                          style: AppTextStyles.title1(context)
                                              .copyWith(fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                      Positioned(
                                    top: gaugeSize / 2 + innerRadius + 6,
                                    child: Text(
                                      remainingText,
                                      style: AppTextStyles.caption(context)
                                          .copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: gaugeColor,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withOpacity(0.25),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _proteinCard(BuildContext context) {
    final consumed = app.dailyProteinConsumedGrams(date);
    final proteinRange = app.proteinTargetRangeGrams();
    final targetMin = proteinRange != null ? proteinRange[0] : null;
    final targetMax = proteinRange != null ? proteinRange[1] : null;
    final hasTarget =
        targetMin != null && targetMax != null && targetMax > 0;
    final remaining = hasTarget ? (targetMax! - consumed) : null;
    final isOver = remaining != null && remaining < 0;
    final remainingText = !hasTarget
        ? '---'
        : isOver
            ? t.proteinRemainingOver((-remaining!).round())
            : t.proteinRemainingLeft(remaining!.round());
    const gaugeSize = 156.0;
    const innerSize = 73.0;
    const innerRadius = innerSize / 2;
    const proteinCapPadding = 50.0;
    final gaugeKey = ValueKey('protein-gauge-${date.toIso8601String()}');
    final titleStyle = AppTextStyles.title2(context);
    final titleHeight = _measureTextHeight(
      t.dayCardProteinLabel,
      titleStyle,
    );
    const titleGap = 6.0;
    return _infoCard(
      borderOpacity: 0,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Text(
              t.dayCardProteinLabel,
              style: titleStyle,
            ),
          ),
          Positioned.fill(
            top: titleHeight + titleGap,
            child: Center(
              child: TweenAnimationBuilder<double>(
                key: gaugeKey,
                tween: Tween(begin: 0, end: consumed),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                builder: (context, animatedConsumed, child) {
                  final gaugeColor = _gaugeColorForValue(
                    animatedConsumed,
                    targetMin,
                    targetMax,
                    theme.colorScheme.primary,
                    capPadding: proteinCapPadding,
                  );
                  return SizedBox(
                    width: gaugeSize,
                    height: gaugeSize,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _calorieGauge(
                          consumed: animatedConsumed,
                          min: targetMin,
                          max: targetMax,
                          primary: theme.colorScheme.primary,
                          innerRadius: innerRadius,
                          size: gaugeSize,
                          capPadding: proteinCapPadding,
                        ),
                        Container(
                          width: innerSize,
                          height: innerSize,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Text(
                            '${animatedConsumed.round()}g',
                            style: AppTextStyles.title1(context)
                                .copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Positioned(
                          top: gaugeSize / 2 + innerRadius + 6,
                          child: Text(
                            remainingText,
                            style: AppTextStyles.caption(context).copyWith(
                              fontWeight: FontWeight.w600,
                              color: gaugeColor,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _measureTextHeight(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.height;
  }
  @override
  Widget build(BuildContext context) {
    return _calorieCard(context);
  }
}

class _CalorieGaugePainter extends CustomPainter {
  _CalorieGaugePainter({
    required this.consumed,
    required this.min,
    required this.max,
    required this.primary,
    required this.innerRadius,
    required this.capPadding,
  });

  final double consumed;
  final int? min;
  final int? max;
  final Color primary;
  final double innerRadius;
  final double capPadding;

  static const double _startAngle = math.pi * 11 / 12; // 165°
  static const double _sweepAngle = math.pi * 7 / 6; // 210°
  static const double _strokeWidth = 24;
  static const Color _pointerBlue = Color(0xFF4A8DFF);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - _strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final basePaint = Paint()
      ..color = const Color(0xFFE1E6E4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, _startAngle, _sweepAngle, false, basePaint);

    if (max != null && max! > 0) {
      final cap = max! + capPadding;
      final minValue = min!.toDouble();
      final maxValue = max!.toDouble();
      _drawGradientArcGlow(
        canvas,
        rect,
        _startAngle,
        _sweepAngle,
        primary,
        minValue: minValue,
        maxValue: maxValue,
        cap: cap.toDouble(),
      );
      _drawGradientArc(
        canvas,
        rect,
        _startAngle,
        _sweepAngle,
        primary,
        minValue: minValue,
        maxValue: maxValue,
        cap: cap.toDouble(),
      );

      _drawTick(
        canvas,
        center,
        radius,
        minValue / cap,
        label: min.toString(),
      );
      _drawTick(
        canvas,
        center,
        radius,
        maxValue / cap,
        label: max.toString(),
      );

      final value = consumed.clamp(0.0, cap);
      final t = (value / cap).clamp(0.0, 1.0);
      _drawPointerTriangle(canvas, center, radius, t, innerRadius);
    }
  }

  void _drawGradientArc(
    Canvas canvas,
    Rect rect,
    double start,
    double sweep,
    Color green, {
    required double minValue,
    required double maxValue,
    required double cap,
  }
  ) {
    if (sweep == 0) return;
    const segments = 60;
    final segSweep = sweep / segments;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < segments; i++) {
      final t = (i + 0.5) / segments;
      paint.color = _colorAt(t, green, minValue, maxValue, cap);
      canvas.drawArc(rect, start + segSweep * i, segSweep, false, paint);
    }
  }

  void _drawGradientArcGlow(
    Canvas canvas,
    Rect rect,
    double start,
    double sweep,
    Color green, {
    required double minValue,
    required double maxValue,
    required double cap,
  }
  ) {
    if (sweep == 0) return;
    const segments = 60;
    final segSweep = sweep / segments;
    final glowRect = Rect.fromCircle(
      center: rect.center,
      radius: rect.width / 2 + 2,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth + 10
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    for (var i = 0; i < segments; i++) {
      final t = (i + 0.5) / segments;
      paint.color =
          _colorAt(t, green, minValue, maxValue, cap).withOpacity(0.15);
      canvas.drawArc(glowRect, start + segSweep * i, segSweep, false, paint);
    }
  }

  Color _colorAt(
    double t,
    Color green,
    double minValue,
    double maxValue,
    double cap,
  ) {
    final minT = (minValue / cap).clamp(0.0, 1.0);
    final maxT = (maxValue / cap).clamp(0.0, 1.0);
    return _gaugeColorAt(t, green, minValue, maxValue, cap);
  }

  void _drawTick(
    Canvas canvas,
    Offset center,
    double radius,
    double t, {
    required String label,
  }) {
    final angle = _startAngle + _sweepAngle * t;
    final outer = Offset(
      center.dx + math.cos(angle) * radius,
      center.dy + math.sin(angle) * radius,
    );
    final inner = Offset(
      center.dx + math.cos(angle) * (radius - 12),
      center.dy + math.sin(angle) * (radius - 12),
    );
    final paint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(inner, outer, paint);

    final lead = Offset(
      center.dx + math.cos(angle) * (radius + 21),
      center.dy + math.sin(angle) * (radius + 21),
    );
    canvas.drawLine(outer, lead, paint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final offset = Offset(
      lead.dx,
      lead.dy - textPainter.height / 2,
    );
    textPainter.paint(canvas, offset);
  }

  void _drawPointerTriangle(
    Canvas canvas,
    Offset center,
    double radius,
    double t,
    double innerRadius,
  ) {
    final angle = _startAngle + _sweepAngle * t;
    final tip = Offset(
      center.dx + math.cos(angle) * radius,
      center.dy + math.sin(angle) * radius,
    );
    final baseRadius = innerRadius;
    final baseAngleLeft = angle + 0.12;
    final baseAngleRight = angle - 0.12;
    final left = Offset(
      center.dx + math.cos(baseAngleLeft) * baseRadius,
      center.dy + math.sin(baseAngleLeft) * baseRadius,
    );
    final right = Offset(
      center.dx + math.cos(baseAngleRight) * baseRadius,
      center.dy + math.sin(baseAngleRight) * baseRadius,
    );
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();
    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final fill = Paint()
      ..color = _pointerBlue
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fill);
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(covariant _CalorieGaugePainter oldDelegate) {
    return oldDelegate.consumed != consumed ||
        oldDelegate.min != min ||
        oldDelegate.max != max ||
        oldDelegate.primary != primary;
  }
}
