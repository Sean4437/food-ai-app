import 'package:flutter/material.dart';
import 'dart:async';
import 'package:food_ai_app/gen/app_localizations.dart';
import '../design/text_styles.dart';
import '../widgets/app_background.dart';
import '../state/app_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _isSignUp = false;
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final app = AppStateScope.of(context);
      final cached = (app.supabaseUserEmail ?? app.profile.email).trim();
      if (cached.isEmpty) return;
      if (_emailController.text.trim().isEmpty) {
        _emailController.text = cached;
        _emailController.selection =
            TextSelection.fromPosition(TextPosition(offset: cached.length));
      }
    });
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
    if (labels.any((label) => label.startsWith('-') || label.endsWith('-'))) return false;
    return true;
  }

  bool _isValidPassword(String value) {
    if (value.length < 8) return false;
    if (value.contains(RegExp(r'\s'))) return false;
    if (value.contains(RegExp(r'[\u4e00-\u9fff\u3400-\u4dbf\uf900-\ufaff]'))) return false;
    return true;
  }

  bool _isValidNickname(String value) {
    final nickname = value.trim();
    if (nickname.length < 2 || nickname.length > 24) return false;
    if (RegExp(r'[\x00-\x1F\x7F]').hasMatch(nickname)) return false;
    if (RegExp(r'[\u200B-\u200F\uFEFF]').hasMatch(nickname)) return false;
    return true;
  }

  bool _isNetworkError(String text) {
    final lower = text.toLowerCase();
    return lower.contains('socketexception') ||
        lower.contains('timeout') ||
        lower.contains('failed host lookup') ||
        lower.contains('clientexception') ||
        lower.contains('network');
  }

  String _classifyResetErrorCode(Object err) {
    final lower = err.toString().toLowerCase();
    if (_isNetworkError(lower)) return 'network';
    if (lower.contains('rate limit') || lower.contains('too many')) {
      return 'rate_limited';
    }
    if (lower.contains('expired') || lower.contains('invalid') || lower.contains('otp')) {
      return 'link_expired';
    }
    if (lower.contains('not found') || lower.contains('user')) return 'email_not_found';
    return 'unknown';
  }

  String _formatAuthError(Object err, AppLocalizations t, {required bool isSignUp}) {
    final text = err.toString();
    final lower = text.toLowerCase();
    if (_isNetworkError(text)) return t.authNetworkError;
    if (lower.contains('email not confirmed') || lower.contains('confirm your email')) {
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
      if (lower.contains('already registered') || lower.contains('already exists') || lower.contains('user exists')) {
        return t.authEmailExists;
      }
      return t.authSignUpFailed;
    }
    if (lower.contains('invalid login') || lower.contains('invalid credentials') || lower.contains('invalid email or password')) {
      return t.authLoginInvalid;
    }
    return t.authError;
  }

  @override
  void dispose() {
    _emailController.dispose();
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
        DateTime.now().difference(_lastAuthAttempt!) < const Duration(seconds: 2)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.authTooManyAttempts)));
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
    if (password.isEmpty) {
      _setInlinePasswordError(t.authPasswordRequired);
      return;
    }
    if (_isSignUp && !_isValidPassword(password)) {
      _setInlinePasswordError(t.authPasswordInvalid);
      return;
    }
    if (_isSignUp && password != confirm) {
      _setInlinePasswordError(t.authPasswordMismatch);
      return;
    }
    if (_isSignUp && nickname.isEmpty) {
      _setInlineNicknameError(t.authNicknameRequired);
      return;
    }
    if (_isSignUp && !_isValidNickname(nickname)) {
      _setInlineNicknameError(t.authNicknameInvalid);
      return;
    }
    setState(() => _loading = true);
    try {
      if (_isSignUp) {
        await app.signUpSupabase(email, password, nickname: nickname);
      } else {
        await app.signInSupabase(email, password);
      }
      if (mounted) {
        final message = _isSignUp ? t.authSignUpVerify : t.authSignInSuccess;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        if (_isSignUp) {
          setState(() {
            _showVerifyPanel = true;
            _resendCooldown = 30;
          });
          _startResendCooldown();
        }
      }
    } catch (err) {
      if (mounted) {
        final message = _formatAuthError(err, t, isSignUp: _isSignUp);
        if (!_isSignUp && message == t.authLoginInvalid) {
          _setInlinePasswordError(message);
        } else if (_isSignUp && message == t.authEmailInvalid) {
          _setInlineEmailError(message);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        }
        if (!_isSignUp && message == t.authEmailNotVerified) {
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
    setState(() => _loading = true);
    try {
      await app.resendVerificationEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.authResendSent)));
      setState(() {
        _showVerifyPanel = true;
        _resendCooldown = 30;
      });
      _startResendCooldown();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.authResendFailed)));
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final cardWidth = (media.size.width - 32).clamp(280.0, 420.0);
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
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
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
                      t.authTitle,
                      style: AppTextStyles.title1(context),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t.authSubtitle,
                      style: AppTextStyles.caption(context).copyWith(color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                    if (_bannerMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
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
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_loading,
                      onChanged: (_) {
                        if (_inlineEmailError != null) {
                          _setInlineEmailError(null);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: t.authEmailLabel,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        errorText: _inlineEmailError,
                      ),
                    ),
                    const SizedBox(height: 10),
                TextField(
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
                        helperText: _isSignUp ? t.authPasswordRule : null,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        errorText: _inlinePasswordError,
                        suffixIcon: IconButton(
                          icon: Text(_showPassword ? '🙈' : '👁️'),
                          onPressed: _loading ? null : () => setState(() => _showPassword = !_showPassword),
                        ),
                      ),
                    ),
                    if (_isSignUp) ...[
                      const SizedBox(height: 10),
                      TextField(
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          suffixIcon: IconButton(
                            icon: Text(_showConfirm ? '🙈' : '👁️'),
                            onPressed: _loading ? null : () => setState(() => _showConfirm = !_showConfirm),
                          ),
                        ),
                      ),
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
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          errorText: _inlineNicknameError,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _isSignUp ? t.authSignUp : t.authSignIn,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _loading
                          ? null
                          : () {
                              setState(() => _isSignUp = !_isSignUp);
                            },
                      child: Text(_isSignUp ? t.authToggleToSignIn : t.authToggleToSignUp),
                    ),
                    TextButton(
                      onPressed: _loading ? null : _resetPassword,
                      child: Text(t.authForgotPassword),
                    ),
                    if (_showVerifyPanel) ...[
                      const SizedBox(height: 8),
                      Container(
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
                              style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              t.authVerifyBody(_emailController.text.trim()),
                              style: AppTextStyles.caption(context).copyWith(color: Colors.black54, height: 1.4),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _loading || _resendCooldown > 0 ? null : _resendVerification,
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
                      ),
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
