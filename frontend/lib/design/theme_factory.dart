import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme_config.dart';
import 'app_theme.dart';

class ThemeFactory {
  static ThemeData fromConfig(ThemeConfig config) {
    final primary = _hex(config.colors['primary'] ?? '#5B7CFA');
    final background = _hex(config.colors['background'] ?? '#F3F5FB');
    final gradientTop = _hex(config.colors['background_top'] ?? '#E6F1FF');
    final gradientBottom = _hex(config.colors['background_bottom'] ?? '#F3F5FA');
    final glow = _hex(config.colors['glow'] ?? '#D7E9FF');
    final card = _hex(config.colors['card'] ?? '#FFFFFF');
    final text = _hex(config.colors['text'] ?? '#1B1D21');
    final muted = _hex(config.colors['muted'] ?? '#6B7280');
    final accent = _hex(config.colors['accent'] ?? '#F4C95D');
    final success = _hex(config.colors['success'] ?? '#8AD7A4');
    final warning = _hex(config.colors['warning'] ?? '#F4C95D');
    final danger = _hex(config.colors['danger'] ?? '#F08A7C');
    final radiusCard = config.radii['card'] ?? 18.0;
    final radiusButton = config.radii['button'] ?? 16.0;

    final baseTextTheme = GoogleFonts.getTextTheme(config.font);
    final textTheme = baseTextTheme.copyWith(
      titleLarge: baseTextTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w600, color: text),
      titleMedium: baseTextTheme.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w600, color: text),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w500, color: text),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w400, color: text),
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.transparent,
      cardColor: card,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        background: background,
        surface: card,
        onSurface: text,
      ),
      textTheme: textTheme,
      extensions: [
        AppTheme(
          card: card,
          mutedText: muted,
          accent: accent,
          success: success,
          warning: warning,
          danger: danger,
          gradientTop: gradientTop,
          gradientBottom: gradientBottom,
          glow: glow,
          radiusCard: radiusCard,
          radiusButton: radiusButton,
        ),
      ],
    );
  }

  static Color _hex(String value) {
    var hex = value.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }
}
