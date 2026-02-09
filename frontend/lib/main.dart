import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_screen.dart';
import 'screens/log_screen.dart';
import 'screens/suggestions_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/custom_foods_screen.dart';
import 'screens/login_screen.dart';
import 'screens/trial_expired_screen.dart';
import 'state/app_state.dart';
import 'design/theme_controller.dart';
import 'state/tab_state.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.ensureInitialized();
  final themeController = ThemeController();
  final tabState = TabState();
  final appState = AppState();
  await appState.init();
  final themeAsset = appState.profile.themeAsset.isEmpty
      ? 'assets/themes/theme_clean.json'
      : appState.profile.themeAsset;
  themeController.loadFromAsset(themeAsset);
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
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _requestedAccess = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        final app = AppStateScope.of(context);
        if (session == null) {
          _requestedAccess = false;
          return const LoginScreen();
        }
        if (!app.trialChecked) {
          if (!_requestedAccess) {
            _requestedAccess = true;
            // ignore: discarded_futures
            app.refreshAccessStatus();
          }
          return const MainShell();
        }
        if (app.trialExpired && !app.isWhitelisted) {
          return const TrialExpiredScreen();
        }
        return const MainShell();
      },
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  AppState? _app;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _app = AppStateScope.of(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final app = _app;
      if (app != null) {
        // ignore: discarded_futures
        app.runAutoFinalizeFlow();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final tabState = TabScope.of(context);
    final theme = Theme.of(context);
    final screens = const [
      HomeScreen(),
      ChatScreen(),
      SuggestionsScreen(),
      LogScreen(),
      CustomFoodsScreen(),
      SettingsScreen(),
    ];

    return Scaffold(
      body: screens[tabState.index],
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: tabState.index,
        activeColor: theme.colorScheme.primary,
        inactiveColor: theme.colorScheme.onSurface.withOpacity(0.6),
        onTap: (value) => tabState.setIndex(value),
        items: [
          BottomNavigationBarItem(
            icon: Builder(
              builder: (context) {
                final color = IconTheme.of(context).color;
                return Text('🏠', style: TextStyle(fontSize: 20, color: color));
              },
            ),
            label: t.tabHome,
          ),
          BottomNavigationBarItem(
            icon: Builder(
              builder: (context) {
                return Opacity(
                  opacity: 0.7,
                  child: Image.asset('assets/cat01.png', width: 24, height: 24),
                );
              },
            ),
            activeIcon: Image.asset('assets/cat01.png', width: 24, height: 24),
            label: t.tabChatAssistant,
          ),
          BottomNavigationBarItem(
            icon: Builder(
              builder: (context) {
                final color = IconTheme.of(context).color;
                return Text('📸', style: TextStyle(fontSize: 20, color: color));
              },
            ),
            label: t.tabSuggest,
          ),
          BottomNavigationBarItem(
            icon: Builder(
              builder: (context) {
                final color = IconTheme.of(context).color;
                return Text('🧾', style: TextStyle(fontSize: 20, color: color));
              },
            ),
            label: t.tabLog,
          ),
          BottomNavigationBarItem(
            icon: Builder(
              builder: (context) {
                final color = IconTheme.of(context).color;
                return Text('🍳', style: TextStyle(fontSize: 20, color: color));
              },
            ),
            label: t.tabCustom,
          ),
          BottomNavigationBarItem(
            icon: Builder(
              builder: (context) {
                final color = IconTheme.of(context).color;
                return Text('⚙️', style: TextStyle(fontSize: 20, color: color));
              },
            ),
            label: t.tabSettings,
          ),
        ],
      ),
    );
  }
}


