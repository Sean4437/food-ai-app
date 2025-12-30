import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/log_screen.dart';
import 'screens/suggestions_screen.dart';
import 'screens/settings_screen.dart';
import 'state/app_state.dart';
import 'design/theme_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final themeController = ThemeController();
  themeController.loadFromAsset('assets/themes/theme_clean.json');
  runApp(ThemeScope(
    notifier: themeController,
    child: AppStateScope(
      notifier: AppState(),
      child: const FoodAiApp(),
    ),
  ));
}

class FoodAiApp extends StatelessWidget {
  const FoodAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food AI MVP',
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
      theme: ThemeScope.of(context).theme,
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final screens = const [
      HomeScreen(),
      LogScreen(),
      SuggestionsScreen(),
      SettingsScreen(),
    ];

    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: _index,
        activeColor: const Color(0xFF5B7CFA),
        inactiveColor: Colors.black54,
        onTap: (value) => setState(() => _index = value),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home_filled), label: t.tabHome),
          BottomNavigationBarItem(icon: const Icon(Icons.receipt_long), label: t.tabLog),
          BottomNavigationBarItem(icon: const Icon(Icons.lightbulb), label: t.tabSuggest),
          BottomNavigationBarItem(icon: const Icon(Icons.settings), label: t.tabSettings),
        ],
      ),
    );
  }
}
