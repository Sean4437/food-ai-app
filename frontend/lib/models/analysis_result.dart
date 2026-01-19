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
      if (value is num) {
        parsedMacros[key.toString()] = value.toDouble();
      } else if (value is String) {
        final cleaned = value.replaceAll('%', '').trim();
        final numeric = double.tryParse(cleaned);
        if (numeric != null) {
          parsedMacros[key.toString()] = numeric;
        } else {
          parsedMacros[key.toString()] = _macroLevelToPercent(cleaned);
        }
      }
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

double _macroLevelToPercent(String value) {
  final lower = value.toLowerCase();
  if (value.contains('低') || lower.contains('low')) return 30;
  if (value.contains('高') || lower.contains('high')) return 80;
  return 55;
}
