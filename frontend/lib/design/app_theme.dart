import 'package:flutter/material.dart';

class AppTheme extends ThemeExtension<AppTheme> {
  const AppTheme({
    required this.card,
    required this.mutedText,
    required this.accent,
    required this.success,
    required this.warning,
    required this.danger,
    required this.gradientTop,
    required this.gradientBottom,
    required this.glow,
    required this.radiusCard,
    required this.radiusButton,
  });

  final Color card;
  final Color mutedText;
  final Color accent;
  final Color success;
  final Color warning;
  final Color danger;
  final Color gradientTop;
  final Color gradientBottom;
  final Color glow;
  final double radiusCard;
  final double radiusButton;

  @override
  AppTheme copyWith({
    Color? card,
    Color? mutedText,
    Color? accent,
    Color? success,
    Color? warning,
    Color? danger,
    Color? gradientTop,
    Color? gradientBottom,
    Color? glow,
    double? radiusCard,
    double? radiusButton,
  }) {
    return AppTheme(
      card: card ?? this.card,
      mutedText: mutedText ?? this.mutedText,
      accent: accent ?? this.accent,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      gradientTop: gradientTop ?? this.gradientTop,
      gradientBottom: gradientBottom ?? this.gradientBottom,
      glow: glow ?? this.glow,
      radiusCard: radiusCard ?? this.radiusCard,
      radiusButton: radiusButton ?? this.radiusButton,
    );
  }

  @override
  AppTheme lerp(ThemeExtension<AppTheme>? other, double t) {
    if (other is! AppTheme) return this;
    return AppTheme(
      card: Color.lerp(card, other.card, t) ?? card,
      mutedText: Color.lerp(mutedText, other.mutedText, t) ?? mutedText,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      danger: Color.lerp(danger, other.danger, t) ?? danger,
      gradientTop: Color.lerp(gradientTop, other.gradientTop, t) ?? gradientTop,
      gradientBottom: Color.lerp(gradientBottom, other.gradientBottom, t) ?? gradientBottom,
      glow: Color.lerp(glow, other.glow, t) ?? glow,
      radiusCard: radiusCard + (other.radiusCard - radiusCard) * t,
      radiusButton: radiusButton + (other.radiusButton - radiusButton) * t,
    );
  }
}
