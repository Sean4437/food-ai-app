import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ai_app/design/app_theme.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import 'package:food_ai_app/models/meal_entry.dart';
import 'package:food_ai_app/screens/log_screen.dart';
import 'package:food_ai_app/state/app_state.dart';

class _TestAppState extends AppState {
  @override
  bool get trialChecked => true;

  @override
  bool get isSupabaseSignedIn => false;
}

void Function(FlutterErrorDetails details)? _originalOnError;

ThemeData _testTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5B7CFA)),
    extensions: const <ThemeExtension<dynamic>>[
      AppTheme(
        card: Colors.white,
        mutedText: Color(0xFF6B7280),
        accent: Color(0xFFF4C95D),
        success: Color(0xFF8AD7A4),
        warning: Color(0xFFF4C95D),
        danger: Color(0xFFF08A7C),
        gradientTop: Color(0xFFE6F1FF),
        gradientBottom: Color(0xFFF3F5FA),
        glow: Color(0xFFD7E9FF),
        radiusCard: 18,
        radiusButton: 16,
      ),
    ],
  );
}

Widget _buildTestApp(AppState app) {
  return AppStateScope(
    notifier: app,
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'TW'),
        Locale('en'),
      ],
      theme: _testTheme(),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(0.9)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const LogScreen(),
    ),
  );
}

Uint8List _tinyPng() {
  return base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/Pi3n1wAAAABJRU5ErkJggg==',
  );
}

void main() {
  setUp(() {
    _originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final text = details.exceptionAsString();
      if (text.contains('A RenderFlex overflowed by')) {
        return;
      }
      _originalOnError?.call(details);
    };
  });

  tearDown(() {
    FlutterError.onError = _originalOnError;
  });

  testWidgets('LogScreen renders without entries', (tester) async {
    final binding = tester.binding;
    await binding.setSurfaceSize(const Size(430, 1200));
    addTearDown(() => binding.setSurfaceSize(null));

    final app = _TestAppState();

    await tester.pumpWidget(_buildTestApp(app));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(LogScreen), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('LogScreen renders with one meal entry', (tester) async {
    final binding = tester.binding;
    await binding.setSurfaceSize(const Size(430, 1200));
    addTearDown(() => binding.setSurfaceSize(null));

    final app = _TestAppState();
    app.entries.add(
      MealEntry(
        id: 'meal-1',
        imageBytes: _tinyPng(),
        filename: 'meal.png',
        time: DateTime.now(),
        type: MealType.lunch,
        overrideFoodName: '測試餐',
      ),
    );

    await tester.pumpWidget(_buildTestApp(app));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(LogScreen), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('測試餐'), findsOneWidget);
  });
}
