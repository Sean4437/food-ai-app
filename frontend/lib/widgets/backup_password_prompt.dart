import 'package:flutter/material.dart';

import '../state/app_state.dart';

bool _isZh(BuildContext context) {
  return Localizations.localeOf(context)
      .languageCode
      .toLowerCase()
      .startsWith('zh');
}

bool _isValidBackupPassword(String value) {
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
      title: Text(
        isZh ? '保護付費帳號' : 'Protect your paid account',
      ),
      content: Text(
        email.isEmpty
            ? (isZh
                ? '建議設定備援密碼。之後若換裝置或登入失效，可以直接用密碼登入。'
                : 'Set a backup password so you can sign in directly later if you change devices or lose your session.')
            : (isZh
                ? '你的訂閱已綁定到 $email。\n\n建議設定備援密碼，之後若換裝置或登入失效，可以直接用密碼登入。'
                : 'Your subscription is linked to $email.\n\nSet a backup password so you can sign in directly later if you change devices or lose your session.'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop('later'),
          child: Text(isZh ? '之後再說' : 'Maybe later'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop('set'),
          child: Text(isZh ? '立即設定' : 'Set now'),
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
        title: Text(isZh ? '設定備援密碼' : 'Set backup password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isZh
                  ? '之後除了信箱登入連結，也能直接用 Email + 密碼登入。'
                  : 'You will be able to sign in with Email + password in addition to email sign-in links.',
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
                  ? '密碼至少 8 碼，且不可含空白或中文。'
                  : 'Password must be at least 8 characters with no spaces or Chinese characters.',
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
                        errorText =
                            isZh ? '請完整輸入密碼' : 'Enter both password fields.';
                      });
                      return;
                    }
                    if (!_isValidBackupPassword(password)) {
                      setState(() {
                        errorText = isZh
                            ? '密碼至少 8 碼，且不可含空白或中文。'
                            : 'Password must be at least 8 characters with no spaces or Chinese characters.';
                      });
                      return;
                    }
                    if (password != confirm) {
                      setState(() {
                        errorText =
                            isZh ? '兩次密碼不一致' : 'Passwords do not match.';
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
                                ? '備援密碼已設定'
                                : 'Backup password set successfully.',
                          ),
                        ),
                      );
                    } catch (err) {
                      setState(() {
                        saving = false;
                        errorText = isZh
                            ? '設定失敗，請稍後再試。'
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
