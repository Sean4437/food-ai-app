import 'package:flutter/material.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import 'package:intl/intl.dart';
import '../design/text_styles.dart';
import '../models/week_plan.dart';
import '../services/api_service.dart';
import '../state/app_state.dart';
import '../widgets/app_background.dart';
import '../widgets/subscription_paywall.dart';

class WeekPlanScreen extends StatefulWidget {
  const WeekPlanScreen({super.key});

  @override
  State<WeekPlanScreen> createState() => _WeekPlanScreenState();
}

class _RatioPreset {
  const _RatioPreset({
    required this.key,
    required this.labelZh,
    required this.labelEn,
    required this.ratio,
  });

  final String key;
  final String labelZh;
  final String labelEn;
  final WeekPlanMixRatio ratio;
}

class _WeekPlanScreenState extends State<WeekPlanScreen> {
  static final List<_RatioPreset> _ratioPresets = [
    const _RatioPreset(
      key: 'balanced',
      labelZh: '平衡（自煮40 外食40 便利20）',
      labelEn: 'Balanced (40/40/20)',
      ratio: WeekPlanMixRatio(homeCook: 40, eatOut: 40, convenienceStore: 20),
    ),
    const _RatioPreset(
      key: 'home',
      labelZh: '自煮優先（70/20/10）',
      labelEn: 'Home-cook first (70/20/10)',
      ratio: WeekPlanMixRatio(homeCook: 70, eatOut: 20, convenienceStore: 10),
    ),
    const _RatioPreset(
      key: 'eat_out',
      labelZh: '外食優先（20/70/10）',
      labelEn: 'Eat-out first (20/70/10)',
      ratio: WeekPlanMixRatio(homeCook: 20, eatOut: 70, convenienceStore: 10),
    ),
    const _RatioPreset(
      key: 'convenience',
      labelZh: '便利店優先（20/20/60）',
      labelEn: 'Convenience first (20/20/60)',
      ratio: WeekPlanMixRatio(homeCook: 20, eatOut: 20, convenienceStore: 60),
    ),
    const _RatioPreset(
      key: 'all_home',
      labelZh: '全部自煮（100/0/0）',
      labelEn: 'All home-cook (100/0/0)',
      ratio: WeekPlanMixRatio(homeCook: 100, eatOut: 0, convenienceStore: 0),
    ),
    const _RatioPreset(
      key: 'all_eat_out',
      labelZh: '全部外食（0/100/0）',
      labelEn: 'All eat-out (0/100/0)',
      ratio: WeekPlanMixRatio(homeCook: 0, eatOut: 100, convenienceStore: 0),
    ),
    const _RatioPreset(
      key: 'all_convenience',
      labelZh: '全部便利店（0/0/100）',
      labelEn: 'All convenience (0/0/100)',
      ratio: WeekPlanMixRatio(homeCook: 0, eatOut: 0, convenienceStore: 100),
    ),
  ];

  DateTime _startDate = DateTime.now();
  String _goalMode = 'profile_default';
  String _goalOverride = 'lose_fat';
  _RatioPreset _selectedPreset = _ratioPresets.first;
  bool _loading = false;
  bool _replanning = false;
  WeekPlanData? _plan;
  WeekPlanReplanResult? _lastReplan;
  String? _errorMessage;

  bool get _isZh => Localizations.localeOf(context)
      .languageCode
      .toLowerCase()
      .startsWith('zh');

  String _goalLabel(String goal) {
    switch (goal) {
      case 'lose_fat':
        return _isZh ? '減脂' : 'Lose fat';
      case 'maintain':
        return _isZh ? '維持' : 'Maintain';
      case 'gain_muscle':
        return _isZh ? '增肌' : 'Gain muscle';
      default:
        return goal;
    }
  }

