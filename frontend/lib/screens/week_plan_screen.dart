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
  static const String _warningTagAi = '[AI]';
  static const String _warningTagFallback = '[FALLBACK]';

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
  bool _fixedSectionExpanded = true;
  final Set<String> _expandedPlanDays = <String>{};
  bool _planningSettingsExpanded = false;
  bool _showAllDayDetails = false;
  String? _selectedPlanDate;

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
      _selectedPlanDate = null;
      _seedExpandedDaysFromPlan(cachedPlan);
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

  bool _isVisiblePlanWarning(String warning) {
    final text = warning.trim().toUpperCase();
    return text.startsWith(_warningTagAi) ||
        text.startsWith(_warningTagFallback);
  }

  String _displayPlanWarning(String warning) {
    var text = warning.trim();
    if (text.toUpperCase().startsWith(_warningTagAi)) {
      text = text.substring(_warningTagAi.length).trim();
    } else if (text.toUpperCase().startsWith(_warningTagFallback)) {
      text = text.substring(_warningTagFallback.length).trim();
    }
    if (text.startsWith(':') || text.startsWith('-')) {
      text = text.substring(1).trim();
    }
    return text;
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

  int _fixedCountForMeal(String mealType) {
    return _fixedMeals.where((rule) => rule.mealType == mealType).length;
  }

  String _mealSourceSummary(String mealType) {
    final selected = _mealScenarioSelections[mealType] ?? _scenarioTypes;
    final sourceSummary = selected.isEmpty
        ? _scenarioLabel(_noneScenario)
        : selected.map(_scenarioLabel).join(' / ');
    final fixedCount = _fixedCountForMeal(mealType);
    return _isZh
        ? '$sourceSummary · 固定 $fixedCount 筆'
        : '$sourceSummary · fixed $fixedCount';
  }

  void _seedExpandedDaysFromPlan(WeekPlanData? plan) {
    _expandedPlanDays.clear();
    if (plan == null || plan.dayPlans.isEmpty) {
      _selectedPlanDate = null;
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final todayKey = _formatDate(today);
    final tomorrowKey = _formatDate(tomorrow);
    final dayKeys = plan.dayPlans.map((day) => day.date).toList();
    final dayKeySet = dayKeys.toSet();

    if (dayKeySet.contains(todayKey)) {
      _expandedPlanDays.add(todayKey);
      _selectedPlanDate ??= todayKey;
    }
    if (dayKeySet.contains(tomorrowKey)) {
      _expandedPlanDays.add(tomorrowKey);
    }

    if (_expandedPlanDays.isEmpty) {
      _expandedPlanDays.add(dayKeys.first);
      _selectedPlanDate ??= dayKeys.first;
      if (dayKeys.length > 1) {
        _expandedPlanDays.add(dayKeys[1]);
      }
      return;
    }

    if (_expandedPlanDays.length == 1 && dayKeys.length > 1) {
      for (final key in dayKeys) {
        if (_expandedPlanDays.contains(key)) continue;
        _expandedPlanDays.add(key);
        break;
      }
    }
    _selectedPlanDate ??= _expandedPlanDays.first;
  }

  void _expandAllPlanDays() {
    final plan = _plan;
    if (plan == null) return;
    setState(() {
      _expandedPlanDays
        ..clear()
        ..addAll(plan.dayPlans.map((day) => day.date));
    });
  }

  void _collapseAllPlanDays() {
    setState(() => _expandedPlanDays.clear());
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required bool expanded,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.caption(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption(context).copyWith(
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: Colors.black54,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekdayPresetButtons(
    Set<int> selectedWeekdays,
    void Function(void Function()) sheetSetState,
  ) {
    void apply(List<int> values) {
      sheetSetState(() {
        selectedWeekdays
          ..clear()
          ..addAll(values);
      });
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ActionChip(
          label: Text(_isZh ? '每天' : 'Every day'),
          onPressed: () => apply(_weekdays),
        ),
        ActionChip(
          label: Text(_isZh ? '平日' : 'Weekdays'),
          onPressed: () => apply(const <int>[1, 2, 3, 4, 5]),
        ),
        ActionChip(
          label: Text(_isZh ? '週末' : 'Weekend'),
          onPressed: () => apply(const <int>[6, 7]),
        ),
      ],
    );
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
                    _buildWeekdayPresetButtons(selectedWeekdays, sheetSetState),
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
                    _buildWeekdayPresetButtons(selectedWeekdays, sheetSetState),
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
        _selectedPlanDate = null;
        _seedExpandedDaysFromPlan(plan);
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

  Future<void> _handleGeneratePressed() async {
    if (_loading) return;
    if (_plan == null) {
      await _generateWeekPlan();
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_isZh ? '重新生成本週計畫？' : 'Regenerate this week plan?'),
        content: Text(
          _isZh
              ? '會以目前設定重新產生 7 天餐次，原本內容可能被覆蓋。'
              : 'This will regenerate the 7-day plan and may replace current items.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(_isZh ? '取消' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(_isZh ? '重新生成' : 'Regenerate'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    await _generateWeekPlan();
  }

  Future<void> _handleReplanPressed() async {
    if (_replanning || _plan == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_isZh ? '重排剩餘天數？' : 'Replan remaining days?'),
        content: Text(
          _isZh
              ? '會保留已鎖定與已吃過項目，重新安排其餘餐次。'
              : 'Locked/eaten items are kept, and remaining meals will be replanned.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(_isZh ? '取消' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(_isZh ? '重排' : 'Replan'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    await _replanRemainingWeek();
  }

  Widget _buildFixedMealsSection(String mealType) {
    final indexedRules = _fixedMeals
        .asMap()
        .entries
        .where((entry) => entry.value.mealType == mealType)
        .toList();
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
                    fontWeight: FontWeight.w700,
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
                color: const Color(0xFFFAFAFA),
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
    final expanded = _expandedPlanDays.contains(day.date);
    final lockedCount = day.meals.where((meal) => meal.locked).length;
    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                setState(() {
                  if (expanded) {
                    _expandedPlanDays.remove(day.date);
                  } else {
                    _expandedPlanDays.add(day.date);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
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
                          const SizedBox(height: 2),
                          Text(
                            _isZh
                                ? '${day.meals.length} 餐 · 固定 $lockedCount 餐'
                                : '${day.meals.length} meals · $lockedCount locked',
                            style: AppTextStyles.caption(context).copyWith(
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
            ),
            if (expanded) ...[
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
                                  style:
                                      AppTextStyles.caption(context).copyWith(
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
                                      style: AppTextStyles.caption(context)
                                          .copyWith(
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
          ],
        ),
      ),
    );
  }

  WeekPlanDayPlan? _resolveSelectedDayPlan(WeekPlanData? plan) {
    if (plan == null || plan.dayPlans.isEmpty) return null;
    final todayKey = _formatDate(DateTime.now());
    final available = plan.dayPlans.map((d) => d.date).toSet();
    final preferred = _selectedPlanDate;
    String key;
    if (preferred != null && available.contains(preferred)) {
      key = preferred;
    } else if (available.contains(todayKey)) {
      key = todayKey;
    } else {
      key = plan.dayPlans.first.date;
    }
    _selectedPlanDate = key;
    return plan.dayPlans.firstWhere((d) => d.date == key);
  }

  DateTime? _tryParseDateKey(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  Color _scenarioChipColor(String scenario) {
    switch (scenario) {
      case 'home_cook':
        return const Color(0xFF6FCF97);
      case 'eat_out':
        return const Color(0xFFF2994A);
      case 'convenience_store':
        return const Color(0xFF56CCF2);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    final dayPlans = plan?.dayPlans ?? const <WeekPlanDayPlan>[];
    final dayByDate = <String, WeekPlanDayPlan>{
      for (final day in dayPlans) day.date: day,
    };
    final selectedDay = _resolveSelectedDayPlan(plan);
    final selectedDateKey = _selectedPlanDate;
    final activeScenarioMeals = _mealTypes
        .where(
          (mealType) => (_mealScenarioSelections[mealType] ?? const <String>[])
              .isNotEmpty,
        )
        .length;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayKey = _formatDate(today);

    final weekDates = <DateTime>[];
    for (final day in dayPlans) {
      final parsed = _tryParseDateKey(day.date);
      if (parsed != null) {
        weekDates.add(parsed);
      }
    }
    if (weekDates.isEmpty) {
      final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
      for (var i = 0; i < 7; i++) {
        weekDates.add(start.add(Duration(days: i)));
      }
    }

    final weekGoalLabel = _goalMode == 'week_override'
        ? _goalLabel(_goalOverride)
        : (_isZh ? '沿用個人設定' : 'Use profile goal');
    final settingsSummary = _isZh
        ? '已套用 $activeScenarioMeals/${_mealTypes.length} 餐來源・固定餐 ${_fixedMeals.length} 項'
        : '$activeScenarioMeals/${_mealTypes.length} meal sources ・ ${_fixedMeals.length} fixed rules';

    final visibleWarnings = (plan?.validation.warnings ?? const <String>[])
        .where(_isVisiblePlanWarning)
        .map(_displayPlanWarning)
        .where((text) => text.trim().isNotEmpty)
        .toList();

    Widget buildMealCard(WeekPlanMealItem meal) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _mealTypeLabel(meal.mealType),
                          style: AppTextStyles.caption(context).copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _scenarioChipColor(meal.scenario).withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _scenarioLabel(meal.scenario),
                          style: AppTextStyles.caption(context).copyWith(
                            color: _scenarioChipColor(meal.scenario),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    meal.dishName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body(context).copyWith(
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${meal.kcal} kcal',
              style: AppTextStyles.caption(context).copyWith(
                color: const Color(0xFF374151),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

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
                          _isZh ? '7 天飲食規劃' : '7-Day Meal Plan',
                          style: AppTextStyles.title2(context),
                        ),
                      ),
                      IconButton(
                        tooltip: _isZh ? '規劃設定' : 'Plan settings',
                        onPressed: () {
                          setState(() {
                            _planningSettingsExpanded =
                                !_planningSettingsExpanded;
                          });
                        },
                        icon: Icon(
                          _planningSettingsExpanded
                              ? Icons.tune_rounded
                              : Icons.tune_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isZh ? '本週目標' : 'Weekly Focus',
                            style: AppTextStyles.body(context).copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            plan != null
                                ? _goalLabel(plan.goalEffective)
                                : weekGoalLabel,
                            style: AppTextStyles.body(context).copyWith(
                              color: const Color(0xFF111827),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            plan != null
                                ? '${_isZh ? '每日目標' : 'Daily target'} ${plan.dailyTarget.kcal} kcal'
                                : (_isZh
                                    ? '產生計畫後會顯示每日熱量目標'
                                    : 'Daily kcal target will appear after generation'),
                            style: AppTextStyles.caption(context).copyWith(
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            plan == null
                                ? (_isZh
                                    ? '產生計畫後即可直接查看下方餐單。'
                                    : 'Generate a plan to view today meals below.')
                                : (selectedDay == null
                                    ? (_isZh
                                        ? '先在本週行程選一天，再查看餐單。'
                                        : 'Pick a day from week strip to view meals.')
                                    : (_isZh
                                        ? '今天餐單已準備好，往下直接執行。'
                                        : 'Today meals are ready. Scroll down to execute.')),
                            style: AppTextStyles.caption(context).copyWith(
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed:
                                  _loading ? null : _handleGeneratePressed,
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
                                plan == null
                                    ? (_isZh
                                        ? '產生 7 天計畫'
                                        : 'Generate 7-day plan')
                                    : (_isZh
                                        ? '重新生成 7 天計畫'
                                        : 'Regenerate 7-day plan'),
                              ),
                            ),
                          ),
                          if (plan != null) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed:
                                    _replanning ? null : _handleReplanPressed,
                                icon: _replanning
                                    ? const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.swap_horiz_rounded,
                                        size: 16,
                                      ),
                                label: Text(
                                  _isZh ? '重排剩餘天數' : 'Replan remaining days',
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isZh ? '本週行程' : 'This Week',
                            style: AppTextStyles.caption(context).copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: weekDates.map((date) {
                                final key = _formatDate(date);
                                final dayPlan = dayByDate[key];
                                final isSelected = selectedDateKey == key;
                                final isToday = key == todayKey;
                                final dotColor = isSelected
                                    ? const Color(0xFF22C55E)
                                    : dayPlan != null
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFFD1D5DB);
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedPlanDate = key;
                                      if (dayPlan != null) {
                                        _expandedPlanDays
                                          ..clear()
                                          ..add(key);
                                      }
                                    });
                                  },
                                  child: Container(
                                    width: 78,
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFEFFCF4)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF6FCF97)
                                            : const Color(0xFFE5E7EB),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _weekdayShortLabel(date.weekday),
                                          style: AppTextStyles.caption(
                                            context,
                                          ).copyWith(
                                            color: isToday
                                                ? const Color(0xFF111827)
                                                : const Color(0xFF6B7280),
                                            fontWeight: isToday
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat('M/d').format(date),
                                          style: AppTextStyles.caption(
                                            context,
                                          ).copyWith(
                                            color: const Color(0xFF1F2937),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: dotColor,
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (selectedDay != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _isZh ? '餐次安排' : 'Meals',
                      style: AppTextStyles.body(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...selectedDay.meals.map(buildMealCard),
                  ] else if (plan == null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _isZh
                          ? '先產生 7 天計畫，這裡會顯示餐次安排。'
                          : 'Generate a 7-day plan to see meal details.',
                      style: AppTextStyles.caption(context).copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildSectionHeader(
                    title: _isZh ? '規劃設定' : 'Planning settings',
                    subtitle: settingsSummary,
                    expanded: _planningSettingsExpanded,
                    onTap: () {
                      setState(() {
                        _planningSettingsExpanded = !_planningSettingsExpanded;
                      });
                    },
                  ),
                  if (_planningSettingsExpanded) ...[
                    const SizedBox(height: 8),
                    Card(
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _pickStartDate,
                                icon: const Icon(Icons.event),
                                label: Text(
                                  '${_isZh ? '開始日' : 'Start'}: ${_formatDate(_startDate)}',
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              initialValue: _goalMode,
                              decoration: InputDecoration(
                                labelText: _isZh ? '目標來源' : 'Goal source',
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'profile_default',
                                  child: Text(
                                    _isZh ? '使用個人目標' : 'Use profile goal',
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'week_override',
                                  child: Text(
                                    _isZh ? '本週覆寫目標' : 'Override this week',
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
                                  labelText: _isZh ? '本週目標' : 'Weekly goal',
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
                            const SizedBox(height: 12),
                            Text(
                              _isZh ? '餐別來源' : 'Meal sources',
                              style: AppTextStyles.caption(context).copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._mealTypes.map((mealType) {
                              final selected =
                                  _mealScenarioSelections[mealType] ??
                                      _scenarioTypes;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.fromLTRB(
                                  10,
                                  8,
                                  10,
                                  10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _mealTypeLabel(mealType),
                                      style: AppTextStyles.caption(context)
                                          .copyWith(
                                        color: const Color(0xFF111827),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _mealSourceSummary(mealType),
                                      style: AppTextStyles.caption(context)
                                          .copyWith(
                                        color: const Color(0xFF6B7280),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
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
                                            label: Text(
                                              _scenarioLabel(scenario),
                                            ),
                                            selected:
                                                selected.contains(scenario),
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
                            _buildSectionHeader(
                              title: _isZh
                                  ? '固定自訂餐（可多筆）'
                                  : 'Fixed custom meals (multi)',
                              subtitle: _isZh
                                  ? '目前 ${_fixedMeals.length} 項'
                                  : '${_fixedMeals.length} rules',
                              expanded: _fixedSectionExpanded,
                              onTap: () {
                                setState(() {
                                  _fixedSectionExpanded =
                                      !_fixedSectionExpanded;
                                });
                              },
                            ),
                            if (_fixedSectionExpanded) ...[
                              const SizedBox(height: 8),
                              ..._mealTypes.map(_buildFixedMealsSection),
                            ],
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFBBF7D0),
                                ),
                              ),
                              child: Text(
                                _isZh
                                    ? '固定餐會優先於 AI 產生的餐次內容。'
                                    : 'Fixed meals override generated meals.',
                                style: AppTextStyles.caption(context).copyWith(
                                  color: const Color(0xFF166534),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _errorMessage!,
                      style: AppTextStyles.caption(context).copyWith(
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                  if (_lastReplan != null) ...[
                    const SizedBox(height: 10),
                    Card(
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          _isZh
                              ? '最近重排：v${_lastReplan!.oldVersion} -> v${_lastReplan!.newVersion}，變更 ${_lastReplan!.changedDays.length} 天'
                              : 'Last replan: v${_lastReplan!.oldVersion} -> v${_lastReplan!.newVersion}, ${_lastReplan!.changedDays.length} day(s) changed',
                          style: AppTextStyles.caption(context).copyWith(
                            color: const Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (plan != null && visibleWarnings.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Card(
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isZh ? '提醒' : 'Warnings',
                              style: AppTextStyles.caption(context).copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 6),
                            ...visibleWarnings.map(
                              (warning) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '- $warning',
                                  style:
                                      AppTextStyles.caption(context).copyWith(
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (plan != null) ...[
                    const SizedBox(height: 10),
                    _buildSectionHeader(
                      title: _isZh ? '整週明細' : 'Full week details',
                      subtitle: _isZh
                          ? '${plan.dayPlans.length} 天，點開看全部餐次'
                          : '${plan.dayPlans.length} days',
                      expanded: _showAllDayDetails,
                      onTap: () {
                        setState(() {
                          _showAllDayDetails = !_showAllDayDetails;
                        });
                      },
                    ),
                    if (_showAllDayDetails) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          TextButton(
                            onPressed: _expandAllPlanDays,
                            child: Text(_isZh ? '全部展開' : 'Expand all'),
                          ),
                          TextButton(
                            onPressed: _collapseAllPlanDays,
                            child: Text(_isZh ? '全部收合' : 'Collapse all'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ...plan.dayPlans.map(_buildDayCard),
                    ],
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
