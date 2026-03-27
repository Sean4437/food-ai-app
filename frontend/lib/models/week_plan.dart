class WeekPlanMixRatio {
  const WeekPlanMixRatio({
    required this.homeCook,
    required this.eatOut,
    required this.convenienceStore,
  });

  final int homeCook;
  final int eatOut;
  final int convenienceStore;

  Map<String, dynamic> toJson() => {
        'home_cook': homeCook,
        'eat_out': eatOut,
        'convenience_store': convenienceStore,
      };

  factory WeekPlanMixRatio.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return WeekPlanMixRatio(
      homeCook: parseInt(json['home_cook']),
      eatOut: parseInt(json['eat_out']),
      convenienceStore: parseInt(json['convenience_store']),
    );
  }
}

class WeekPlanMealScenarios {
  const WeekPlanMealScenarios({
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.snack,
  });

  final List<String> breakfast;
  final List<String> lunch;
  final List<String> dinner;
  final List<String> snack;

  static const List<String> _defaultScenarios = <String>[
    'home_cook',
    'eat_out',
    'convenience_store',
  ];

  static List<String> _normalizeScenarioList(dynamic value) {
    final values = <String>[];
    final seen = <String>{};
    if (value is List) {
      for (final item in value) {
        final scenario = item.toString().trim();
        if (scenario.isEmpty || seen.contains(scenario)) continue;
        seen.add(scenario);
        values.add(scenario);
      }
    }
    return values.isNotEmpty ? values : List<String>.from(_defaultScenarios);
  }

  List<String> forMealType(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return breakfast;
      case 'lunch':
        return lunch;
      case 'dinner':
        return dinner;
      case 'snack':
        return snack;
      default:
        return List<String>.from(_defaultScenarios);
    }
  }

  Map<String, dynamic> toJson() => {
        'breakfast': breakfast,
        'lunch': lunch,
        'dinner': dinner,
        'snack': snack,
      };

  factory WeekPlanMealScenarios.fromJson(Map<String, dynamic> json) {
    return WeekPlanMealScenarios(
      breakfast: _normalizeScenarioList(json['breakfast']),
      lunch: _normalizeScenarioList(json['lunch']),
      dinner: _normalizeScenarioList(json['dinner']),
      snack: _normalizeScenarioList(json['snack']),
    );
  }

  factory WeekPlanMealScenarios.fromMixRatio(WeekPlanMixRatio ratio) {
    final allowed = <String>[];
    if (ratio.homeCook > 0) allowed.add('home_cook');
    if (ratio.eatOut > 0) allowed.add('eat_out');
    if (ratio.convenienceStore > 0) allowed.add('convenience_store');
    final normalized =
        allowed.isNotEmpty ? allowed : List<String>.from(_defaultScenarios);
    return WeekPlanMealScenarios(
      breakfast: List<String>.from(normalized),
      lunch: List<String>.from(normalized),
      dinner: List<String>.from(normalized),
      snack: List<String>.from(normalized),
    );
  }
}

class WeekPlanMacroTarget {
  const WeekPlanMacroTarget({
    required this.kcal,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
  });

  final int kcal;
  final double proteinG;
  final double carbG;
  final double fatG;

  factory WeekPlanMacroTarget.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    double parseDouble(dynamic value) {
      if (value is double) return value;
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    return WeekPlanMacroTarget(
      kcal: parseInt(json['kcal']),
      proteinG: parseDouble(json['protein_g']),
      carbG: parseDouble(json['carb_g']),
      fatG: parseDouble(json['fat_g']),
    );
  }
}

class WeekPlanMealItem {
  const WeekPlanMealItem({
    required this.mealType,
    required this.dishName,
    required this.scenario,
    required this.source,
    required this.kcal,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
    required this.locked,
    required this.eaten,
  });

  final String mealType;
  final String dishName;
  final String scenario;
  final String source;
  final int kcal;
  final double proteinG;
  final double carbG;
  final double fatG;
  final bool locked;
  final bool eaten;

  factory WeekPlanMealItem.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    double parseDouble(dynamic value) {
      if (value is double) return value;
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    return WeekPlanMealItem(
      mealType: (json['meal_type'] ?? '').toString(),
      dishName: (json['dish_name'] ?? '').toString(),
      scenario: (json['scenario'] ?? '').toString(),
      source: (json['source'] ?? '').toString(),
      kcal: parseInt(json['kcal']),
      proteinG: parseDouble(json['protein_g']),
      carbG: parseDouble(json['carb_g']),
      fatG: parseDouble(json['fat_g']),
      locked: json['locked'] == true,
      eaten: json['eaten'] == true,
    );
  }
}

class WeekPlanDayPlan {
  const WeekPlanDayPlan({
    required this.date,
    required this.totals,
    required this.meals,
  });

  final String date;
  final WeekPlanMacroTarget totals;
  final List<WeekPlanMealItem> meals;