  String _mealTypeLabel(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return _isZh ? '早餐' : 'Breakfast';
      case 'lunch':
        return _isZh ? '午餐' : 'Lunch';
      case 'dinner':
        return _isZh ? '晚餐' : 'Dinner';
      case 'snack':
        return _isZh ? '點心' : 'Snack';
      default:
        return mealType;
    }
  }

  String _scenarioLabel(String scenario) {
    switch (scenario) {
      case 'home_cook':
        return _isZh ? '自煮' : 'Home';
      case 'eat_out':
        return _isZh ? '外食' : 'Eat-out';
      case 'convenience_store':
        return _isZh ? '便利店' : 'Convenience';
      default:
        return scenario;
    }
  }

  String _friendlyApiError(ApiException err) {
    if (_isZh) {
      switch (err.code) {
        case 'subscription_required':
          return '此功能需要訂閱後才能使用。';
        case 'plan_limit_reached':
          return '本週生成次數已達上限。';
        case 'invalid_mix_ratio':
          return '情境比例設定無效，請重新調整。';
        case 'invalid_goal_mode':
        case 'invalid_goal_override':
          return '目標設定無效，請重新選擇。';
        default:
          return '生成計畫失敗（${err.code}）。';
      }
    }
    switch (err.code) {
      case 'subscription_required':
        return 'This feature requires subscription.';
      case 'plan_limit_reached':
        return 'Weekly plan generation limit reached.';
      case 'invalid_mix_ratio':
        return 'Invalid mix ratio. Please adjust and retry.';
      case 'invalid_goal_mode':
      case 'invalid_goal_override':
        return 'Invalid goal setting. Please choose again.';
      default:
        return 'Failed to generate plan (${err.code}).';
    }
  }

  String _formatDate(DateTime value) {
    return DateFormat('yyyy-MM-dd').format(value);
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    setState(
        () => _startDate = DateTime(picked.year, picked.month, picked.day));
  }

  Future<void> _generateWeekPlan() async {
    final app = AppStateScope.of(context);
    final t = AppLocalizations.of(context)!;
    if (!app.canUseFeature(AppFeature.suggest)) {
      await showSubscriptionPaywall(context, app, t);
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
      _lastReplan = null;
    });

    try {
      final api = ApiService(baseUrl: app.profile.apiBaseUrl);
      final localeTag = Localizations.localeOf(context).toLanguageTag();
      final payload = <String, dynamic>{
        'start_date': _formatDate(_startDate),
        'days': 7,
        'lang': localeTag,
        'timezone': DateTime.now().timeZoneName,
        'goal_mode': _goalMode,
        'goal_override': _goalMode == 'week_override' ? _goalOverride : null,
        'profile_goal': app.profile.goal,
        'sync_goal_to_profile': false,
        'mix_ratio': _selectedPreset.ratio.toJson(),
        'constraints': <String, dynamic>{
          'daily_budget_twd': null,
          'max_prep_minutes': null,
          'allergies': const <String>[],
          'avoid_foods': const <String>[],
          'preferred_foods': const <String>[],
        },
      };
      final plan = await api.generateWeekPlan(payload, app.debugAccessToken);
      if (!mounted) return;
      setState(() => _plan = plan);
    } on ApiException catch (err) {
      if (!mounted) return;
      setState(() => _errorMessage = _friendlyApiError(err));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _isZh
            ? '生成計畫失敗，請稍後再試。'
            : 'Failed to generate plan. Please try again later.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _replanRemainingWeek() async {
    final app = AppStateScope.of(context);
    final plan = _plan;
    if (plan == null) return;

    setState(() {
      _replanning = true;
      _errorMessage = null;
    });

    try {
      final api = ApiService(baseUrl: app.profile.apiBaseUrl);
      final payload = <String, dynamic>{
        'plan_id': plan.planId,
        'scope': 'rest_week',
        'trigger_source': 'manual',
        'reason': 'manual_replan',
        'keep_locked': true,
        'keep_eaten': true,
      };
      final result = await api.replanWeek(payload, app.debugAccessToken);
      if (!mounted) return;
      setState(() => _lastReplan = result);
      final text = _isZh
          ? '已重排 ${result.changedDays.length} 天（v${result.newVersion}）'
          : 'Replanned ${result.changedDays.length} day(s) (v${result.newVersion})';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    } on ApiException catch (err) {
      if (!mounted) return;
      setState(() => _errorMessage = _friendlyApiError(err));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            _isZh ? '重排失敗，請稍後再試。' : 'Replan failed. Please try again later.';
      });
    } finally {
      if (mounted) {
        setState(() => _replanning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    return AppBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      ),
                      Expanded(
                        child: Text(
                          _isZh ? '未來 7 天飲食規劃' : '7-Day Meal Plan',
                          style: AppTextStyles.title2(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isZh ? '設定條件' : 'Planning Conditions',
                            style: AppTextStyles.body(context)
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickStartDate,
                                  icon: const Icon(Icons.event),
                                  label: Text(
                                    (_isZh ? '起始日：' : 'Start: ') +
                                        _formatDate(_startDate),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: _goalMode,
                            decoration: InputDecoration(
                              labelText: _isZh ? '目標來源' : 'Goal Source',
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'profile_default',
                                child: Text(
                                    _isZh ? '沿用設定頁目標' : 'Use profile goal'),
                              ),
                              DropdownMenuItem(
                                value: 'week_override',
                                child: Text(_isZh
                                    ? '只覆寫本週目標'
                                    : 'Override for this week'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _goalMode = value);
                            },
                          ),
                          if (_goalMode == 'week_override') ...[
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              value: _goalOverride,
                              decoration: InputDecoration(
                                labelText: _isZh ? '本週目標' : 'Weekly Goal',
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 'lose_fat', child: Text('lose_fat')),
                                DropdownMenuItem(
                                    value: 'maintain', child: Text('maintain')),
                                DropdownMenuItem(
                                    value: 'gain_muscle',
                                    child: Text('gain_muscle')),
                              ],
                              selectedItemBuilder: (context) => [
                                Text(_goalLabel('lose_fat')),
                                Text(_goalLabel('maintain')),
                                Text(_goalLabel('gain_muscle')),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => _goalOverride = value);
                              },
                            ),
                          ],
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: _selectedPreset.key,
                            decoration: InputDecoration(
                              labelText: _isZh ? '情境比例' : 'Scenario Mix',
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: _ratioPresets
                                .map((preset) => DropdownMenuItem(
                                      value: preset.key,
                                      child: Text(_isZh
                                          ? preset.labelZh
                                          : preset.labelEn),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              final next = _ratioPresets.firstWhere(
                                (item) => item.key == value,
                                orElse: () => _ratioPresets.first,
                              );
                              setState(() => _selectedPreset = next);
                            },
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _loading ? null : _generateWeekPlan,
                              icon: _loading
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.auto_awesome),
                              label: Text(
                                  _isZh ? '生成 7 天計畫' : 'Generate 7-day plan'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _errorMessage!,
                      style: AppTextStyles.caption(context)
                          .copyWith(color: Colors.red.shade700),
                    ),
                  ],
                  if (plan != null) ...[
                    const SizedBox(height: 12),
                    Card(
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (_isZh ? '本週目標：' : 'Goal: ') +
                                  _goalLabel(plan.goalEffective),
                              style: AppTextStyles.body(context)
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              (_isZh ? '每日目標 ' : 'Daily target ') +
                                  '${plan.dailyTarget.kcal} kcal / P${plan.dailyTarget.proteinG.toStringAsFixed(0)} C${plan.dailyTarget.carbG.toStringAsFixed(0)} F${plan.dailyTarget.fatG.toStringAsFixed(0)}',
                              style: AppTextStyles.caption(context)
                                  .copyWith(color: Colors.black54),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_isZh ? '計畫編號' : 'Plan ID'}: ${plan.planId}  ·  v${plan.version}',
                              style: AppTextStyles.caption(context)
                                  .copyWith(color: Colors.black54),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed:
                                    _replanning ? null : _replanRemainingWeek,
                                icon: _replanning
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.swap_horiz),
                                label: Text(
                                    _isZh ? '重排剩餘天數' : 'Replan remaining days'),
                              ),
                            ),
                            if (_lastReplan != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                (_isZh ? '最近重排：' : 'Last replan: ') +
                                    'v${_lastReplan!.oldVersion} → v${_lastReplan!.newVersion}',
                                style: AppTextStyles.caption(context)
                                    .copyWith(color: Colors.black54),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...plan.dayPlans.map((day) {
                      return Card(
                        elevation: 0.5,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                day.date,
                                style: AppTextStyles.body(context)
                                    .copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${day.totals.kcal} kcal  ·  P${day.totals.proteinG.toStringAsFixed(0)} C${day.totals.carbG.toStringAsFixed(0)} F${day.totals.fatG.toStringAsFixed(0)}',
                                style: AppTextStyles.caption(context)
                                    .copyWith(color: Colors.black54),
                              ),
                              const SizedBox(height: 10),
                              ...day.meals.map((meal) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.black12),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${_mealTypeLabel(meal.mealType)} · ${_scenarioLabel(meal.scenario)}',
                                              style:
                                                  AppTextStyles.caption(context)
                                                      .copyWith(
                                                          color:
                                                              Colors.black54),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              meal.dishName,
                                              style:
                                                  AppTextStyles.body(context),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '${meal.kcal} kcal',
                                        style: AppTextStyles.caption(context)
                                            .copyWith(
                                                fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
