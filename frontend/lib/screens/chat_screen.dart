import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import '../config/feature_flags.dart';
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
  final FocusNode _inputFocus = FocusNode();
  final GlobalKey _inputKey = GlobalKey();
  int _lastMessageCount = 0;
  List<String> _quickPrompts = [];
  String _quickLocale = '';
  String _quickDate = '';
  bool _quickMenuOpen = false;

  void _ensureQuickPrompts(AppLocalizations t) {
    final now = DateTime.now();
    final dateKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (_quickPrompts.isNotEmpty &&
        _quickLocale == t.localeName &&
        _quickDate == dateKey) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _quickLocale = t.localeName;
        _quickDate = dateKey;
        _quickPrompts = _generateQuickPrompts(t, seed: dateKey.hashCode);
      });
    });
  }

  List<String> _generateQuickPrompts(AppLocalizations t, {required int seed}) {
    final rand = Random(seed);
    final isEnglish = t.localeName.toLowerCase().startsWith('en');
    final today = isEnglish
        ? <String>[
            "Give me a quick summary of today's meals.",
            'How did I do today? Just the key points.',
            "One-sentence recap of today's eating.",
            'Did I go over today? Quick check.',
          ]
        : <String>[
            '幫我快速總結今天的飲食重點。',
            '今天我吃得如何？只要重點就好。',
            '用一句話回顧我今天的飲食。',
            '我今天有沒有超標？幫我快速檢查。',
          ];
    final tomorrow = isEnglish
        ? <String>[
            'How should I eat tomorrow to stay on track?',
            'Give me a simple plan for tomorrow.',
            "Give me 3 quick tips for tomorrow's meals.",
            'Keep it light tomorrow. Any suggestions?',
          ]
        : <String>[
            '明天我要怎麼吃比較能維持目標？',
            '幫我安排一個簡單的明日飲食方向。',
            '給我 3 個明天飲食的快速建議。',
            '明天想吃清爽一點，給我建議。',
          ];
    final week = isEnglish
        ? <String>[
            'How was my eating this week? Key takeaways.',
            'Give me a short weekly summary.',
            'What did I do well and what should I fix this week?',
            'Any imbalance or overages this week?',
          ]
        : <String>[
            '我這週的飲食整體如何？重點整理給我。',
            '幫我做一個簡短的週總結。',
            '我這週做得好的和要改善的是什麼？',
            '這週有沒有失衡或超標的地方？',
          ];
    final nextWeek = isEnglish
        ? <String>[
            'What should I focus on next week?',
            "Give me 3 reminders for next week's meals.",
            'I want to eat cleaner next week. Any guidance?',
            'Give me one sentence for next week direction.',
          ]
        : <String>[
            '下週我應該優先注意什麼？',
            '給我 3 個下週飲食提醒。',
            '下週想吃得更乾淨，請給我方向。',
            '請用一句話告訴我下週策略。',
          ];
    final activity = isEnglish
        ? <String>[
            'Based on today, what exercise should I do and how long?',
            'Suggest a workout for today based on my profile.',
            'How much exercise is appropriate for me today?',
            'Pick an activity and duration for today.',
          ]
        : <String>[
            '根據我今天狀態，建議我做什麼運動、多久？',
            '依我的設定，幫我安排今天的運動建議。',
            '我今天適合的運動量大概多少？',
            '幫我決定今天的運動種類和時間。',
          ];
    final whatToEat = isEnglish
        ? <String>[
            'What can I eat today given my current status?',
            'Suggest what I should eat next today.',
            'Any meal ideas for today based on what I ate?',
            'What should I eat now to stay on track?',
          ]
        : <String>[
            '以我目前狀態，今天接下來可以吃什麼？',
            '幫我建議今天下一餐要吃什麼。',
            '根據我今天已吃內容，給我餐點建議。',
            '我現在吃什麼比較能維持目標？',
          ];
    return <String>[
      today[rand.nextInt(today.length)],
      tomorrow[rand.nextInt(tomorrow.length)],
      week[rand.nextInt(week.length)],
      nextWeek[rand.nextInt(nextWeek.length)],
      activity[rand.nextInt(activity.length)],
      whatToEat[rand.nextInt(whatToEat.length)],
    ];
  }

  @override
  void initState() {
    super.initState();
    _inputFocus.addListener(() {
      if (!mounted) return;
      if (!_inputFocus.hasFocus) {
        _quickMenuOpen = false;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
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
    if (_inputFocus.hasFocus) {
      _inputFocus.unfocus();
    }
    final locale = Localizations.localeOf(context).toString();
    await app.sendChatMessage(text, locale, t);
  }

  Future<void> _showQuickMenu(AppState app, AppLocalizations t) async {
    if (_quickMenuOpen || _quickPrompts.isEmpty) return;
    final box = _inputKey.currentContext?.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) return;
    _quickMenuOpen = true;
    final position = box.localToGlobal(Offset.zero, ancestor: overlay);
    final rect = RelativeRect.fromRect(
      Rect.fromLTWH(position.dx, position.dy, box.size.width, box.size.height),
      Offset.zero & overlay.size,
    );
    final items = _quickPrompts
        .map(
          (text) => PopupMenuItem<String>(
            value: text,
            child: Text(text, style: const TextStyle(fontSize: 13)),
          ),
        )
        .toList();
    final selected = await showMenu<String>(
      context: context,
      position: rect,
      items: items,
      elevation: 8,
    );
    _quickMenuOpen = false;
    if (!mounted || selected == null) return;
    _controller.text = selected;
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
  }

  String _assistantName(AppState app, AppLocalizations t) {
    final name = app.profile.chatAssistantName.trim();
    return name.isEmpty ? t.chatAssistantDefaultName : name;
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
              style:
                  AppTextStyles.body(context).copyWith(color: Colors.black54),
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
        return '??';
      case 'female':
        return '??';
      case 'other':
        return '??';
      default:
        return '??';
    }
  }

  Widget _buildUserAvatar(AppState app) {
    const size = 80.0;
    final bytes = app.chatAvatarBytes;
    if (bytes != null && bytes.isNotEmpty) {
      return ClipOval(
        child:
            Image.memory(bytes, width: size, height: size, fit: BoxFit.cover),
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
        child: Text(_genderEmoji(app.profile.gender),
            style: const TextStyle(fontSize: 32)),
      ),
    );
  }

  Widget _buildBubble(
      ChatMessage msg, bool isUser, ThemeData theme, AppState app) {
    final bubbleColor =
        isUser ? theme.colorScheme.primary.withOpacity(0.9) : Colors.white;
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
        style:
            AppTextStyles.body(context).copyWith(color: textColor, height: 1.4),
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
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
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
        if (app.chatError != null && app.chatError!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              app.chatError!,
              style: AppTextStyles.body(context)
                  .copyWith(color: Colors.redAccent, fontSize: 12),
            ),
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: _inputKey,
                        controller: _controller,
                        focusNode: _inputFocus,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onTap: () => _showQuickMenu(app, t),
                        onSubmitted: (_) => _sendMessage(app, t),
                        decoration: InputDecoration(
                          hintText: t.chatInputHint,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
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
                        onPressed:
                            app.chatSending ? null : () => _sendMessage(app, t),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          padding: EdgeInsets.zero,
                        ),
                        child: app.chatSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send, size: 18),
                      ),
                    ),
                  ],
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
                style:
                    AppTextStyles.body(context).copyWith(color: Colors.black87),
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
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(t.chatLockedAction,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPaywall(
      BuildContext context, AppState app, AppLocalizations t) async {
    if (kIsWeb) {
      if (!kEnableWebMockSubscription) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(t.webPaywallTestNote)));
        }
        return;
      }
      await _showMockPaywall(context, app, t);
      return;
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      await _showIapPaywall(context, app);
    }
  }

  Future<void> _showMockPaywall(
      BuildContext context, AppState app, AppLocalizations t) async {
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
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 12),
            Text(title,
                style: AppTextStyles.body(context)
                    .copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.body(context)
                    .copyWith(color: Colors.black54, fontSize: 13),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                currentPlanLabel,
                textAlign: TextAlign.center,
                style: AppTextStyles.body(context)
                    .copyWith(color: Colors.black54, fontSize: 12),
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
                style: AppTextStyles.body(context)
                    .copyWith(color: Colors.black45, fontSize: 12),
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
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(8))),
              const SizedBox(height: 12),
              Text(title,
                  style: AppTextStyles.body(context)
                      .copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body(context)
                      .copyWith(color: Colors.black54, fontSize: 13),
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
                  style: AppTextStyles.body(context)
                      .copyWith(color: Colors.black45, fontSize: 12),
                ),
              ),
              if ((app.iapLastError ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
                  child: Text(
                    app.iapLastError!,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body(context)
                        .copyWith(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 6),
              TextButton(
                onPressed:
                    app.iapProcessing ? null : () => app.restoreIapPurchases(),
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
                  child: Text(title,
                      style: AppTextStyles.body(context)
                          .copyWith(fontWeight: FontWeight.w700)),
                ),
                if (badge != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge,
                      style: AppTextStyles.body(context).copyWith(
                          fontSize: 11, color: theme.colorScheme.primary),
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
                    const Text('?', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(text,
                            style: AppTextStyles.body(context)
                                .copyWith(fontSize: 13))),
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
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
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

  Future<void> _showMockSuccess(BuildContext context,
      {required AppLocalizations t}) {
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

  Future<void> _showIapUnavailable(BuildContext context,
      {required AppLocalizations t}) {
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
              onPressed: app.chatMessages.isEmpty
                  ? null
                  : () => _confirmClearChat(context, app, t),
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

  Future<void> _confirmClearChat(
      BuildContext context, AppState app, AppLocalizations t) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.chatClearTitle),
        content: Text(t.chatClearBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(t.cancel)),
          ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(t.chatClearConfirm)),
        ],
      ),
    );
    if (result == true) {
      await app.clearChat();
    }
  }
}