  factory WeekPlanDayPlan.fromJson(Map<String, dynamic> json) {
    final rawMeals = json['meals'];
    final parsedMeals = <WeekPlanMealItem>[];
    if (rawMeals is List) {
      for (final item in rawMeals) {
        if (item is Map<String, dynamic>) {
          parsedMeals.add(WeekPlanMealItem.fromJson(item));
        } else if (item is Map) {
          parsedMeals.add(WeekPlanMealItem.fromJson(
              item.map((k, v) => MapEntry(k.toString(), v))));
        }
      }
    }

    final rawTotals = json['totals'];
    final totalsMap = rawTotals is Map<String, dynamic>
        ? rawTotals
        : rawTotals is Map
            ? rawTotals.map((k, v) => MapEntry(k.toString(), v))
            : const <String, dynamic>{};

    return WeekPlanDayPlan(
      date: (json['date'] ?? '').toString(),
      totals: WeekPlanMacroTarget.fromJson(totalsMap),
      meals: parsedMeals,
    );
  }
}

class WeekPlanValidation {
  const WeekPlanValidation({
    required this.passed,
    required this.warnings,
  });

  final bool passed;
  final List<String> warnings;

  factory WeekPlanValidation.fromJson(Map<String, dynamic> json) {
    final rawWarnings = json['warnings'];
    final warnings = <String>[];
    if (rawWarnings is List) {
      for (final item in rawWarnings) {
        final value = item.toString().trim();
        if (value.isNotEmpty) warnings.add(value);
      }
    }
    return WeekPlanValidation(
      passed: json['passed'] == true,
      warnings: warnings,
    );
  }
}

class WeekPlanData {
  const WeekPlanData({
    required this.planId,
    required this.version,
    required this.startDate,
    required this.endDate,
    required this.goalEffective,
    required this.mealScenariosEffective,
    required this.dailyTarget,
    required this.dayPlans,
    required this.validation,
    this.mixRatioEffective,
  });

  final String planId;
  final int version;
  final String startDate;
  final String endDate;
  final String goalEffective;
  final WeekPlanMealScenarios mealScenariosEffective;
  final WeekPlanMixRatio? mixRatioEffective;
  final WeekPlanMacroTarget dailyTarget;
  final List<WeekPlanDayPlan> dayPlans;
  final WeekPlanValidation validation;

  factory WeekPlanData.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    final rawDays = json['day_plans'];
    final days = <WeekPlanDayPlan>[];
    if (rawDays is List) {
      for (final item in rawDays) {
        if (item is Map<String, dynamic>) {
          days.add(WeekPlanDayPlan.fromJson(item));
        } else if (item is Map) {
          days.add(WeekPlanDayPlan.fromJson(
              item.map((k, v) => MapEntry(k.toString(), v))));
        }
      }
    }

    final rawMix = json['mix_ratio_effective'];
    final mixMap = rawMix is Map<String, dynamic>
        ? rawMix
        : rawMix is Map
            ? rawMix.map((k, v) => MapEntry(k.toString(), v))
            : const <String, dynamic>{};
    final mixRatio = mixMap.isEmpty ? null : WeekPlanMixRatio.fromJson(mixMap);

    final rawMealScenarios = json['meal_scenarios_effective'];
    final mealScenarioMap = rawMealScenarios is Map<String, dynamic>
        ? rawMealScenarios
        : rawMealScenarios is Map
            ? rawMealScenarios.map((k, v) => MapEntry(k.toString(), v))
            : const <String, dynamic>{};
    final mealScenarios = mealScenarioMap.isNotEmpty
        ? WeekPlanMealScenarios.fromJson(mealScenarioMap)
        : mixRatio != null
            ? WeekPlanMealScenarios.fromMixRatio(mixRatio)
            : WeekPlanMealScenarios.fromJson(const <String, dynamic>{});

    final rawDailyTarget = json['daily_target'];
    final dailyTargetMap = rawDailyTarget is Map<String, dynamic>
        ? rawDailyTarget
        : rawDailyTarget is Map
            ? rawDailyTarget.map((k, v) => MapEntry(k.toString(), v))
            : const <String, dynamic>{};

    final rawValidation = json['validation'];
    final validationMap = rawValidation is Map<String, dynamic>
        ? rawValidation
        : rawValidation is Map
            ? rawValidation.map((k, v) => MapEntry(k.toString(), v))
            : const <String, dynamic>{};

    return WeekPlanData(
      planId: (json['plan_id'] ?? '').toString(),
      version: parseInt(json['version']),
      startDate: (json['start_date'] ?? '').toString(),
      endDate: (json['end_date'] ?? '').toString(),
      goalEffective: (json['goal_effective'] ?? '').toString(),
      mealScenariosEffective: mealScenarios,
      mixRatioEffective: mixRatio,
      dailyTarget: WeekPlanMacroTarget.fromJson(dailyTargetMap),
      dayPlans: days,
      validation: WeekPlanValidation.fromJson(validationMap),
    );
  }
}

class WeekPlanReplanResult {
  const WeekPlanReplanResult({
    required this.planId,
    required this.oldVersion,
    required this.newVersion,
    required this.changedDays,
  });

  final String planId;
  final int oldVersion;
  final int newVersion;
  final List<String> changedDays;

  factory WeekPlanReplanResult.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    final rawChangedDays = json['changed_days'];
    final changedDays = <String>[];
    if (rawChangedDays is List) {
      for (final item in rawChangedDays) {
        final value = item.toString().trim();
        if (value.isNotEmpty) changedDays.add(value);
      }
    }

    return WeekPlanReplanResult(
      planId: (json['plan_id'] ?? '').toString(),
      oldVersion: parseInt(json['old_version']),
      newVersion: parseInt(json['new_version']),
      changedDays: changedDays,
    );
  }
}
