import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'screens/home_screen.dart';
import 'screens/log_screen.dart';
import 'screens/suggestions_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/custom_foods_screen.dart';
import 'screens/login_screen.dart';
import 'screens/reset_password_screen.dart';
import 'state/app_state.dart';
import 'design/theme_controller.dart';
import 'state/tab_state.dart';
import 'services/supabase_service.dart';
import 'widgets/revolver_tab_bar.dart';

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
          data: data.copyWith(
              textScaler: TextScaler.linear(
                  AppStateScope.of(context).profile.textScale)),
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
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<AuthState>? _authSub;
  StreamSubscription<Uri>? _linkSub;
  bool _showResetPassword = false;
  bool _handlingRecoveryLink = false;

  @override
  void initState() {
    super.initState();
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.passwordRecovery) {
        if (mounted) {
          setState(() => _showResetPassword = true);
        }
      }
    });
    _initAuthLinks();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _linkSub?.cancel();
    super.dispose();
  }

  Future<void> _initAuthLinks() async {
    if (kIsWeb) {
      await _handleAuthLink(Uri.base);
      return;
    }
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        await _handleAuthLink(initial);
      }
      _linkSub = _appLinks.uriLinkStream.listen((uri) {
        _handleAuthLink(uri);
      });
    } catch (_) {}
  }

  bool _looksLikeRecovery(Uri uri) {
    bool hasRecovery(Map<String, String> params) {
      if (params['type'] == 'recovery') return true;
      if (params.containsKey('access_token')) return true;
      if (params.containsKey('refresh_token')) return true;
      if (params.containsKey('code')) return true;
      if (params.containsKey('token') || params.containsKey('token_hash')) {
        return true;
      }
      return false;
    }

    if (hasRecovery(uri.queryParameters)) return true;

    final fragment = uri.fragment;
    if (fragment.isEmpty) return false;
    final cleaned = fragment.startsWith('/') ? fragment.substring(1) : fragment;
    final queryPart = cleaned.contains('?') ? cleaned.split('?').last : cleaned;
    if (!queryPart.contains('=')) return false;
    final fragParams = Uri.splitQueryString(queryPart);
    return hasRecovery(fragParams);
  }

  Future<void> _handleAuthLink(Uri uri) async {
    if (!_looksLikeRecovery(uri)) return;
    if (_handlingRecoveryLink) return;
    _handlingRecoveryLink = true;
    try {
      String? extractParam(Uri target, String key) {
        final direct = target.queryParameters[key];
        if (direct != null && direct.isNotEmpty) return direct;
        final fragment = target.fragment;
        if (fragment.isEmpty) return null;
        final cleaned =
            fragment.startsWith('/') ? fragment.substring(1) : fragment;
        final queryPart =
            cleaned.contains('?') ? cleaned.split('?').last : cleaned;
        if (!queryPart.contains('=')) return null;
        final fragParams = Uri.splitQueryString(queryPart);
        final value = fragParams[key];
        return (value != null && value.isNotEmpty) ? value : null;
      }

      final tokenHash =
          extractParam(uri, 'token') ?? extractParam(uri, 'token_hash');
      final type = extractParam(uri, 'type');
      if (tokenHash != null && (type == null || type == 'recovery')) {
        await Supabase.instance.client.auth.verifyOTP(
          tokenHash: tokenHash,
          type: OtpType.recovery,
        );
        if (mounted) setState(() => _showResetPassword = true);
        return;
      }

      String? extractCode(Uri target) {
        final code = target.queryParameters['code'];
        if (code != null && code.isNotEmpty) return code;
        final fragment = target.fragment;
        if (fragment.isEmpty) return null;
        final cleaned =
            fragment.startsWith('/') ? fragment.substring(1) : fragment;
        final queryPart =
            cleaned.contains('?') ? cleaned.split('?').last : cleaned;
        if (!queryPart.contains('=')) return null;
        final fragParams = Uri.splitQueryString(queryPart);
        final fragCode = fragParams['code'];
        return fragCode != null && fragCode.isNotEmpty ? fragCode : null;
      }

      final code = extractCode(uri);
      if (code != null) {
        await Supabase.instance.client.auth.exchangeCodeForSession(code);
        if (mounted) setState(() => _showResetPassword = true);
      } else {
        await Supabase.instance.client.auth.getSessionFromUrl(uri);
        if (mounted) {
          setState(() => _showResetPassword = true);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _showResetPassword = true);
      }
    } finally {
      _handlingRecoveryLink = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showResetPassword) {
      return ResetPasswordScreen(
        onDone: () {
          if (mounted) {
            setState(() => _showResetPassword = false);
          }
        },
      );
    }
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
  bool _didRunInitialAutoFlow = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _app = AppStateScope.of(context);
    if (!_didRunInitialAutoFlow) {
      _didRunInitialAutoFlow = true;
      _triggerAutoFlows();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _triggerAutoFlows();
    }
  }

  void _triggerAutoFlows() {
    final app = _app;
    if (app == null) return;
    final t = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    scheduleMicrotask(() async {
      await app.runAutoFinalizeFlow();
      await app.runAutoMealChatReminder(t, locale);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final tabState = TabScope.of(context);
    const screens = [
      HomeScreen(),
      ChatScreen(),
      SuggestionsScreen(),
      LogScreen(),
      CustomFoodsScreen(),
      SettingsScreen(),
    ];

    return Scaffold(
      body: screens[tabState.index],
      bottomNavigationBar: RevolverTabBar(
        currentIndex: tabState.index,
        onSelect: (value) => tabState.setIndex(value),
        items: [
          RevolverTabItem(
            label: t.tabHome,
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
          ),
          RevolverTabItem(
            label: t.tabChat,
            assetImage: 'assets/cat01.png',
          ),
          RevolverTabItem(
            label: t.tabSuggest,
            icon: Icons.auto_awesome_outlined,
            activeIcon: Icons.auto_awesome_rounded,
          ),
          RevolverTabItem(
            label: t.tabLog,
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long_rounded,
          ),
          RevolverTabItem(
            label: t.tabCustom,
            icon: Icons.restaurant_menu_outlined,
            activeIcon: Icons.restaurant_menu,
          ),
          RevolverTabItem(
            label: t.tabSettings,
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings,
          ),
        ],
      ),
    );
  }
}
