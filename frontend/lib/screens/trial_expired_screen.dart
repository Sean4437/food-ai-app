import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import '../design/text_styles.dart';
import '../widgets/app_background.dart';
import '../state/app_state.dart';

class TrialExpiredScreen extends StatelessWidget {
  const TrialExpiredScreen({super.key});

  Future<void> _showMockPaywall(BuildContext context, AppState app, AppLocalizations t) async {
    final isZh = Localizations.localeOf(context).languageCode.startsWith('zh');
    final title = isZh ? '選擇訂閱方案（測試）' : 'Select a plan (test)';
    final monthly = isZh ? '月訂 \$5.99' : 'Monthly \$5.99';
    final yearly = isZh ? '年訂 \$49.99' : 'Yearly \$49.99';
    final cancel = isZh ? '取消' : 'Cancel';
    final chosen = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 12),
            Text(title, style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ListTile(
              title: Text(monthly),
              onTap: () => Navigator.of(context).pop('monthly'),
            ),
            ListTile(
              title: Text(yearly),
              onTap: () => Navigator.of(context).pop('yearly'),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.of(context).pop('cancel'),
              child: Text(cancel),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (chosen == 'monthly' || chosen == 'yearly') {
      app.setMockSubscriptionActive(true);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isZh ? '已啟用測試訂閱' : 'Test subscription enabled')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final app = AppStateScope.of(context);
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
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
                      t.trialExpiredTitle,
                      style: AppTextStyles.title1(context),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t.trialExpiredBody,
                      style: AppTextStyles.body(context).copyWith(color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (kIsWeb && app.isWhitelisted) {
                          _showMockPaywall(context, app, t);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        t.trialExpiredAction,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    TextButton(
                      onPressed: () => app.signOutSupabase(),
                      child: Text(t.signOut),
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
