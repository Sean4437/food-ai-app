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

class _WeekPlanScreenState extends State<WeekPlanScreen> {
  static const List<String> _mealTypes = <String>[
    'breakfast',
    'lunch',
    'dinner',
    'snack',
  ];
  static const List<String> _scenarioTypes = <String>[
    'home_cook',
    'eat_out',
    'convenience_store',
  ];

  DateTime _startDate = DateTime.now();
  String _goalMode = 'profile_default';
  String _goalOverride = 'lose_fat';
  Map<String, List<String>> _mealScenarioSelections = {
    for (final mealType in _mealTypes)
      mealType: List<String>.from(_scenarioTypes),
  };
  bool _loading = false;
  bool _replanning = false;
  WeekPlanData? _plan;
  WeekPlanReplanResult? _lastReplan;
  String? _errorMessage;
  bool _hydratedFromCache = false;

  bool get _isZh => Localizations.localeOf(context)
      .languageCode
      .toLowerCase()
      .startsWith('zh');

  void _setMealScenarioSelectionFromData(WeekPlanMealScenarios data) {
    _mealScenarioSelections = {
      for (final mealType in _mealTypes)
        mealType: List<String>.from(data.forMealType(mealType)),
    };
  }

  WeekPlanMealScenarios _mealScenarioPayload() {
    List<String> normalize(String mealType) {
      final current = _mealScenarioSelections[mealType] ?? _scenarioTypes;
      final values = <String>[];
      for (final scenario in _scenarioTypes) {
        if (current.contains(scenario)) values.add(scenario);
      }
      return values.isNotEmpty ? values : List<String>.from(_scenarioTypes);
    }

    return WeekPlanMealScenarios(
      breakfast: normalize('breakfast'),
      lunch: normalize('lunch'),
      dinner: normalize('dinner'),
      snack: normalize('snack'),
    );
  }

  void _toggleMealScenario(String mealType, String scenario, bool selected) {
    final current = List<String>.from(
      _mealScenarioSelections[mealType] ?? _scenarioTypes,
    );
    if (selected) {
      if (!current.contains(scenario)) {
        current.add(scenario);
      }
    } else {
      current.remove(scenario);
      if (current.isEmpty) {
        final text = _isZh
            ? '每一餐至少要保留一種來源。'
            : 'Each meal must keep at least one source.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(text)),
        );
        return;
      }
    }

    current.sort(
      (a, b) => _scenarioTypes.indexOf(a).compareTo(_scenarioTypes.indexOf(b)),
    );
    setState(() {
      _mealScenarioSelections = {
        ..._mealScenarioSelections,
        mealType: current,
      };
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hydratedFromCache) return;
    final app = AppStateScope.of(context);
    final cachedPlan = app.cachedWeekPlan;
    final cachedReplan = app.cachedWeekPlanReplan;
    if (cachedPlan != null) {
      _plan = cachedPlan;
      _lastReplan = cachedReplan;
      final parsedStart = DateTime.tryParse(cachedPlan.startDate);
      if (parsedStart != null) {
        _startDate =
            DateTime(parsedStart.year, parsedStart.month, parsedStart.day);
      }
      _goalMode = 'week_override';
      _goalOverride = cachedPlan.goalEffective;
      _setMealScenarioSelectionFromData(cachedPlan.mealScenariosEffective);
    }
    _hydratedFromCache = true;
  }

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
        case 'invalid_meal_scenarios':
          return '每餐來源設定無效，請至少勾選一種。';
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
      case 'invalid_meal_scenarios':
        return 'Invalid meal scenarios. Select at least one per meal.';
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
        'meal_scenarios': _mealScenarioPayload().toJson(),
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
      setState(() {
        _plan = plan;
        _lastReplan = null;
      });
      app.cacheWeekPlan(plan, lastReplan: null);
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
      app.cacheWeekPlan(_plan, lastReplan: result);
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
                            initialValue: _goalMode,
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
                              initialValue: _goalOverride,
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
                          Text(
                            _isZh ? '每餐可選來源' : 'Meal Source by Meal',
                            style: AppTextStyles.caption(context).copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._mealTypes.map((mealType) {
                            final selected =
                                _mealScenarioSelections[mealType] ??
                                    _scenarioTypes;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _mealTypeLabel(mealType),
                                    style:
                                        AppTextStyles.caption(context).copyWith(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _scenarioTypes.map((scenario) {
                                      return FilterChip(
                                        label: Text(_scenarioLabel(scenario)),
                                        selected: selected.contains(scenario),
                                        onSelected: (value) =>
                                            _toggleMealScenario(
                                          mealType,
                                          scenario,
                                          value,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            );
                          }),
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
                              '${_isZh ? '每日目標 ' : 'Daily target '}${plan.dailyTarget.kcal} kcal / P${plan.dailyTarget.proteinG.toStringAsFixed(0)} C${plan.dailyTarget.carbG.toStringAsFixed(0)} F${plan.dailyTarget.fatG.toStringAsFixed(0)}',
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
                                '${_isZh ? '最近重排：' : 'Last replan: '}v${_lastReplan!.oldVersion} → v${_lastReplan!.newVersion}',
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
