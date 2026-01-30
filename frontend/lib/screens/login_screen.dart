import 'package:flutter/material.dart';
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
  bool _isSignUp = false;
  bool _loading = false;
  bool _showPassword = false;
  bool _showConfirm = false;

  bool _isValidEmail(String value) {
    final email = value.trim();
    if (email.isEmpty) return false;
    return RegExp(r'^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$').hasMatch(email);
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
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    final t = AppLocalizations.of(context)!;
    final app = AppStateScope.of(context);
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.authEmailRequired)));
      return;
    }
    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.authEmailInvalid)));
      return;
    }
    if (password.isEmpty) return;
    if (_isSignUp && password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.authPasswordMismatch)));
      return;
    }
    setState(() => _loading = true);
    try {
      if (_isSignUp) {
        await app.signUpSupabase(email, password);
      } else {
        await app.signInSupabase(email, password);
      }
      if (mounted) {
        final message = _isSignUp ? t.authSignUpVerify : t.authSignInSuccess;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (err) {
      if (mounted) {
        final message = _formatAuthError(err, t, isSignUp: _isSignUp);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        suffixIcon: IconButton(
                          icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
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
                        decoration: InputDecoration(
                          labelText: t.authConfirmPasswordLabel,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          suffixIcon: IconButton(
                            icon: Icon(_showConfirm ? Icons.visibility_off : Icons.visibility),
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
