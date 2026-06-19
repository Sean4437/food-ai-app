import 'package:flutter/material.dart';

import '../state/app_state.dart';

bool _isZh(BuildContext context) {
  return Localizations.localeOf(context)
      .languageCode
      .toLowerCase()
      .startsWith('zh');
}

bool _isValidSignInPassword(String value) {
  if (value.length < 8) return false;
  if (value.contains(RegExp(r'\s'))) return false;
  if (value.contains(RegExp(r'[\u4e00-\u9fff\u3400-\u4dbf\uf900-\ufaff]'))) {
    return false;
  }
  return true;
}

Future<void> showBackupPasswordPrompt(
  BuildContext context,
  AppState app,
) async {
  if (!context.mounted || !app.isSupabaseSignedIn) return;
  final isZh = _isZh(context);
  final email = (app.supabaseUserEmail ?? app.profile.email).trim();
  final action = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(isZh ? '建議設定登入密碼' : 'Set a sign-in password'),
      content: Text(
        email.isEmpty
            ? (isZh
                ? '除了信箱登入連結外，你也可以先設定一組登入密碼。之後如果換裝置、連結過期，或臨時收不到信，仍可直接登入。'
                : 'Besides email sign-in links, you can also set a password now. If you switch devices, your link expires, or you cannot access email temporarily, you can still sign in directly.')
            : (isZh
                ? '你的帳號目前綁定在 $email。\n\n除了信箱登入連結外，你也可以先設定一組登入密碼。之後如果換裝置、連結過期，或臨時收不到信，仍可直接登入。'
                : 'Your account is linked to $email.\n\nBesides email sign-in links, you can also set a password now. If you switch devices, your link expires, or you cannot access email temporarily, you can still sign in directly.'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop('later'),
          child: Text(isZh ? '稍後再說' : 'Maybe later'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop('set'),
          child: Text(isZh ? '現在設定' : 'Set now'),
        ),
      ],
    ),
  );
  if (action != 'set' || !context.mounted) return;
  await showBackupPasswordSetupDialog(context, app);
}

Future<void> showBackupPasswordSetupDialog(
  BuildContext context,
  AppState app,
) async {
  if (!context.mounted || !app.isSupabaseSignedIn) return;
  final isZh = _isZh(context);
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  String? errorText;
  bool obscurePassword = true;
  bool obscureConfirm = true;
  bool saving = false;

  await showDialog<void>(
    context: context,
    barrierDismissible: !saving,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) => AlertDialog(
        title: Text(isZh ? '設定登入密碼' : 'Set sign-in password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isZh
                  ? '設定完成後，你可以改用 Email + 密碼登入，不必每次都等信箱連結。'
                  : 'After setting this, you can sign in with Email + password instead of waiting for an email link every time.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: obscurePassword,
              enabled: !saving,
              decoration: InputDecoration(
                labelText: isZh ? '新密碼' : 'New password',
                suffixIcon: IconButton(
                  onPressed: saving
                      ? null
                      : () =>
                          setState(() => obscurePassword = !obscurePassword),
                  icon: Icon(
                    obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmController,
              obscureText: obscureConfirm,
              enabled: !saving,
              decoration: InputDecoration(
                labelText: isZh ? '確認密碼' : 'Confirm password',
                suffixIcon: IconButton(
                  onPressed: saving
                      ? null
                      : () => setState(() => obscureConfirm = !obscureConfirm),
                  icon: Icon(
                    obscureConfirm ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isZh
                  ? '密碼至少 8 碼，且不能包含空白或中文。'
                  : 'Password must be at least 8 characters and cannot contain spaces or Chinese characters.',
              style: Theme.of(dialogContext)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.black54),
            ),
            if (errorText != null) ...[
              const SizedBox(height: 8),
              Text(
                errorText!,
                style: Theme.of(dialogContext)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.red.shade700),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.of(dialogContext).pop(),
            child: Text(isZh ? '取消' : 'Cancel'),
          ),
          FilledButton(
            onPressed: saving
                ? null
                : () async {
                    final password = passwordController.text;
                    final confirm = confirmController.text;
                    if (password.isEmpty || confirm.isEmpty) {
                      setState(() {
                        errorText = isZh
                            ? '請完整輸入兩個密碼欄位'
                            : 'Please fill in both password fields.';
                      });
                      return;
                    }
                    if (!_isValidSignInPassword(password)) {
                      setState(() {
                        errorText = isZh
                            ? '密碼至少 8 碼，且不能包含空白或中文。'
                            : 'Password must be at least 8 characters and cannot contain spaces or Chinese characters.';
                      });
                      return;
                    }
                    if (password != confirm) {
                      setState(() {
                        errorText = isZh
                            ? '兩次輸入的密碼不一致'
                            : 'Passwords do not match.';
                      });
                      return;
                    }
                    setState(() {
                      saving = true;
                      errorText = null;
                    });
                    try {
                      await app.updateSupabasePassword(password);
                      if (!dialogContext.mounted) return;
                      Navigator.of(dialogContext).pop();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isZh
                                ? '登入密碼已更新'
                                : 'Sign-in password updated.',
                          ),
                        ),
                      );
                    } catch (_) {
                      setState(() {
                        saving = false;
                        errorText = isZh
                            ? '設定密碼失敗，請稍後再試'
                            : 'Failed to set password. Please try again later.';
                      });
                    }
                  },
            child: Text(isZh ? '儲存密碼' : 'Save password'),
          ),
        ],
      ),
    ),
  );

  passwordController.dispose();
  confirmController.dispose();
}
