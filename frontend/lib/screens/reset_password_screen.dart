import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../design/text_styles.dart';
import '../widgets/app_background.dart';
import '../gen/app_localizations.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  bool _showPassword = false;
  bool _showConfirm = false;

  String _classifyResetErrorCode(Object err) {
    final lower = err.toString().toLowerCase();
    if (lower.contains('socketexception') ||
        lower.contains('timeout') ||
        lower.contains('failed host lookup') ||
        lower.contains('clientexception') ||
        lower.contains('network')) {
      return 'network';
    }
    if (lower.contains('rate limit') || lower.contains('too many')) {
      return 'rate_limited';
    }
    if (lower.contains('expired') ||
        lower.contains('invalid') ||
        lower.contains('otp') ||
        lower.contains('flow_state')) {
      return 'link_expired';
    }
    if (lower.contains('weak password')) return 'weak_password';
    return 'unknown';
  }

  Future<bool> _ensureRecoverySession() async {
    if (Supabase.instance.client.auth.currentSession != null) return true;
    if (!kIsWeb) return false;

    Uri? uri = Uri.base;
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
      final code = extractParam(uri, 'code');

      if (tokenHash != null) {
        await Supabase.instance.client.auth.verifyOTP(
          tokenHash: tokenHash,
          type: OtpType.recovery,
        );
      } else if (code != null) {
        await Supabase.instance.client.auth.exchangeCodeForSession(code);
      } else {
        await Supabase.instance.client.auth.getSessionFromUrl(uri);
      }
    } catch (_) {}

    return Supabase.instance.client.auth.currentSession != null;
  }

  bool _isValidPassword(String value) {
    if (value.length < 8) return false;
    if (value.contains(RegExp(r'\s'))) return false;
    if (value.contains(RegExp(r'[\u4e00-\u9fff\u3400-\u4dbf\uf900-\ufaff]'))) {
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    final t = AppLocalizations.of(context)!;
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    if (password.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.authPasswordRequired)));
      return;
    }
    if (!_isValidPassword(password)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.authPasswordInvalid)));
      return;
    }
    if (password != confirm) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.authPasswordMismatch)));
      return;
    }
    setState(() => _loading = true);
    try {
      final ready = await _ensureRecoverySession();
      if (!ready) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(t.authResetLinkInvalid)));
        return;
      }
      await Supabase.instance.client.auth
          .updateUser(UserAttributes(password: password));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.authPasswordUpdated)));
      widget.onDone();
    } catch (err) {
      if (!mounted) return;
      final code = _classifyResetErrorCode(err);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${t.authResetFailed} ($code)')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
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
                  children: [
                    Text(t.authResetPasswordTitle,
                        style: AppTextStyles.title2(context)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        labelText: t.authNewPasswordLabel,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmController,
                      obscureText: !_showConfirm,
                      decoration: InputDecoration(
                        labelText: t.authConfirmPasswordLabel,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showConfirm
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () =>
                              setState(() => _showConfirm = !_showConfirm),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        child: Text(_loading
                            ? t.usageLoading
                            : t.authResetPasswordAction),
                      ),
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
