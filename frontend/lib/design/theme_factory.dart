import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme_config.dart';
import 'app_theme.dart';

class ThemeFactory {
  static ThemeData fromConfig(ThemeConfig config) {
    final primary = _hex(config.colors['primary'] ?? '#5B7CFA');
    final background = _hex(config.colors['background'] ?? '#F3F5FB');
    final card = _hex(config.colors['card'] ?? '#FFFFFF');
    final text = _hex(config.colors['text'] ?? '#1B1D21');
    final muted = _hex(config.colors['muted'] ?? '#6B7280');
    final accent = _hex(config.colors['accent'] ?? '#F4C95D');
    final success = _hex(config.colors['success'] ?? '#8AD7A4');
    final warning = _hex(config.colors['warning'] ?? '#F4C95D');
    final danger = _hex(config.colors['danger'] ?? '#F08A7C');
    final radiusCard = config.radii['card'] ?? 18.0;
    final radiusButton = config.radii['button'] ?? 16.0;

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      cardColor: card,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        background: background,
        surface: card,
        onSurface: text,
      ),
      textTheme: GoogleFonts.getTextTheme(config.font),
      extensions: [
        AppTheme(
          card: card,
          mutedText: muted,
          accent: accent,
          success: success,
          warning: warning,
          danger: danger,
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
