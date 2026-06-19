import 'package:flutter/material.dart';
import 'dart:async';
import 'package:food_ai_app/gen/app_localizations.dart';
import '../design/text_styles.dart';
import '../widgets/app_background.dart';
import '../state/app_state.dart';

enum _LoginMode { magicLink, password, signUp }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _nicknameController = TextEditingController();
  _LoginMode _mode = _LoginMode.magicLink;
  bool _loading = false;
  bool _showPassword = false;
  bool _showConfirm = false;
  bool _showVerifyPanel = false;
  int _resendCooldown = 0;
  DateTime? _lastAuthAttempt;
  Timer? _resendTimer;
  String? _inlineEmailError;
  String? _inlinePasswordError;
  String? _inlineNicknameError;
  String? _bannerMessage;
  bool _bannerIsError = false;
  List<String> _rememberedEmails = const [];
  String? _magicLinkSentEmail;

  bool get _isSignUpMode => _mode == _LoginMode.signUp;
  bool get _isPasswordMode => _mode == _LoginMode.password;
  bool get _isMagicLinkMode => _mode == _LoginMode.magicLink;
  bool get _isMagicLinkSuccessState =>
      _isMagicLinkMode && _magicLinkSentEmail != null;

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      if (!mounted) return;
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final app = AppStateScope.of(context);
      _refreshRememberedEmails(app, fillWhenEmpty: true);
    });
  }

  void _refreshRememberedEmails(AppState app, {bool fillWhenEmpty = false}) {
    final remembered = app.rememberedAuthEmails;
    if (!mounted) return;
    setState(() => _rememberedEmails = remembered);
    if (fillWhenEmpty &&
        remembered.isNotEmpty &&
        _emailController.text.trim().isEmpty) {
      _fillEmail(remembered.first);
    }
  }

  void _fillEmail(String email) {
    _emailController.text = email;
    _emailController.selection =
        TextSelection.fromPosition(TextPosition(offset: email.length));
    if (_inlineEmailError != null) {
      _setInlineEmailError(null);
    }
  }

  List<String> _filteredRememberedEmails() {
    if (_rememberedEmails.isEmpty) return const [];
    final query = _emailController.text.trim().toLowerCase();
    if (query.isEmpty) return List<String>.from(_rememberedEmails);
    final ranked = _rememberedEmails
        .asMap()
        .entries
        .where((entry) => entry.value.toLowerCase().contains(query))
        .toList();
    int score(String email) {
      final lower = email.toLowerCase();
      if (lower.startsWith(query)) return 0;
      return 1;
    }

    ranked.sort((a, b) {
      final byScore = score(a.value).compareTo(score(b.value));
      if (byScore != 0) return byScore;
      return a.key.compareTo(b.key);
    });
    return ranked.map((entry) => entry.value).toList();
  }

  void _removeRememberedEmail(AppState app, String email) {
    app.removeRememberedAuthEmail(email);
    _refreshRememberedEmails(app);
  }

  bool _isValidEmail(String value) {
    final email = value.trim();
    if (email.isEmpty) return false;
    // Basic structure check + enforce TLD >= 2 chars.
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$').hasMatch(email)) return false;
    // Global length limits.
    if (email.length > 254) return false;
    if (email.contains('..')) return false;
    final parts = email.split('@');
    if (parts.length != 2) return false;
    final local = parts[0];
    final domain = parts[1];
    if (local.isEmpty || domain.isEmpty) return false;
    if (local.length > 64) return false;
    if (local.startsWith('.') || local.endsWith('.')) return false;
    if (domain.startsWith('.') || domain.endsWith('.')) return false;
    // Domain labels must not be empty or start/end with '-'.
    final labels = domain.split('.');
    if (labels.any((label) => label.isEmpty)) return false;
    if (labels.any((label) => label.startsWith('-') || label.endsWith('-'))) {
      return false;
    }
    return true;
  }

  bool _isValidPassword(String value) {
    if (value.length < 8) return false;
    if (value.contains(RegExp(r'\s'))) return false;
    if (value.contains(RegExp(r'[\u4e00-\u9fff\u3400-\u4dbf\uf900-\ufaff]'))) {
      return false;
    }
    return true;
  }

  bool _isValidNickname(String value) {
    final nickname = value.trim();
    if (nickname.length < 2 || nickname.length > 24) return false;
    if (RegExp(r'[\x00-\x1F\x7F]').hasMatch(nickname)) return false;
    if (RegExp(r'[\u200B-\u200F\uFEFF]').hasMatch(nickname)) return false;
    return true;
  }

  bool _isZh() {
    return Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('zh');
  }

  bool _isNetworkError(String text) {
    final lower = text.toLowerCase();
    return lower.contains('socketexception') ||
        lower.contains('timeout') ||
        lower.contains('failed host lookup') ||
        lower.contains('clientexception') ||
        lower.contains('network');
  }

  String _screenTitle(AppLocalizations t) {
    switch (_mode) {
      case _LoginMode.magicLink:
        return _isZh() ? '\u767b\u5165 Food AI' : 'Sign in to Food AI';
      case _LoginMode.password:
        return _isZh() ? '\u5bc6\u78bc\u767b\u5165' : 'Sign in with password';
      case _LoginMode.signUp:
        return _isZh() ? '\u5efa\u7acb\u5e33\u865f' : 'Create account';
    }
  }

  String _screenSubtitle(AppLocalizations t) {
    switch (_mode) {
      case _LoginMode.magicLink:
        return _isZh()
            ? '\u8f38\u5165 Email\uff0c\u6211\u5011\u6703\u5bc4\u767b\u5165\u9023\u7d50\u7d66\u4f60\uff0c\u7b2c\u4e00\u6b21\u4f7f\u7528\u6703\u81ea\u52d5\u5efa\u7acb\u5e33\u865f'
            : 'Enter your email and we will send you a sign-in link. First-time use will create your account automatically.';
      case _LoginMode.password:
        return _isZh()
            ? '\u8f38\u5165\u5bc6\u78bc\u767b\u5165\u4f60\u7684 Food AI \u5e33\u865f'
            : 'Use your password to sign in to Food AI.';
      case _LoginMode.signUp:
        return _isZh()
            ? '\u5148\u5efa\u7acb\u5e33\u865f\uff0c\u4e4b\u5f8c\u53ef\u4ee5\u7528\u9023\u7d50\u6216\u5bc6\u78bc\u767b\u5165'
            : 'Create your account first, then sign in with a link or password.';
    }
  }

  void _switchMode(_LoginMode mode) {
    FocusScope.of(context).unfocus();
    setState(() {
      _mode = mode;
      _showPassword = false;
      _showConfirm = false;
      _bannerMessage = null;
      _bannerIsError = false;
      _inlineEmailError = null;
      _inlinePasswordError = null;
      _inlineNicknameError = null;
      if (mode != _LoginMode.magicLink) {
        _magicLinkSentEmail = null;
      }
    });
  }

  void _resetMagicLinkSentState() {
    setState(() => _magicLinkSentEmail = null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _emailFocusNode.requestFocus();
    });
  }

  String _classifyResetErrorCode(Object err) {
    final lower = err.toString().toLowerCase();
    if (_isNetworkError(lower)) return 'network';
    if (lower.contains('rate limit') || lower.contains('too many')) {
      return 'rate_limited';
    }
    if (lower.contains('expired') ||
        lower.contains('invalid') ||
        lower.contains('otp')) {
      return 'link_expired';
    }
    if (lower.contains('not found') || lower.contains('user')) {
      return 'email_not_found';
    }
    return 'unknown';
  }

  String _classifyMagicLinkErrorCode(Object err) {
    final lower = err.toString().toLowerCase();
    if (_isNetworkError(lower)) return 'network';
    if (lower.contains('rate limit') || lower.contains('too many')) {
      return 'rate_limited';
    }
    if (lower.contains('email not confirmed') ||
        lower.contains('confirm your email') ||
        lower.contains('email not verified') ||
        lower.contains('verification')) {
      return 'email_not_verified';
    }
    if (lower.contains('user not found') ||
        lower.contains('not found') ||
        lower.contains('not registered') ||
        lower.contains('signup disabled') ||
        lower.contains('no user')) {
      return 'email_not_found';
    }
    return 'unknown';
  }

  String _formatMagicLinkError(Object err, AppLocalizations t) {
    final code = _classifyMagicLinkErrorCode(err);
    switch (code) {
      case 'network':
        return t.authNetworkError;
      case 'email_not_verified':
        return t.authEmailNotVerified;
      case 'email_not_found':
        return _isZh()
            ? '\u9019\u500b Email \u76ee\u524d\u7121\u6cd5\u4f7f\u7528\u767b\u5165\u9023\u7d50\uff0c\u8acb\u7a0d\u5f8c\u518d\u8a66\u6216\u6539\u7528\u5bc6\u78bc\u767b\u5165'
            : 'This email cannot use a sign-in link right now. Please try again later or sign in with your password.';
      case 'rate_limited':
        return _isZh()
            ? '\u5bc4\u9001\u592a\u983b\u7e41\uff0c\u8acb\u7a0d\u5f8c\u518d\u8a66'
            : 'Too many requests. Please try again later.';
      default:
        return _isZh()
            ? '\u5bc4\u9001\u767b\u5165\u9023\u7d50\u5931\u6557\uff0c\u8acb\u7a0d\u5f8c\u518d\u8a66\uff0c\u6216\u6539\u7528\u5bc6\u78bc\u767b\u5165'
            : 'Failed to send sign-in link. Please try again later, or sign in with your password.';
    }
  }

  String _formatAuthError(Object err, AppLocalizations t,
      {required bool isSignUp}) {
    final text = err.toString();
    final lower = text.toLowerCase();
    if (_isNetworkError(text)) return t.authNetworkError;
    if (lower.contains('email not confirmed') ||
        lower.contains('confirm your email')) {
      return t.authEmailNotVerified;
    }
    if (isSignUp) {
      if (lower.contains('invalid email') ||
          lower.contains('not a valid email') ||
          lower.contains('validate email') ||
          lower.contains('email is invalid')) {
        return t.authEmailInvalid;
      }
      if (lower.contains('password') && lower.contains('least')) {
        return t.authPasswordInvalid;
      }
      if (lower.contains('already registered') ||
          lower.contains('already exists') ||
          lower.contains('user exists')) {
        return t.authEmailExists;
      }
      return t.authSignUpFailed;
    }
    if (lower.contains('invalid login') ||
        lower.contains('invalid credentials') ||
        lower.contains('invalid email or password')) {
      return t.authLoginInvalid;
    }
    return t.authError;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _nicknameController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _showBanner(String message, {bool isError = false}) {
    setState(() {
      _bannerMessage = message;
      _bannerIsError = isError;
    });
  }

  void _clearBanner() {
    if (_bannerMessage == null) return;
    setState(() {
      _bannerMessage = null;
      _bannerIsError = false;
    });
  }

  void _setInlineEmailError(String? message) {
    setState(() => _inlineEmailError = message);
  }

  void _setInlinePasswordError(String? message) {
    setState(() => _inlinePasswordError = message);
  }

  void _setInlineNicknameError(String? message) {
    setState(() => _inlineNicknameError = message);
  }

  void _clearInlineErrors() {
    if (_inlineEmailError == null &&
        _inlinePasswordError == null &&
        _inlineNicknameError == null) {
      return;
    }
    setState(() {
      _inlineEmailError = null;
      _inlinePasswordError = null;
      _inlineNicknameError = null;
    });
  }

  Future<void> _submit() async {
    if (_loading) return;
    final t = AppLocalizations.of(context)!;
    final app = AppStateScope.of(context);
    _clearBanner();
    _clearInlineErrors();
    if (_lastAuthAttempt != null &&
        DateTime.now().difference(_lastAuthAttempt!) <
            const Duration(seconds: 2)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.authTooManyAttempts)));
      return;
    }
    _lastAuthAttempt = DateTime.now();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    final nickname = _nicknameController.text.trim();
    if (email.isEmpty) {
      _setInlineEmailError(t.authEmailRequired);
      return;
    }
    if (!_isValidEmail(email)) {
      _setInlineEmailError(t.authEmailInvalid);
      return;
    }
    app.rememberAuthEmail(email);
    _refreshRememberedEmails(app);
    if (password.isEmpty) {
      _setInlinePasswordError(t.authPasswordRequired);
      return;
    }
    if (_isSignUpMode && !_isValidPassword(password)) {
      _setInlinePasswordError(t.authPasswordInvalid);
      return;
    }
    if (_isSignUpMode && password != confirm) {
      _setInlinePasswordError(t.authPasswordMismatch);
      return;
    }
    if (_isSignUpMode && nickname.isEmpty) {
      _setInlineNicknameError(t.authNicknameRequired);
      return;
    }
    if (_isSignUpMode && !_isValidNickname(nickname)) {
      _setInlineNicknameError(t.authNicknameInvalid);
      return;
    }
    setState(() => _loading = true);
    try {
      if (_isSignUpMode) {
        await app.signUpSupabase(email, password, nickname: nickname);
      } else {
        await app.signInSupabase(email, password);
      }
      if (mounted) {
        _refreshRememberedEmails(app);
        final message = _isSignUpMode ? t.authSignUpVerify : t.authSignInSuccess;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
        if (_isSignUpMode) {
          setState(() {
            _showVerifyPanel = true;
            _resendCooldown = 30;
          });
          _startResendCooldown();
        }
      }
    } catch (err) {
      if (mounted) {
        final message = _formatAuthError(err, t, isSignUp: _isSignUpMode);
        if (!_isSignUpMode && message == t.authLoginInvalid) {
          _setInlinePasswordError(message);
        } else if (_isSignUpMode && message == t.authEmailInvalid) {
          _setInlineEmailError(message);
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));
        }
        if (!_isSignUpMode && message == t.authEmailNotVerified) {
          setState(() {
            _showVerifyPanel = true;
            _resendCooldown = 0;
          });
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldown <= 0) {
        timer.cancel();
        return;
      }
      setState(() => _resendCooldown -= 1);
    });
  }

  Future<void> _resendVerification() async {
    if (_loading || _resendCooldown > 0) return;
    final t = AppLocalizations.of(context)!;
    final app = AppStateScope.of(context);
    _clearBanner();
    _clearInlineErrors();
    final email = _emailController.text.trim();
    if (email.isEmpty || !_isValidEmail(email)) {
      _setInlineEmailError(t.authEmailInvalid);
      return;
    }
    app.rememberAuthEmail(email);
    _refreshRememberedEmails(app);
    setState(() => _loading = true);
    try {
      await app.resendVerificationEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.authResendSent)));
      setState(() {
        _showVerifyPanel = true;
        _resendCooldown = 30;
      });
      _startResendCooldown();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(t.authResendFailed)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_loading) return;
    final t = AppLocalizations.of(context)!;
    final app = AppStateScope.of(context);
    _clearBanner();
    _clearInlineErrors();
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _setInlineEmailError(t.authEmailRequired);
      return;
    }
    if (!_isValidEmail(email)) {
      _setInlineEmailError(t.authEmailInvalid);
      return;
    }
    app.rememberAuthEmail(email);
    _refreshRememberedEmails(app);
    setState(() => _loading = true);
    try {
      await app.resetSupabasePassword(email);
      if (mounted) {
        _showBanner(t.authResetSent, isError: false);
      }
    } catch (err) {
      if (mounted) {
        final code = _classifyResetErrorCode(err);
        _showBanner('${t.authResetFailed} ($code)', isError: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendMagicLink() async {
    if (_loading) return;
    final t = AppLocalizations.of(context)!;
    final app = AppStateScope.of(context);
    _clearBanner();
    _clearInlineErrors();
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _setInlineEmailError(t.authEmailRequired);
      return;
    }
    if (!_isValidEmail(email)) {
      _setInlineEmailError(t.authEmailInvalid);
      return;
    }
    app.rememberAuthEmail(email);
    _refreshRememberedEmails(app);
    setState(() => _loading = true);
    try {
      await app.sendMagicLink(email);
      if (!mounted) return;
      _refreshRememberedEmails(app);
      _emailFocusNode.unfocus();
      setState(() {
        _magicLinkSentEmail = email;
        _bannerMessage = null;
        _bannerIsError = false;
      });
    } catch (err) {
      if (!mounted) return;
      final message = _formatMagicLinkError(err, t);
      _showBanner(message, isError: true);
      if (message == t.authEmailNotVerified) {
        setState(() {
          _showVerifyPanel = true;
          _resendCooldown = 0;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildBanner(BuildContext context) {
    if (_bannerMessage == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _bannerIsError
            ? const Color(0xFFFFE7E5)
            : const Color(0xFFE6F6EF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _bannerIsError
              ? const Color(0xFFF3B3AC)
              : const Color(0xFFBDE4D1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _bannerMessage ?? '',
              style: AppTextStyles.caption(context).copyWith(
                color: _bannerIsError
                    ? const Color(0xFFB42318)
                    : const Color(0xFF1E7A53),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: _clearBanner,
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField(
    BuildContext context,
    AppLocalizations t,
  ) {
    return TextField(
      controller: _emailController,
      focusNode: _emailFocusNode,
      keyboardType: TextInputType.emailAddress,
      enabled: !_loading,
      onChanged: (_) {
        if (_inlineEmailError != null) {
          _setInlineEmailError(null);
        } else {
          setState(() {});
        }
      },
      decoration: InputDecoration(
        labelText: t.authEmailLabel,
        hintText: _isZh()
            ? '\u4f8b\u5982\uff1asean@example.com'
            : 'For example: sean@example.com',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        errorText: _inlineEmailError,
      ),
    );
  }

  Widget _buildEmailSuggestions(
    BuildContext context,
    AppState app,
    List<String> emailSuggestions,
  ) {
    return TextFieldTapRegion(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 160),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: emailSuggestions.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, thickness: 1),
          itemBuilder: (context, index) {
            final email = emailSuggestions[index];
            return ListTile(
              dense: true,
              leading: const Icon(
                Icons.history,
                size: 18,
                color: Colors.black45,
              ),
              title: Text(
                email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(
                  Icons.close,
                  size: 18,
                  color: Colors.black45,
                ),
                onPressed: () => _removeRememberedEmail(app, email),
              ),
              onTap: () {
                _fillEmail(email);
                _emailFocusNode.unfocus();
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildPasswordField(AppLocalizations t, {required bool showRule}) {
    return TextField(
      controller: _passwordController,
      obscureText: !_showPassword,
      enabled: !_loading,
      onChanged: (_) {
        if (_inlinePasswordError != null) {
          _setInlinePasswordError(null);
        }
      },
      decoration: InputDecoration(
        labelText: t.authPasswordLabel,
        helperText: showRule ? t.authPasswordRule : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        errorText: _inlinePasswordError,
        suffixIcon: IconButton(
          icon: Icon(
            _showPassword ? Icons.visibility_off_outlined : Icons.visibility,
          ),
          onPressed:
              _loading ? null : () => setState(() => _showPassword = !_showPassword),
        ),
      ),
    );
  }

  Widget _buildConfirmPasswordField(AppLocalizations t) {
    return TextField(
      controller: _confirmController,
      obscureText: !_showConfirm,
      enabled: !_loading,
      onChanged: (_) {
        if (_inlinePasswordError != null) {
          _setInlinePasswordError(null);
        }
      },
      decoration: InputDecoration(
        labelText: t.authConfirmPasswordLabel,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        suffixIcon: IconButton(
          icon: Icon(
            _showConfirm ? Icons.visibility_off_outlined : Icons.visibility,
          ),
          onPressed:
              _loading ? null : () => setState(() => _showConfirm = !_showConfirm),
        ),
      ),
    );
  }

  Widget _buildMagicLinkSuccessCard(BuildContext context) {
    final email = _magicLinkSentEmail ?? _emailController.text.trim();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FBF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8EDE1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.mark_email_read_outlined,
            size: 30,
            color: Color(0xFF1E7A53),
          ),
          const SizedBox(height: 10),
          Text(
            _isZh()
                ? '\u767b\u5165\u9023\u7d50\u5df2\u5bc4\u51fa'
                : 'Sign-in link sent',
            textAlign: TextAlign.center,
            style: AppTextStyles.body(context)
                .copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            email,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption(context).copyWith(
              color: const Color(0xFF1F2937),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isZh()
                ? '\u8acb\u5230\u4fe1\u7bb1\u958b\u555f\u9023\u7d50\u3002\u5982\u679c\u9019\u662f\u7b2c\u4e00\u6b21\u4f7f\u7528\uff0c\u9ede\u64ca\u5f8c\u6703\u81ea\u52d5\u5efa\u7acb\u5e33\u865f\uff1b\u5982\u679c\u6c92\u770b\u5230\uff0c\u8acb\u9806\u4fbf\u6aa2\u67e5\u5783\u573e\u90f5\u4ef6'
                : 'Open the link in your inbox. If this is your first time, clicking it will create your account automatically. If you do not see it, check spam as well.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption(context)
                .copyWith(color: Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _loading ? null : _sendMagicLink,
            icon: const Icon(Icons.refresh),
            label: Text(
              _isZh()
                  ? '\u91cd\u65b0\u5bc4\u9001\u767b\u5165\u9023\u7d50'
                  : 'Resend sign-in link',
            ),
          ),
          TextButton(
            onPressed: _loading ? null : _resetMagicLinkSentState,
            child: Text(
              _isZh() ? '\u66f4\u63db Email' : 'Use another email',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyPanel(BuildContext context, AppLocalizations t) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.authVerifyTitle,
            style:
                AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            t.authVerifyBody(_emailController.text.trim()),
            style: AppTextStyles.caption(context)
                .copyWith(color: Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _loading || _resendCooldown > 0
                      ? null
                      : _resendVerification,
                  child: Text(
                    _resendCooldown > 0
                        ? t.authResendCooldown(_resendCooldown)
                        : t.authResend,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppStateScope.of(context);
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final cardWidth = (media.size.width - 32).clamp(280.0, 420.0);
    final emailSuggestions = _filteredRememberedEmails();
    final showEmailSuggestions = !_isMagicLinkSuccessState &&
        _emailFocusNode.hasFocus &&
        !_loading &&
        emailSuggestions.isNotEmpty;
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: cardWidth),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _screenTitle(t),
                      style: AppTextStyles.title1(context),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _screenSubtitle(t),
                      style: AppTextStyles.caption(context)
                          .copyWith(color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                    if (_bannerMessage != null) ...[
                      const SizedBox(height: 12),
                      _buildBanner(context),
                    ],
                    const SizedBox(height: 16),
                    if (_isMagicLinkSuccessState) ...[
                      _buildMagicLinkSuccessCard(context),
                    ] else ...[
                      _buildEmailField(context, t),
                      if (showEmailSuggestions) ...[
                        const SizedBox(height: 6),
                        _buildEmailSuggestions(context, app, emailSuggestions),
                      ],
                    ],
                    if (_isPasswordMode || _isSignUpMode) ...[
                      const SizedBox(height: 10),
                      _buildPasswordField(t, showRule: _isSignUpMode),
                    ],
                    if (_isSignUpMode) ...[
                      const SizedBox(height: 10),
                      _buildConfirmPasswordField(t),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _nicknameController,
                        enabled: !_loading,
                        onChanged: (_) {
                          if (_inlineNicknameError != null) {
                            _setInlineNicknameError(null);
                          }
                        },
                        decoration: InputDecoration(
                          labelText: t.nicknameLabel,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          errorText: _inlineNicknameError,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: _loading
                          ? null
                          : (_isMagicLinkMode ? _sendMagicLink : _submit),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _isMagicLinkMode
                            ? (_isZh()
                                ? '\u5bc4\u9001\u767b\u5165\u9023\u7d50'
                                : 'Send sign-in link')
                            : (_isSignUpMode ? t.authSignUp : t.authSignIn),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (_isMagicLinkMode && !_isMagicLinkSuccessState) ...[
                      const SizedBox(height: 8),
                      Text(
                        _isZh()
                            ? '\u4e0d\u7528\u5bc6\u78bc\uff0c\u5f9e\u4fe1\u7bb1\u9ede\u4e00\u4e0b\u5c31\u80fd\u767b\u5165\uff0c\u7b2c\u4e00\u6b21\u4f7f\u7528\u4e5f\u53ef\u4ee5\u76f4\u63a5\u958b\u59cb'
                            : 'No password needed. Open the email link to sign in, even on your first visit.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption(context)
                            .copyWith(color: Colors.black54),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 4,
                        children: [
                          TextButton(
                            onPressed: _loading
                                ? null
                                : () => _switchMode(_LoginMode.password),
                            child: Text(
                              _isZh()
                                  ? '\u7528\u5bc6\u78bc\u767b\u5165'
                                  : 'Use password instead',
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_isMagicLinkSuccessState) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 4,
                        children: [
                          TextButton(
                            onPressed: _loading
                                ? null
                                : () => _switchMode(_LoginMode.password),
                            child: Text(
                              _isZh()
                                  ? '\u6539\u7528\u5bc6\u78bc\u767b\u5165'
                                  : 'Sign in with password',
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_isPasswordMode) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 4,
                        children: [
                          TextButton(
                            onPressed: _loading
                                ? null
                                : () => _switchMode(_LoginMode.magicLink),
                            child: Text(
                              _isZh()
                                  ? '\u6539\u7528\u767b\u5165\u9023\u7d50'
                                  : 'Use sign-in link instead',
                            ),
                          ),
                          TextButton(
                            onPressed: _loading ? null : _resetPassword,
                            child: Text(t.authForgotPassword),
                          ),
                        ],
                      ),
                    ],
                    if (_isSignUpMode) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 4,
                        children: [
                          TextButton(
                            onPressed: _loading
                                ? null
                                : () => _switchMode(_LoginMode.magicLink),
                            child: Text(
                              _isZh()
                                  ? '\u5148\u7528\u767b\u5165\u9023\u7d50'
                                  : 'Use sign-in link instead',
                            ),
                          ),
                          TextButton(
                            onPressed: _loading
                                ? null
                                : () => _switchMode(_LoginMode.password),
                            child: Text(t.authToggleToSignIn),
                          ),
                        ],
                      ),
                    ],
                    if (_showVerifyPanel) ...[
                      const SizedBox(height: 8),
                      _buildVerifyPanel(context, t),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
