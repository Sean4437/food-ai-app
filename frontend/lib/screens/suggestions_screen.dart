import 'package:flutter/material.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import '../state/app_state.dart';
import '../widgets/record_sheet.dart';

class SuggestionsScreen extends StatelessWidget {
  const SuggestionsScreen({super.key});

  Widget _decisionCard({
    required IconData icon,
    required String title,
    required String desc,
    required Color tint,
    required String actionLabel,
    required Future<void> Function() onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tint.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: tint),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    onPressed: () => onAction(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: tint,
                      side: BorderSide(color: tint),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(actionLabel),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final app = AppStateScope.of(context);
    Future<void> recordAndNotify() async {
      final entry = await showRecordSheet(context, app);
      if (entry == null) return;
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(t.logSuccess),
          duration: const Duration(seconds: 2),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(t.suggestTitle),
        leading: Navigator.of(context).canPop() ? const BackButton() : null,
        backgroundColor: const Color(0xFFF3F5FB),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(t.suggestTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.suggestTodayLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text(app.todayStatusLabel(t), style: const TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _decisionCard(
                    icon: Icons.store_mall_directory,
                    title: t.optionConvenienceTitle,
                    desc: t.optionConvenienceDesc,
                    tint: const Color(0xFF5B7CFA),
                    actionLabel: t.logThisMeal,
                    onAction: recordAndNotify,
                  ),
                  const SizedBox(height: 12),
                  _decisionCard(
                    icon: Icons.lunch_dining,
                    title: t.optionBentoTitle,
                    desc: t.optionBentoDesc,
                    tint: const Color(0xFF8AD7A4),
                    actionLabel: t.logThisMeal,
                    onAction: recordAndNotify,
                  ),
                  const SizedBox(height: 12),
                  _decisionCard(
                    icon: Icons.restaurant,
                    title: t.optionLightTitle,
                    desc: t.optionLightDesc,
                    tint: const Color(0xFFF4C95D),
                    actionLabel: t.logThisMeal,
                    onAction: recordAndNotify,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
