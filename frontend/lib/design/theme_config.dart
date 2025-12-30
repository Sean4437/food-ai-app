class ThemeConfig {
  ThemeConfig({
    required this.name,
    required this.font,
    required this.colors,
    required this.radii,
    required this.layout,
  });

  final String name;
  final String font;
  final Map<String, String> colors;
  final Map<String, double> radii;
  final Map<String, List<String>> layout;

  factory ThemeConfig.fromJson(Map<String, dynamic> json) {
    return ThemeConfig(
      name: json['name'] as String? ?? 'clean',
      font: json['font'] as String? ?? 'Manrope',
      colors: Map<String, String>.from(json['colors'] as Map? ?? const {}),
      radii: (json['radii'] as Map? ?? const {}).map(
        (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
      ),
      layout: (json['layout'] as Map? ?? const {}).map(
        (key, value) => MapEntry(key.toString(), List<String>.from(value as List? ?? const [])),
      ),
    );
  }

  static ThemeConfig fallback() {
    return ThemeConfig(
      name: 'clean',
      font: 'Manrope',
      colors: {
        'primary': '#5B7CFA',
        'background': '#F3F5FB',
        'card': '#FFFFFF',
        'text': '#1B1D21',
        'muted': '#6B7280',
        'accent': '#F4C95D',
        'success': '#8AD7A4',
        'warning': '#F4C95D',
        'danger': '#F08A7C',
      },
      radii: {
        'card': 18,
        'button': 16,
      },
      layout: {
        'home': ['capture', 'latest', 'next', 'summary'],
      },
    );
  }
}
