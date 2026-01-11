import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme_config.dart';
import 'theme_factory.dart';

class ThemeController extends ChangeNotifier {
  ThemeController() {
    _config = ThemeConfig.fallback();
    _theme = ThemeFactory.fromConfig(_config);
  }

  late ThemeConfig _config;
  late ThemeData _theme;

  ThemeConfig get config => _config;
  ThemeData get theme => _theme;

  Future<void> loadFromAsset(String assetPath) async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final jsonMap = json.decode(raw) as Map<String, dynamic>;
      _config = ThemeConfig.fromJson(jsonMap);
      _theme = ThemeFactory.fromConfig(_config);
      notifyListeners();
    } catch (_) {
      _config = ThemeConfig.fallback();
      _theme = ThemeFactory.fromConfig(_config);
      notifyListeners();
    }
  }
}

class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({
    super.key,
    required ThemeController notifier,
    required super.child,
  }) : super(notifier: notifier);

  static ThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    return scope!.notifier!;
  }
}
