import 'package:flutter/material.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import 'package:intl/intl.dart';

import '../design/text_styles.dart';
import '../models/custom_food.dart';
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

class _FixedMealsNormalizedResult {
  const _FixedMealsNormalizedResult({
    required this.rules,
    required this.removedNames,
  });

  final List<WeekPlanFixedMeal> rules;
  final List<String> removedNames;
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
  static const List<int> _weekdays = <int>[1, 2, 3, 4, 5, 6, 7];
  static const String _noneScenario = '__none__';

  DateTime _startDate = DateTime.now();
  String _goalMode = 'profile_default';
  String _goalOverride = 'lose_fat';
  Map<String, List<String>> _mealScenarioSelections = {
    for (final mealType in _mealTypes)
      mealType: List<String>.from(_scenarioTypes),
  };
  List<WeekPlanFixedMeal> _fixedMeals = <WeekPlanFixedMeal>[];

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
      _fixedMeals =
          List<WeekPlanFixedMeal>.from(cachedPlan.fixedMealsEffective);
    }
    _hydratedFromCache = true;
  }

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
      return values;
    }

    return WeekPlanMealScenarios(
      breakfast: normalize('breakfast'),
      lunch: normalize('lunch'),
      dinner: normalize('dinner'),
      snack: normalize('snack'),
    );
  }

  void _toggleMealScenario(String mealType, String scenario, bool selected) {
    if (scenario == _noneScenario) {
      setState(() {
        _mealScenarioSelections = {
          ..._mealScenarioSelections,
          mealType: selected ? <String>[] : List<String>.from(_scenarioTypes),
        };
      });
      return;
    }
    final current = List<String>.from(
      _mealScenarioSelections[mealType] ?? _scenarioTypes,
    );
    if (selected) {
      if (!current.contains(scenario)) {
        current.add(scenario);
      }
    } else {
      current.remove(scenario);
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
      case _noneScenario:
        return _isZh ? '無' : 'None';
      case 'home_cook':
        return _isZh ? '自煮' : 'Home';
      case 'eat_out':
        return _isZh ? '外食' : 'Eat-out';
      case 'convenience_store':
        return _isZh ? '便利店' : 'Convenience';
      case 'fixed_custom':
        return _isZh ? '固定自訂' : 'Fixed custom';
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
          return '本週已達計劃生成上限。';
        case 'invalid_meal_scenarios':
          return '餐次來源設定有誤，請至少保留一餐有來源。';
        case 'invalid_fixed_meals':
          return '固定餐設定有誤，請重新檢查。';
        case 'invalid_mix_ratio':
          return '比例設定錯誤，請調整後再試。';
        case 'invalid_goal_mode':
        case 'invalid_goal_override':
          return '目標設定錯誤，請重新選擇。';
        default:
          return '生成失敗（${err.code}）。';
      }
    }
    switch (err.code) {
      case 'subscription_required':
        return 'This feature requires subscription.';
      case 'plan_limit_reached':
        return 'Weekly plan generation limit reached.';
      case 'invalid_meal_scenarios':
        return 'Invalid meal scenarios. Keep at least one meal with sources.';
      case 'invalid_fixed_meals':
        return 'Invalid fixed meal rules. Please review your settings.';
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

  String _weekdayShortLabel(int weekday) {
    const en = <int, String>{
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };
    const zh = <int, String>{
      1: '一',
      2: '二',
      3: '三',
      4: '四',
      5: '五',
      6: '六',
      7: '日',
    };
    if (_isZh) {
      return zh[weekday] ?? '?';
    }
    return en[weekday] ?? '?';
  }

  String _weekdaySummary(List<int> weekdays) {
    final normalized = weekdays.toSet().toList()..sort();
    if (normalized.length == 7) {
      return _isZh ? '每天' : 'Every day';
    }
    if (_isZh) {
      return normalized.map((d) => '週${_weekdayShortLabel(d)}').join('、');
    }
    return normalized.map(_weekdayShortLabel).join(', ');
  }

  int _parseCalorieMidpoint(String text) {
    final matches =
        RegExp(r'\d+').allMatches(text).map((m) => int.tryParse(m.group(0)!));
    final values = matches.whereType<int>().toList();
    if (values.isEmpty) return 0;
    if (values.length == 1) return values.first;
    return ((values.first + values.last) / 2).round();
  }

  double _macroValue(CustomFood food, String key) {
    final rawValue = food.macros[key] ??
        food.macros[key.toLowerCase()] ??
        (key == 'carb_g'
            ? (food.macros['carb'] ?? food.macros['carbs'])
            : null);
    return rawValue ?? 0;
  }

  _FixedMealsNormalizedResult _normalizeFixedMeals(AppState app) {
    final byId = <String, CustomFood>{
      for (final food in app.customFoods) food.id: food,
    };
    final normalized = <WeekPlanFixedMeal>[];
    final removedNames = <String>[];
    for (final rule in _fixedMeals) {
      final food = byId[rule.customFoodId];
      if (food == null) {
        if (rule.customFoodName.trim().isNotEmpty) {
          removedNames.add(rule.customFoodName.trim());
        }
        continue;
      }
      final weekdays = rule.weekdays.where((d) => d >= 1 && d <= 7).toSet()
        ..addAll(rule.weekdays.isEmpty ? _weekdays : const <int>[]);
      final kcal = _parseCalorieMidpoint(food.calorieRange);
      normalized.add(
        WeekPlanFixedMeal(
          mealType: rule.mealType,
          customFoodId: food.id,
          customFoodName: food.name,
          weekdays: weekdays.toList()..sort(),
          kcal: kcal,
          proteinG: _macroValue(food, 'protein'),
          carbG: _macroValue(food, 'carb_g'),
          fatG: _macroValue(food, 'fat'),
        ),
      );
    }
    return _FixedMealsNormalizedResult(
      rules: normalized,
      removedNames: removedNames,
    );
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
    setState(() {
      _startDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _showAddFixedMealSheet(String mealType) async {
    final app = AppStateScope.of(context);
    final foods = List<CustomFood>.from(app.customFoods)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    if (foods.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isZh
                ? '目前沒有自訂食物，請先到自訂頁新增。'
                : 'No custom foods yet. Please add one first.',
          ),
        ),
      );
      return;
    }

    String? selectedFoodId = foods.first.id;
    final selectedWeekdays = _weekdays.toSet();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, sheetSetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isZh
                          ? '新增固定${_mealTypeLabel(mealType)}'
                          : 'Add fixed ${_mealTypeLabel(mealType)}',
                      style: AppTextStyles.body(context).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedFoodId,
                      decoration: InputDecoration(
                        labelText: _isZh ? '選擇自訂食物' : 'Choose custom food',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: foods
                          .map((food) => DropdownMenuItem<String>(
                                value: food.id,
                                child: Text(food.name),
                              ))
                          .toList(),
                      onChanged: (value) {
                        sheetSetState(() => selectedFoodId = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isZh ? '套用星期' : 'Weekdays',
                      style: AppTextStyles.caption(context).copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _weekdays.map((weekday) {
                        final selected = selectedWeekdays.contains(weekday);
                        return FilterChip(
                          label: Text(
                            _isZh
                                ? '週${_weekdayShortLabel(weekday)}'
                                : _weekdayShortLabel(weekday),
                          ),
                          selected: selected,
                          onSelected: (value) {
                            sheetSetState(() {
                              if (value) {
                                selectedWeekdays.add(weekday);
                              } else if (selectedWeekdays.length > 1) {
                                selectedWeekdays.remove(weekday);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: Text(_isZh ? '取消' : 'Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              final id = selectedFoodId;
                              if (id == null || id.trim().isEmpty) return;
                              final food =
                                  foods.firstWhere((item) => item.id == id);
                              final rule = WeekPlanFixedMeal(
                                mealType: mealType,
                                customFoodId: food.id,
                                customFoodName: food.name,
                                weekdays: selectedWeekdays.toList()..sort(),
                                kcal: _parseCalorieMidpoint(food.calorieRange),
                                proteinG: _macroValue(food, 'protein'),
                                carbG: _macroValue(food, 'carb_g'),
                                fatG: _macroValue(food, 'fat'),
                              );
                              setState(() {
                                _fixedMeals = <WeekPlanFixedMeal>[
                                  ..._fixedMeals,
                                  rule
                                ];
                                _errorMessage = null;
                              });
                              Navigator.of(ctx).pop();
                            },
                            child: Text(_isZh ? '加入' : 'Add'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showEditWeekdaysSheet(int index) async {
    if (index < 0 || index >= _fixedMeals.length) return;
    final current = _fixedMeals[index];
    final selectedWeekdays = current.weekdays.toSet();
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, sheetSetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isZh ? '調整星期規則' : 'Edit weekday rule',
                      style: AppTextStyles.body(context).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _weekdays.map((weekday) {
                        final selected = selectedWeekdays.contains(weekday);
                        return FilterChip(
                          label: Text(
                            _isZh
                                ? '週${_weekdayShortLabel(weekday)}'
                                : _weekdayShortLabel(weekday),
                          ),
                          selected: selected,
                          onSelected: (value) {
                            sheetSetState(() {
                              if (value) {
                                selectedWeekdays.add(weekday);
                              } else if (selectedWeekdays.length > 1) {
                                selectedWeekdays.remove(weekday);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: Text(_isZh ? '取消' : 'Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              final updated = WeekPlanFixedMeal(
                                mealType: current.mealType,
                                customFoodId: current.customFoodId,
                                customFoodName: current.customFoodName,
                                weekdays: selectedWeekdays.toList()..sort(),
                                kcal: current.kcal,
                                proteinG: current.proteinG,
                                carbG: current.carbG,
                                fatG: current.fatG,
                              );
                              setState(() {
                                final next =
                                    List<WeekPlanFixedMeal>.from(_fixedMeals);
                                next[index] = updated;
                                _fixedMeals = next;
                              });
                              Navigator.of(ctx).pop();
                            },
                            child: Text(_isZh ? '儲存' : 'Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _generateWeekPlan() async {
    final app = AppStateScope.of(context);
    final t = AppLocalizations.of(context)!;
    if (!app.canUseFeature(AppFeature.suggest)) {
      await showSubscriptionPaywall(context, app, t);
      return;
    }

    final scenarioPayload = _mealScenarioPayload();
    final fixedResult = _normalizeFixedMeals(app);
    final hasAnyScenario = scenarioPayload.breakfast.isNotEmpty ||
        scenarioPayload.lunch.isNotEmpty ||
        scenarioPayload.dinner.isNotEmpty ||
        scenarioPayload.snack.isNotEmpty;
    final hasAnyFixed = fixedResult.rules.isNotEmpty;

    if (!hasAnyScenario && !hasAnyFixed) {
      setState(() {
        _errorMessage = _isZh
            ? '請至少保留一餐有來源設定，或加入固定餐。'
            : 'Keep at least one meal source, or add fixed meals.';
      });
      return;
    }

    String? preWarning;
    if (fixedResult.removedNames.isNotEmpty) {
      final removed = fixedResult.removedNames.toSet().join('、');
      preWarning = _isZh
          ? '已移除不存在的固定餐：$removed'
          : 'Removed missing fixed meals: $removed';
    }

    setState(() {
      _fixedMeals = fixedResult.rules;
      _loading = true;
      _errorMessage = preWarning;
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
        'meal_scenarios': scenarioPayload.toJson(),
        'fixed_meals': fixedResult.rules.map((e) => e.toJson()).toList(),
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
        _fixedMeals = List<WeekPlanFixedMeal>.from(plan.fixedMealsEffective);
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

  Widget _buildFixedMealsSection(String mealType) {
    final indexedRules = _fixedMeals.asMap().entries.where(
          (entry) => entry.value.mealType == mealType,
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _mealTypeLabel(mealType),
                  style: AppTextStyles.caption(context).copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _showAddFixedMealSheet(mealType),
                icon: const Icon(Icons.add, size: 16),
                label: Text(_isZh ? '新增固定餐' : 'Add fixed'),
              ),
            ],
          ),
          if (indexedRules.isEmpty)
            Text(
              _isZh ? '尚未設定固定餐' : 'No fixed meal yet',
              style: AppTextStyles.caption(context).copyWith(
                color: Colors.black45,
              ),
            ),
          ...indexedRules.map((entry) {
            final index = entry.key;
            final rule = entry.value;
            return Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rule.customFoodName,
                          style: AppTextStyles.body(context),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_weekdaySummary(rule.weekdays)}  ·  ${rule.kcal} kcal',
                          style: AppTextStyles.caption(context).copyWith(
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: _isZh ? '調整星期' : 'Edit weekdays',
                    onPressed: () => _showEditWeekdaysSheet(index),
                    icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                  ),
                  IconButton(
                    tooltip: _isZh ? '移除' : 'Remove',
                    onPressed: () {
                      setState(() {
                        _fixedMeals = List<WeekPlanFixedMeal>.from(_fixedMeals)
                          ..removeAt(index);
                      });
                    },
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDayCard(WeekPlanDayPlan day) {
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
              style: AppTextStyles.body(context).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${day.totals.kcal} kcal  ·  P${day.totals.proteinG.toStringAsFixed(0)} C${day.totals.carbG.toStringAsFixed(0)} F${day.totals.fatG.toStringAsFixed(0)}',
              style: AppTextStyles.caption(context).copyWith(
                color: Colors.black54,
              ),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                '${_mealTypeLabel(meal.mealType)} · ${_scenarioLabel(meal.scenario)}',
                                style: AppTextStyles.caption(context).copyWith(
                                  color: Colors.black54,
                                ),
                              ),
                              if (meal.locked)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: const Color(0xFF86EFAC),
                                    ),
                                  ),
                                  child: Text(
                                    _isZh ? '固定' : 'Locked',
                                    style:
                                        AppTextStyles.caption(context).copyWith(
                                      color: const Color(0xFF166534),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            meal.dishName,
                            style: AppTextStyles.body(context),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${meal.kcal} kcal',
                      style: AppTextStyles.caption(context).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
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
                            style: AppTextStyles.body(context).copyWith(
                              fontWeight: FontWeight.w700,
                            ),
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
                                  _isZh ? '沿用設定頁目標' : 'Use profile goal',
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'week_override',
                                child: Text(
                                  _isZh ? '只覆寫本週目標' : 'Override for this week',
                                ),
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
                              items: const <String>[
                                'lose_fat',
                                'maintain',
                                'gain_muscle',
                              ]
                                  .map(
                                    (goal) => DropdownMenuItem<String>(
                                      value: goal,
                                      child: Text(_goalLabel(goal)),
                                    ),
                                  )
                                  .toList(),
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
                                    children: [
                                      FilterChip(
                                        label: Text(
                                          _scenarioLabel(_noneScenario),
                                        ),
                                        selected: selected.isEmpty,
                                        onSelected: (value) =>
                                            _toggleMealScenario(
                                          mealType,
                                          _noneScenario,
                                          value,
                                        ),
                                      ),
                                      ..._scenarioTypes.map((scenario) {
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
                                      }),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                          const Divider(height: 22),
                          Text(
                            _isZh ? '固定餐規則（可多筆）' : 'Fixed meal rules (multi)',
                            style: AppTextStyles.caption(context).copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._mealTypes.map(_buildFixedMealsSection),
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
                                _isZh ? '生成 7 天計畫' : 'Generate 7-day plan',
                              ),
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
                      style: AppTextStyles.caption(context).copyWith(
                        color: Colors.red.shade700,
                      ),
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
                              style: AppTextStyles.body(context).copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${_isZh ? '每日目標 ' : 'Daily target '}${plan.dailyTarget.kcal} kcal / P${plan.dailyTarget.proteinG.toStringAsFixed(0)} C${plan.dailyTarget.carbG.toStringAsFixed(0)} F${plan.dailyTarget.fatG.toStringAsFixed(0)}',
                              style: AppTextStyles.caption(context).copyWith(
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_isZh ? '計畫編號' : 'Plan ID'}: ${plan.planId}  ·  v${plan.version}',
                              style: AppTextStyles.caption(context).copyWith(
                                color: Colors.black54,
                              ),
                            ),
                            if (plan.fixedMealsEffective.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                _isZh
                                    ? '固定餐規則：${plan.fixedMealsEffective.length} 筆'
                                    : 'Fixed rules: ${plan.fixedMealsEffective.length}',
                                style: AppTextStyles.caption(context).copyWith(
                                  color: Colors.black54,
                                ),
                              ),
                            ],
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
                                  _isZh ? '重排剩餘天數' : 'Replan remaining days',
                                ),
                              ),
                            ),
                            if (_lastReplan != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                '${_isZh ? '最近重排：' : 'Last replan: '}v${_lastReplan!.oldVersion} → v${_lastReplan!.newVersion}',
                                style: AppTextStyles.caption(context).copyWith(
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                            if (plan.validation.warnings.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                _isZh ? '提醒' : 'Warnings',
                                style: AppTextStyles.caption(context).copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              ...plan.validation.warnings.map(
                                (warning) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '• $warning',
                                    style:
                                        AppTextStyles.caption(context).copyWith(
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...plan.dayPlans.map(_buildDayCard),
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
