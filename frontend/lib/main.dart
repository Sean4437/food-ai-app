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
import 'state/tab_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeController = ThemeController();
  final tabState = TabState();
  final appState = AppState();
  await appState.init();
  final themeAsset = appState.profile.themeAsset.isEmpty
      ? 'assets/themes/theme_clean.json'
      : appState.profile.themeAsset;
  await themeController.loadFromAsset(themeAsset);
  themeController.applyColorOverrides(
    primaryHex: appState.profile.themePrimaryHex,
    cardHex: appState.profile.cardColorHex,
    backgroundTopHex: appState.profile.themeBackgroundTopHex,
    backgroundBottomHex: appState.profile.themeBackgroundBottomHex,
  );
  runApp(ThemeScope(
    notifier: themeController,
    child: TabScope(
      notifier: tabState,
      child: AppStateScope(
        notifier: appState,
        child: const FoodAiApp(),
      ),
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
      locale: AppStateScope.of(context).profile.language == 'en'
          ? const Locale('en')
          : const Locale('zh', 'TW'),
      builder: (context, child) {
        final data = MediaQuery.of(context);
        return MediaQuery(
          data: data.copyWith(textScaler: TextScaler.linear(AppStateScope.of(context).profile.textScale)),
          child: child ?? const SizedBox.shrink(),
        );
      },
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
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final tabState = TabScope.of(context);
    final screens = const [
      SuggestionsScreen(),
      HomeScreen(),
      LogScreen(),
      SettingsScreen(),
    ];

    return Scaffold(
      body: screens[tabState.index],
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: tabState.index,
        activeColor: const Color(0xFF5B7CFA),
        inactiveColor: Colors.black54,
        onTap: (value) => tabState.setIndex(value),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.camera_alt), label: t.tabSuggest),
          BottomNavigationBarItem(icon: const Icon(Icons.home_filled), label: t.tabHome),
          BottomNavigationBarItem(icon: const Icon(Icons.receipt_long), label: t.tabLog),
          BottomNavigationBarItem(icon: const Icon(Icons.settings), label: t.tabSettings),
        ],
      ),
    );
  }
}
