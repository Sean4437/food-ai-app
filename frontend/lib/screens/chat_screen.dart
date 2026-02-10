import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:food_ai_app/gen/app_localizations.dart';
import '../state/app_state.dart';
import '../models/chat_message.dart';
import '../design/text_styles.dart';
import '../widgets/app_background.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _lastMessageCount = 0;
  final _rand = Random();
  List<String> _quickPrompts = [];
  String _quickLocale = '';

  void _ensureQuickPrompts(AppLocalizations t) {
    if (_quickPrompts.isNotEmpty && _quickLocale == t.localeName) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _quickLocale = t.localeName;
        _quickPrompts = _generateQuickPrompts(t);
      });
    });
  }

  List<String> _generateQuickPrompts(AppLocalizations t) {
    if (t.localeName.startsWith('en')) {
      final today = [
        'Give me a quick summary of today’s eating.',
        'How did I do today? Just the key points.',
        'One‑sentence recap of today’s meals.',
        'Did I go over today? Quick check.',
      ];
      final tomorrow = [
        'How should I eat tomorrow to stay on track?',
        'Give me a simple plan for tomorrow.',
        '3 quick tips for tomorrow’s meals.',
        'Keep it light tomorrow—any suggestions?',
      ];
      final week = [
        'How was my eating this week? Key takeaways.',
        'Weekly summary, short and clear.',
        'What did I do well and what to fix this week?',
        'Any imbalance or overages this week?',
      ];
      final nextWeek = [
        'What should I focus on next week?',
        '3 reminders for next week’s meals.',
        'I want to eat cleaner next week—guidance?',
        'Give me one sentence for next week’s direction.',
      ];
      return [
        today[_rand.nextInt(today.length)],
        tomorrow[_rand.nextInt(tomorrow.length)],
        week[_rand.nextInt(week.length)],
        nextWeek[_rand.nextInt(nextWeek.length)],
      ];
    }
    final today = [
      '幫我用一句話整理今天吃得怎麼樣',
      '今天我吃得還可以嗎？給我重點',
      '今天飲食狀況懶人包一下',
      '今天有沒有超標？快速看一下',
    ];
    final tomorrow = [
      '明天我怎麼吃會比較穩？',
      '幫我規劃明天的吃法（簡短版）',
      '明天想清爽一點，你給方向',
      '明天給我 3 個簡單建議',
    ];
    final week = [
      '這週我吃得怎麼樣？給重點',
      '本週飲食總體評語是什麼？',
      '幫我抓這週的優點跟需要改的',
      '這週有超標或不均衡嗎？',
    ];
    final nextWeek = [
      '下週我該怎麼調整比較好？',
      '給我下週 3 個最重要提醒',
      '下週想更健康一點，怎麼吃？',
      '下週方向給我一句話就好',
    ];
    return [
      today[_rand.nextInt(today.length)],
      tomorrow[_rand.nextInt(tomorrow.length)],
      week[_rand.nextInt(week.length)],
      nextWeek[_rand.nextInt(nextWeek.length)],
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _maybeScroll(AppState app) {
    if (_lastMessageCount == app.chatMessages.length) return;
    _lastMessageCount = app.chatMessages.length;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage(AppState app, AppLocalizations t) async {
    final text = _controller.text.trim();
    if (text.isEmpty || app.chatSending) return;
    _controller.clear();
    final locale = Localizations.localeOf(context).toString();
    await app.sendChatMessage(text, locale, t);
  }

  Future<void> _sendQuickPrompt(
      String text, AppState app, AppLocalizations t) async {
    if (text.trim().isEmpty || app.chatSending) return;
    _controller.clear();
    final locale = Localizations.localeOf(context).toString();
    await app.sendChatMessage(text, locale, t);
  }

  String _assistantName(AppState app, AppLocalizations t) {
    final name = app.profile.chatAssistantName.trim();
    return name.isEmpty ? t.tabChatAssistant : name;
  }

  Widget _buildEmpty(AppState app, AppLocalizations t) {
    final name = _assistantName(app, t);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/cat01.png', width: 72, height: 72),
            const SizedBox(height: 12),
            Text(
              t.chatEmptyHintWithName(name),
              style: AppTextStyles.body(context).copyWith(color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _genderEmoji(String gender) {
    switch (gender) {
      case 'male':
        return '👨';
      case 'female':
        return '👩';
      case 'other':
        return '🧑';
      default:
        return '🙂';
    }
  }

  Widget _buildUserAvatar(AppState app) {
    const size = 80.0;
    final bytes = app.chatAvatarBytes;
    if (bytes != null && bytes.isNotEmpty) {
      return ClipOval(
        child: Image.memory(bytes, width: size, height: size, fit: BoxFit.cover),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Text(_genderEmoji(app.profile.gender), style: const TextStyle(fontSize: 32)),
      ),
    );
  }

  Widget _buildBubble(ChatMessage msg, bool isUser, ThemeData theme, AppState app) {
    final bubbleColor = isUser ? theme.colorScheme.primary.withOpacity(0.9) : Colors.white;
    final textColor = isUser ? Colors.white : Colors.black87;
    final radius = Radius.circular(16);
    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.only(
          topLeft: radius,
          topRight: radius,
          bottomLeft: isUser ? radius : const Radius.circular(6),
          bottomRight: isUser ? const Radius.circular(6) : radius,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        msg.content,
        style: AppTextStyles.body(context).copyWith(color: textColor, height: 1.4),
      ),
    );
    final bubbleWithCat = Stack(
      clipBehavior: Clip.none,
      children: [
        bubble,
        Positioned(
          left: -12,
          top: -46,
          child: Image.asset('assets/cat01.png', width: 80, height: 80),
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(child: isUser ? bubble : bubbleWithCat),
          if (isUser) ...[
            const SizedBox(width: 10),
            _buildUserAvatar(app),
          ],
        ],
      ),
    );
  }

  Widget _buildChat(AppState app, AppLocalizations t, ThemeData theme) {
    final messages = app.chatMessages;
    _ensureQuickPrompts(t);
    _maybeScroll(app);
    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? _buildEmpty(app, t)
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 12, bottom: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isUser = msg.role == 'user';
                    return _buildBubble(msg, isUser, theme, app);
                  },
                ),
        ),
        if (_quickPrompts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickPrompts
                  .map(
                    (text) => ActionChip(
                      label: Text(text, style: const TextStyle(fontSize: 12)),
                      onPressed: app.chatSending
                          ? null
                          : () => _sendQuickPrompt(text, app, t),
                    ),
                  )
                  .toList(),
            ),
          ),
        if (app.chatError != null && app.chatError!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              app.chatError!,
              style: AppTextStyles.body(context).copyWith(color: Colors.redAccent, fontSize: 12),
            ),
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(app, t),
                    decoration: InputDecoration(
                      hintText: t.chatInputHint,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: app.chatSending ? null : () => _sendMessage(app, t),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: EdgeInsets.zero,
                    ),
                    child: app.chatSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocked(AppState app, AppLocalizations t, ThemeData theme) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
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
              Image.asset('assets/cat01.png', width: 72, height: 72),
              const SizedBox(height: 12),
              Text(
                t.chatLockedTitle,
                style: AppTextStyles.title1(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                t.chatLockedBody,
                style: AppTextStyles.body(context).copyWith(color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showPaywall(context, app, t),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(t.chatLockedAction, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPaywall(BuildContext context, AppState app, AppLocalizations t) async {
    if (kIsWeb) {
      await _showMockPaywall(context, app, t);
      return;
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      await _showIapPaywall(context, app);
    }
  }

  Future<void> _showMockPaywall(BuildContext context, AppState app, AppLocalizations t) async {
    final title = t.webPaywallTitle;
    final subtitle = t.paywallSubtitle;
    final monthly = t.planMonthlyWithPrice(r'$5.99');
    final yearly = t.planYearlyWithPrice(r'$49.99');
    final yearlyBadge = t.paywallYearlyBadge;
    final testBadge = t.webPaywallTestBadge;
    final cancel = t.cancel;
    final currentPlan = app.mockSubscriptionPlanId;
    final currentPlanLabel = currentPlan == kIapMonthlyId
        ? t.webPaywallCurrentPlanMonthly
        : currentPlan == kIapYearlyId
            ? t.webPaywallCurrentPlanYearly
            : t.webPaywallCurrentPlanNone;
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
            Text(title, style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.body(context).copyWith(color: Colors.black54, fontSize: 13),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                currentPlanLabel,
                textAlign: TextAlign.center,
                style: AppTextStyles.body(context).copyWith(color: Colors.black54, fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _planCard(
                context,
                title: monthly,
                badge: testBadge,
                onTap: () => Navigator.of(context).pop(kIapMonthlyId),
                bullets: [
                  t.paywallFeatureAiAnalysis,
                  t.paywallFeatureNutritionAdvice,
                  t.paywallFeatureSummaries,
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
                onTap: () => Navigator.of(context).pop(kIapYearlyId),
                bullets: [
                  t.paywallFeatureAiAnalysis,
                  t.paywallFeatureNutritionAdvice,
                  t.paywallFeatureSummaries,
                  t.paywallFeatureBestValue,
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                t.webPaywallTestNote,
                textAlign: TextAlign.center,
                style: AppTextStyles.body(context).copyWith(color: Colors.black45, fontSize: 12),
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
    if (chosen == kIapMonthlyId || chosen == kIapYearlyId) {
      app.setMockSubscriptionActive(true, planId: chosen);
      if (context.mounted) {
        await _showMockSuccess(context, t: t);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.webPaywallActivated)),
        );
      }
    }
  }

  Future<void> _showIapPaywall(BuildContext context, AppState app) async {
    final t = AppLocalizations.of(context)!;
    if (!app.iapAvailable) {
      await app.initIap();
    }
    if (!app.iapAvailable) {
      if (context.mounted) {
        await _showIapUnavailable(context, t: t);
      }
      return;
    }
    final monthlyProduct = app.productById(kIapMonthlyId);
    final yearlyProduct = app.productById(kIapYearlyId);
    final monthlyPrice = monthlyProduct?.price ?? '\$5.99';
    final yearlyPrice = yearlyProduct?.price ?? '\$49.99';
    final title = t.paywallTitle;
    final subtitle = t.paywallSubtitle;
    final monthlyTitle = t.planMonthlyWithPrice(monthlyPrice);
    final yearlyTitle = t.planYearlyWithPrice(yearlyPrice);
    final yearlyBadge = t.paywallYearlyBadge;
    final restoreLabel = t.paywallRestore;
    final disclaimer = t.paywallDisclaimer;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(8))),
              const SizedBox(height: 12),
              Text(title, style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w700)),
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
                  title: monthlyTitle,
                  badge: null,
                  ctaLabel: t.paywallStartMonthly,
                  ctaLoading: app.iapProcessing,
                  onTap: () => app.buySubscription(kIapMonthlyId),
                  onCta: () => app.buySubscription(kIapMonthlyId),
                  bullets: [
                    t.paywallFeatureAiAnalysis,
                    t.paywallFeatureNutritionAdvice,
                    t.paywallFeatureSummaries,
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _planCard(
                  context,
                  title: yearlyTitle,
                  badge: yearlyBadge,
                  ctaLabel: t.paywallStartYearly,
                  ctaLoading: app.iapProcessing,
                  onTap: () => app.buySubscription(kIapYearlyId),
                  onCta: () => app.buySubscription(kIapYearlyId),
                  bullets: [
                    t.paywallFeatureAiAnalysis,
                    t.paywallFeatureNutritionAdvice,
                    t.paywallFeatureSummaries,
                    t.paywallFeatureBestValue,
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  disclaimer,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body(context).copyWith(color: Colors.black45, fontSize: 12),
                ),
              ),
              if ((app.iapLastError ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
                  child: Text(
                    app.iapLastError!,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body(context).copyWith(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: app.iapProcessing ? null : () => app.restoreIapPurchases(),
                child: Text(restoreLabel),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _planCard(
    BuildContext context, {
    required String title,
    required List<String> bullets,
    required VoidCallback onTap,
    String? badge,
    String? ctaLabel,
    bool ctaLoading = false,
    VoidCallback? onCta,
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
                    const Text('✅', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(text, style: AppTextStyles.body(context).copyWith(fontSize: 13))),
                  ],
                ),
              ),
            ),
            if (ctaLabel != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: ctaLoading ? null : onCta,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(ctaLoading ? '...' : ctaLabel),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMockSuccess(BuildContext context, {required AppLocalizations t}) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.webPaywallSuccessTitle),
        content: Text(
          t.webPaywallSuccessBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t.webPaywallSuccessCta),
          ),
        ],
      ),
    );
  }

  Future<void> _showIapUnavailable(BuildContext context, {required AppLocalizations t}) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.paywallUnavailableTitle),
        content: Text(
          t.paywallUnavailableBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t.dialogOk),
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
    final assistantName = _assistantName(app, t);
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(assistantName),
          elevation: 0,
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              onPressed: app.chatMessages.isEmpty ? null : () => _confirmClearChat(context, app, t),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        body: SafeArea(
          child: AnimatedBuilder(
            animation: app,
            builder: (context, _) {
              if (!app.chatAvailable) {
                return _buildLocked(app, t, theme);
              }
              return _buildChat(app, t, theme);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmClearChat(BuildContext context, AppState app, AppLocalizations t) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.chatClearTitle),
        content: Text(t.chatClearBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(t.cancel)),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: Text(t.chatClearConfirm)),
        ],
      ),
    );
    if (result == true) {
      await app.clearChat();
    }
  }
}
