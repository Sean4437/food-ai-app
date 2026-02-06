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
    final subtitle = isZh ? '以下僅為測試流程，不會實際扣款。' : 'This is a test flow. No real charge.';
    final monthly = isZh ? '月訂 $5.99' : 'Monthly $5.99';
    final yearly = isZh ? '年訂 $49.99' : 'Yearly $49.99';
    final yearlyBadge = isZh ? '年訂省下約 30%' : 'Save about 30% yearly';
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
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.body(context).copyWith(color: Colors.black54, fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _planCard(
                context,
                title: monthly,
                badge: null,
                onTap: () => Navigator.of(context).pop('monthly'),
                bullets: [
                  isZh ? '完整 AI 分析' : 'Full AI analysis',
                  isZh ? '熱量與營養建議' : 'Calories & nutrition advice',
                  isZh ? '週／月總結' : 'Weekly/monthly summaries',
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _planCard(
                context,
                title: yearly,
                badge: yearlyBadge,
                onTap: () => Navigator.of(context).pop('yearly'),
                bullets: [
                  isZh ? '完整 AI 分析' : 'Full AI analysis',
                  isZh ? '熱量與營養建議' : 'Calories & nutrition advice',
                  isZh ? '週／月總結' : 'Weekly/monthly summaries',
                  isZh ? '更划算的長期方案' : 'Best value for long term',
                ],
              ),
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
        await _showMockSuccess(context, isZh: isZh);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isZh ? '已啟用測試訂閱' : 'Test subscription enabled')),
        );
      }
    }
  }

  static Widget _planCard(
    BuildContext context, {
    required String title,
    required List<String> bullets,
    required VoidCallback onTap,
    String? badge,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w700)),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge,
                      style: AppTextStyles.body(context).copyWith(fontSize: 11, color: theme.colorScheme.primary),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ...bullets.map(
              (text) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Expanded(child: Text(text, style: AppTextStyles.body(context).copyWith(fontSize: 13))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMockSuccess(BuildContext context, {required bool isZh}) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isZh ? '測試訂閱成功' : 'Test Subscription Active'),
        content: Text(
          isZh ? '已解鎖完整功能（測試模式）。' : 'Full features unlocked (test mode).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(isZh ? '開始使用' : 'Continue'),
          ),
        ],
      ),
    );
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
