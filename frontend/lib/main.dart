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
import 'screens/week_plan_screen.dart';
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
  unawaited(themeController.loadFromAsset(kDefaultThemeAsset));
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
  unawaited(() async {
    await appState.init();
    final themeAsset = appState.profile.themeAsset.isEmpty
        ? kDefaultThemeAsset
        : appState.profile.themeAsset;
    await themeController.loadFromAsset(themeAsset);
  }());
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

  bool _looksLikeAuthLink(Uri uri) {
    bool hasAuthPayload(Map<String, String> params) {
      if (params.containsKey('type')) return true;
      if (params.containsKey('access_token')) return true;
      if (params.containsKey('refresh_token')) return true;
      if (params.containsKey('code')) return true;
      if (params.containsKey('token') || params.containsKey('token_hash')) {
        return true;
      }
      return false;
    }

    if (hasAuthPayload(uri.queryParameters)) return true;

    final fragment = uri.fragment;
    if (fragment.isEmpty) return false;
    final cleaned = fragment.startsWith('/') ? fragment.substring(1) : fragment;
    final queryPart = cleaned.contains('?') ? cleaned.split('?').last : cleaned;
    if (!queryPart.contains('=')) return false;
    final fragParams = Uri.splitQueryString(queryPart);
    return hasAuthPayload(fragParams);
  }

  String? _extractAuthParam(Uri target, String key) {
    final direct = target.queryParameters[key];
    if (direct != null && direct.isNotEmpty) return direct;
    final fragment = target.fragment;
    if (fragment.isEmpty) return null;
    final cleaned = fragment.startsWith('/') ? fragment.substring(1) : fragment;
    final queryPart = cleaned.contains('?') ? cleaned.split('?').last : cleaned;
    if (!queryPart.contains('=')) return null;
    final fragParams = Uri.splitQueryString(queryPart);
    final value = fragParams[key];
    return (value != null && value.isNotEmpty) ? value : null;
  }

  String? _extractAuthCode(Uri target) {
    return _extractAuthParam(target, 'code');
  }

  Future<void> _handleAuthLink(Uri uri) async {
    if (!_looksLikeAuthLink(uri)) return;
    if (_handlingRecoveryLink) return;
    _handlingRecoveryLink = true;
    final authType = _extractAuthParam(uri, 'type');
    final isRecovery = authType == 'recovery';
    try {
      final tokenHash = _extractAuthParam(uri, 'token') ??
          _extractAuthParam(uri, 'token_hash');
      if (tokenHash != null && isRecovery) {
        await Supabase.instance.client.auth.verifyOTP(
          tokenHash: tokenHash,
          type: OtpType.recovery,
        );
        if (mounted) setState(() => _showResetPassword = true);
        return;
      }

      final code = _extractAuthCode(uri);
      if (code != null) {
        await Supabase.instance.client.auth.exchangeCodeForSession(code);
        if (mounted && isRecovery) {
          setState(() => _showResetPassword = true);
        }
      } else {
        await Supabase.instance.client.auth.getSessionFromUrl(uri);
        if (mounted && isRecovery) {
          setState(() => _showResetPassword = true);
        }
      }
    } catch (_) {
      if (mounted && isRecovery) {
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
  bool _suppressDockPageChange = false;
  bool _isShowingNicknamePrompt = false;
  String? _nicknamePromptedUserId;
  late final PageController _dockController;
  double _dockPage = 1;
  int _lastDockTarget = 1;

  @override
  void initState() {
    super.initState();
    _dockController = PageController(initialPage: 1, viewportFraction: 0.3);
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

  Future<void> _animateDockTo(int index, {bool immediate = false}) async {
    if (!_dockController.hasClients) return;
    final current =
        _dockController.page ?? _dockController.initialPage.toDouble();
    if ((current - index).abs() < 0.02) return;
    _suppressDockPageChange = true;
    try {
      if (immediate || (current - index).abs() > 1.1) {
        _dockController.jumpToPage(index);
      } else {
        await _dockController.animateToPage(
          index,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      }
    } finally {
      _suppressDockPageChange = false;
    }
  }

  void _handleDockPageChanged(int index) {
    if (_suppressDockPageChange) return;
    final tabState = TabScope.of(context);
    _lastDockTarget = index;
    tabState.setIndex(index);
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
    scheduleMicrotask(() async {
      await app.runAutoFinalizeFlow();
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybePromptForNickname();
      });
    });
  }

  bool _isValidNickname(String value) {
    final nickname = value.trim();
    if (nickname.length < 2 || nickname.length > 24) return false;
    if (RegExp(r'[\x00-\x1F\x7F]').hasMatch(nickname)) return false;
    if (RegExp(r'[\u200B-\u200F\uFEFF]').hasMatch(nickname)) return false;
    return true;
  }

  Future<void> _maybePromptForNickname() async {
    if (!mounted || _isShowingNicknamePrompt) return;
    final app = _app;
    if (app == null || !app.isSupabaseSignedIn) return;
    if (app.profile.name.trim().isNotEmpty) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) return;
    if (_nicknamePromptedUserId == userId) return;

    final t = AppLocalizations.of(context)!;
    final isZh = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('zh');
    final controller = TextEditingController(text: app.profile.name.trim());
    String? errorText;
    bool saving = false;

    _isShowingNicknamePrompt = true;
    _nicknamePromptedUserId = userId;

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => StatefulBuilder(
          builder: (sheetContext, setState) {
            final scheme = Theme.of(sheetContext).colorScheme;
            return AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 28,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: 56,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.badge_outlined,
                          color: scheme.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isZh
                            ? '\u5148\u8a2d\u5b9a\u4f60\u7684\u66b1\u7a31'
                            : 'Set your nickname',
                        style: Theme.of(sheetContext)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isZh
                            ? '\u7b2c\u4e00\u6b21\u4f7f\u7528\u5148\u88dc\u4e00\u500b\u66b1\u7a31\uff0c\u4e4b\u5f8c\u9996\u9801\u3001\u804a\u5929\u8207\u7d00\u9304\u90fd\u6703\u7528\u5230\u3002'
                            : 'Add a nickname first. It will be used across home, chat, and logs.',
                        style: Theme.of(sheetContext)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.black54, height: 1.45),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: controller,
                        enabled: !saving,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: t.nicknameLabel,
                          hintText: isZh
                              ? '\u4f8b\u5982\uff1aSean'
                              : 'For example: Sean',
                          errorText: errorText,
                          filled: true,
                          fillColor: scheme.surfaceContainerHighest
                              .withValues(alpha: 0.45),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: scheme.primary.withValues(alpha: 0.6),
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isZh
                            ? '\u4e4b\u5f8c\u4e5f\u53ef\u4ee5\u5230\u8a2d\u5b9a\u9801\u4fee\u6539\u3002'
                            : 'You can change this later in Settings.',
                        style: Theme.of(sheetContext)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.black45),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: saving
                                  ? null
                                  : () => Navigator.of(sheetContext).pop(),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                isZh
                                    ? '\u7a0d\u5f8c\u518d\u8aaa'
                                    : 'Later',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: saving
                                  ? null
                                  : () async {
                                      final nickname = controller.text.trim();
                                      if (!_isValidNickname(nickname)) {
                                        setState(() {
                                          errorText = t.authNicknameInvalid;
                                        });
                                        return;
                                      }
                                      setState(() {
                                        saving = true;
                                        errorText = null;
                                      });
                                      try {
                                        await app.updateNickname(nickname);
                                        if (!sheetContext.mounted) return;
                                        Navigator.of(sheetContext).pop();
                                      } catch (_) {
                                        if (!sheetContext.mounted) return;
                                        setState(() {
                                          saving = false;
                                          errorText = isZh
                                              ? '\u66b1\u7a31\u66f4\u65b0\u5931\u6557\uff0c\u8acb\u7a0d\u5f8c\u518d\u8a66'
                                              : 'Failed to update nickname. Please try again later.';
                                        });
                                      }
                                    },
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      isZh
                                          ? '\u5132\u5b58'
                                          : 'Save',
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    } finally {
      controller.dispose();
      _isShowingNicknamePrompt = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final tabState = TabScope.of(context);

    const screens = [
      HomeScreen(),
      SuggestionsScreen(),
      LogScreen(),
      ChatScreen(),
      WeekPlanScreen(),
      CustomFoodsScreen(),
      SettingsScreen(),
    ];

    final theme = Theme.of(context);
    final isZh = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('zh');
    final navItems = <_DockItem>[
      _DockItem(label: t.tabHome, icon: Icons.home_rounded),
      _DockItem(label: t.tabSuggest, icon: Icons.auto_awesome_rounded),
      _DockItem(label: t.tabLog, icon: Icons.receipt_long_rounded),
      _DockItem(label: t.tabChat, icon: Icons.chat_bubble_rounded),
      _DockItem(
        label: isZh ? '\u0037\u5929\u898f\u5283' : '7-day plan',
        icon: Icons.calendar_view_week_rounded,
      ),
      _DockItem(label: t.tabCustom, icon: Icons.restaurant_menu_rounded),
      _DockItem(label: t.tabSettings, icon: Icons.settings_rounded),
    ];

    final clampedIndex = tabState.index.clamp(0, screens.length - 1);
    if (_lastDockTarget != clampedIndex) {
      _lastDockTarget = clampedIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _animateDockTo(clampedIndex, immediate: true);
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
        onPageChanged: _handleDockPageChanged,
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
    required this.onPageChanged,
    required this.onSelect,
  });

  final List<_DockItem> items;
  final PageController controller;
  final double page;
  final Color activeColor;
  final Color inactiveColor;
  final ValueChanged<int> onPageChanged;
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
            onPageChanged: onPageChanged,
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
