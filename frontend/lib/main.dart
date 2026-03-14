import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
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
  bool _didEnsureInitialTab = false;
  late final PageController _dockController;
  double _dockPage = 2;
  int _lastDockTarget = 2;

  @override
  void initState() {
    super.initState();
    _dockController = PageController(initialPage: 2, viewportFraction: 0.3);
    _dockController.addListener(_onDockScroll);
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
    _dockController.removeListener(_onDockScroll);
    _dockController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onDockScroll() {
    if (!mounted || !_dockController.hasClients) return;
    final page = _dockController.page;
    if (page == null) return;
    if ((page - _dockPage).abs() < 0.001) return;
    setState(() => _dockPage = page);
  }

  void _animateDockTo(int index) {
    if (!_dockController.hasClients) return;
    final current =
        _dockController.page ?? _dockController.initialPage.toDouble();
    if ((current - index).abs() < 0.02) return;
    _dockController.animateToPage(
      index,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
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
    if (!_didEnsureInitialTab) {
      _didEnsureInitialTab = true;
      if (tabState.index != 2) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final currentTabState = TabScope.of(context);
          if (currentTabState.index != 2) {
            currentTabState.setIndex(2);
          }
        });
      }
    }

    const screens = [
      HomeScreen(),
      ChatScreen(),
      SuggestionsScreen(),
      LogScreen(),
      CustomFoodsScreen(),
      SettingsScreen(),
    ];

    final theme = Theme.of(context);
    final navItems = <_DockItem>[
      _DockItem(label: t.tabHome, icon: Icons.home_rounded),
      _DockItem(label: t.tabChat, icon: Icons.chat_bubble_rounded),
      _DockItem(label: t.tabSuggest, icon: Icons.auto_awesome_rounded),
      _DockItem(label: t.tabLog, icon: Icons.receipt_long_rounded),
      _DockItem(label: t.tabCustom, icon: Icons.restaurant_menu_rounded),
      _DockItem(label: t.tabSettings, icon: Icons.settings_rounded),
    ];

    final clampedIndex = tabState.index.clamp(0, screens.length - 1);
    if (_lastDockTarget != clampedIndex) {
      _lastDockTarget = clampedIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _animateDockTo(clampedIndex);
      });
    }

    return Scaffold(
      extendBody: true,
      body: screens[clampedIndex],
      bottomNavigationBar: _LinearRevolverDock(
        items: navItems,
        controller: _dockController,
        page: _dockPage,
        activeColor: theme.colorScheme.primary,
        inactiveColor: theme.colorScheme.onSurface.withValues(alpha: 0.45),
        onSelect: (index) {
          _lastDockTarget = index;
          tabState.setIndex(index);
          _animateDockTo(index);
        },
      ),
    );
  }
}

class _DockItem {
  const _DockItem({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}

class _LinearRevolverDock extends StatelessWidget {
  const _LinearRevolverDock({
    required this.items,
    required this.controller,
    required this.page,
    required this.activeColor,
    required this.inactiveColor,
    required this.onSelect,
  });

  final List<_DockItem> items;
  final PageController controller;
  final double page;
  final Color activeColor;
  final Color inactiveColor;
  final ValueChanged<int> onSelect;

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final effectiveBottom = math.max(bottomInset, 4.0);
    final glassTop = Color.lerp(scheme.surface, scheme.primary, 0.16)!
        .withValues(alpha: 0.52);
    final glassBottom = Color.lerp(scheme.surface, scheme.secondary, 0.1)!
        .withValues(alpha: 0.34);
    final borderColor = scheme.primary.withValues(alpha: 0.2);

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(18),
        topRight: Radius.circular(18),
      ),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          height: 76 + effectiveBottom,
          padding: EdgeInsets.fromLTRB(8, 6, 8, effectiveBottom),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [glassTop, glassBottom],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
            ),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: PageView.builder(
            controller: controller,
            itemCount: items.length,
            padEnds: true,
            physics: const BouncingScrollPhysics(),
            onPageChanged: onSelect,
            itemBuilder: (context, index) {
              final distance = (page - index).abs().clamp(0.0, 1.8);
              final focus = (1 - (distance / 1.8)).clamp(0.0, 1.0);
              final scale = _lerp(0.82, 1.06, focus);
              final opacity = _lerp(0.5, 1.0, focus);
              final labelOpacity = _lerp(0.5, 1.0, focus);
              final iconSize = _lerp(18, 26, focus);
              final isFocused = distance < 0.35;

              return Center(
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => onSelect(index),
                      child: SizedBox(
                        width: 72,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              curve: Curves.easeOut,
                              width: isFocused ? 46 : 38,
                              height: isFocused ? 46 : 38,
                              decoration: BoxDecoration(
                                color: isFocused
                                    ? activeColor.withValues(alpha: 0.16)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(23),
                              ),
                              child: Icon(
                                items[index].icon,
                                size: iconSize,
                                color: isFocused ? activeColor : inactiveColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              items[index].label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isFocused
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isFocused
                                    ? activeColor
                                    : inactiveColor.withValues(
                                        alpha: labelOpacity,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
