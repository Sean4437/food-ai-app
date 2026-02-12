import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import '../design/app_theme.dart';
import '../design/text_styles.dart';
import '../state/app_state.dart';

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

  Widget activityCard(BuildContext context) => _activityCard(context);

  Widget calorieCard(BuildContext context) => _calorieCard(context);

  Widget _emojiIcon(String emoji, {double size = 16}) {
    return Text(emoji, style: TextStyle(fontSize: size, height: 1));
  }

  Widget _calorieGauge({
    required double consumed,
    required int? min,
    required int? max,
    required Color primary,
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

  Widget _infoCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appTheme.card,
        borderRadius: BorderRadius.circular(appTheme.radiusCard),
        border: Border.all(color: Colors.black.withOpacity(0.08), width: 1),
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

  Widget _activityCard(BuildContext context) {
    final current = app.dailyActivityLevel(date);
    final exerciseType = app.dailyExerciseType(date);
    final exerciseMinutes = app.dailyExerciseMinutes(date);
    final exerciseLabel = app.exerciseLabel(exerciseType, t);
    final shortExercise = exerciseLabel.length > 3
        ? exerciseLabel.substring(0, 3)
        : exerciseLabel;
    return _infoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.activityCardTitle,
            style: AppTextStyles.title2(context),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              app.targetCalorieRangeLabel(date, t),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onSelectActivityLevel,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: onSelectExerciseType,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
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
        ],
      ),
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
    return _infoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.dayCardCalorieLabel,
            style: AppTextStyles.title2(context),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: Container()),
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _calorieGauge(
                      consumed: consumed,
                      min: targetMin,
                      max: targetMax,
                      primary: theme.colorScheme.primary,
                      size: 120,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          consumed.round().toString(),
                          style: AppTextStyles.title1(context).copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'kcal',
                          style: AppTextStyles.caption(context)
                              .copyWith(color: Colors.black54),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          remainingText,
                          style: AppTextStyles.caption(context).copyWith(
                            fontWeight: FontWeight.w600,
                            color: isOver ? Colors.redAccent : Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        t.dayCardMealsLabel,
                        style: AppTextStyles.caption(context)
                            .copyWith(color: Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        app.dayMealLabels(date, t),
                        style: AppTextStyles.caption(context)
                            .copyWith(fontWeight: FontWeight.w600),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _activityCard(context)),
        const SizedBox(width: 12),
        Expanded(child: _calorieCard(context)),
      ],
    );
  }
}

class _CalorieGaugePainter extends CustomPainter {
  _CalorieGaugePainter({
    required this.consumed,
    required this.min,
    required this.max,
    required this.primary,
  });

  final double consumed;
  final int? min;
  final int? max;
  final Color primary;

  static const double _startAngle = math.pi * 7 / 6; // 210°
  static const double _sweepAngle = math.pi * 4 / 3; // 240°
  static const double _strokeWidth = 12;

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
      final cap = max! * 1.5;
      final minValue = (min ?? max!).clamp(0, cap).toDouble();
      final maxValue = max!.toDouble();
      final minT = (minValue / cap).clamp(0.0, 1.0);
      final maxT = (maxValue / cap).clamp(0.0, 1.0);

      if (maxT > minT) {
        _drawGradientArc(
          canvas,
          rect,
          _startAngle + _sweepAngle * minT,
          _sweepAngle * (maxT - minT),
          const Color(0xFF7ADDB0),
          primary,
        );
      }

      if (maxT < 1.0) {
        _drawGradientArc(
          canvas,
          rect,
          _startAngle + _sweepAngle * maxT,
          _sweepAngle * (1.0 - maxT),
          const Color(0xFFFFB067),
          Colors.redAccent,
        );
      }

      final value = consumed.clamp(0.0, cap);
      final t = (value / cap).clamp(0.0, 1.0);
      final angle = _startAngle + _sweepAngle * t;
      final end = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      final pointerPaint = Paint()
        ..color = Colors.black54
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(center, end, pointerPaint);
      final knobPaint = Paint()..color = Colors.white;
      canvas.drawCircle(end, 4, knobPaint);
      final knobBorder = Paint()
        ..color = Colors.black26
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(end, 4, knobBorder);
    }
  }

  void _drawGradientArc(
    Canvas canvas,
    Rect rect,
    double start,
    double sweep,
    Color from,
    Color to,
  ) {
    if (sweep <= 0) return;
    const segments = 40;
    final segSweep = sweep / segments;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < segments; i++) {
      final t = (i + 0.5) / segments;
      paint.color = Color.lerp(from, to, t)!;
      canvas.drawArc(rect, start + segSweep * i, segSweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CalorieGaugePainter oldDelegate) {
    return oldDelegate.consumed != consumed ||
        oldDelegate.min != min ||
        oldDelegate.max != max ||
        oldDelegate.primary != primary;
  }
}
