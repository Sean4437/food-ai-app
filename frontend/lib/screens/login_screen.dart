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
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  bool _isValidPassword(String value) {
    if (value.length < 8) return false;
    if (value.contains(RegExp(r'\s'))) return false;
    if (value.contains(RegExp(r'[\u4e00-\u9fff\u3400-\u4dbf\uf900-\ufaff]'))) return false;
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

  String _formatAuthError(Object err, AppLocalizations t, {required bool isSignUp}) {
    final text = err.toString();
    final lower = text.toLowerCase();
    if (_isNetworkError(text)) return t.authNetworkError;
    if (lower.contains('email not confirmed') || lower.contains('confirm your email')) {
      return t.authEmailNotVerified;
    }
    if (isSignUp) {
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

  Future<void> _submit() async {
    if (_loading) return;
    final t = AppLocalizations.of(context)!;
    final app = AppStateScope.of(context);
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.authEmailRequired)));
      return;
    }
    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.authEmailInvalid)));
      return;
    }
    if (password.isEmpty) return;
    if (_isSignUp && !_isValidPassword(password)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.authPasswordInvalid)));
      return;
    }
    if (_isSignUp && password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.authPasswordMismatch)));
      return;
    }
    if (_isSignUp && nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.authNicknameRequired)));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
    final email = _emailController.text.trim();
    if (email.isEmpty || !_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.authEmailInvalid)));
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
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.authEmailRequired)));
      return;
    }
    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.authEmailInvalid)));
      return;
    }
    setState(() => _loading = true);
    try {
      await app.resetSupabasePassword(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.authResetSent)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.authResetFailed)));
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
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_loading,
                      decoration: InputDecoration(
                        labelText: t.authEmailLabel,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 10),
                TextField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      enabled: !_loading,
                      decoration: InputDecoration(
                        labelText: t.authPasswordLabel,
                        helperText: _isSignUp ? t.authPasswordRule : null,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        suffixIcon: IconButton(
                          icon: Text(_showPassword ? '🙈' : '👁️'),
                          onPressed: _loading ? null : () => setState(() => _showPassword = !_showPassword),
                        ),
                      ),
                    ),
                    if (_isSignUp) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: _nicknameController,
                        enabled: !_loading,
                        decoration: InputDecoration(
                          labelText: t.nicknameLabel,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _confirmController,
                        obscureText: !_showConfirm,
                        enabled: !_loading,
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
