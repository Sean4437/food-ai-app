class AnalysisResult {
  final String foodName;
  final String calorieRange;
  final Map<String, double> macros;
  final List<String> foodItems;
  final List<String> judgementTags;
  final String? dishSummary;
  final String suggestion;
  final String tier;
  final String source;
  final double? costEstimateUsd;
  final double? confidence;
  final bool? isBeverage;

  AnalysisResult({
    required this.foodName,
    required this.calorieRange,
    required this.macros,
    this.foodItems = const [],
    this.judgementTags = const [],
    this.dishSummary,
    required this.suggestion,
    required this.tier,
    required this.source,
    this.costEstimateUsd,
    this.confidence,
    this.isBeverage,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    final rawMacros = (json['macros'] as Map?) ?? {};
    final parsedMacros = <String, double>{};
    rawMacros.forEach((key, value) {
      parsedMacros[key.toString()] = _parseMacroValue(value, key.toString());
    });
    return AnalysisResult(
      foodName: json['food_name'] as String,
      calorieRange: json['calorie_range'] as String,
      macros: parsedMacros,
      foodItems: (json['food_items'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      judgementTags: (json['judgement_tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      dishSummary: json['dish_summary'] as String?,
      suggestion: json['suggestion'] as String,
      tier: json['tier'] as String,
      source: (json['source'] as String?) ?? 'mock',
      costEstimateUsd: (json['cost_estimate_usd'] as num?)?.toDouble(),
      confidence: (json['confidence'] as num?)?.toDouble(),
      isBeverage: json['is_beverage'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'food_name': foodName,
      'calorie_range': calorieRange,
      'macros': macros,
      'food_items': foodItems,
      'judgement_tags': judgementTags,
      'dish_summary': dishSummary,
      'suggestion': suggestion,
      'tier': tier,
      'source': source,
      'cost_estimate_usd': costEstimateUsd,
      'confidence': confidence,
      'is_beverage': isBeverage,
    };
  }
}

double _parseMacroValue(Object? value, String key) {
  if (value is num) return value.toDouble();
  if (value is String) {
    var cleaned = value.trim().toLowerCase();
    cleaned = cleaned.replaceAll('公克', 'g').replaceAll('毫克', 'mg');
    cleaned = cleaned.replaceAll('%', '').replaceAll('kcal', '').trim();
    final isMg = cleaned.contains('mg');
    cleaned = cleaned.replaceAll('mg', '').replaceAll('g', '').trim();
    final numeric = double.tryParse(cleaned);
    if (numeric == null) return 0;
    if (key == 'sodium') {
      return isMg ? numeric : numeric * 1000;
    }
    if (isMg) {
      return numeric / 1000;
    }
    return numeric;
  }
  return 0;
}
