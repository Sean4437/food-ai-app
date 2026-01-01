class AnalysisResult {
  final String foodName;
  final String calorieRange;
  final Map<String, String> macros;
  final String suggestion;
  final String tier;
  final String source;
  final double? costEstimateUsd;

  AnalysisResult({
    required this.foodName,
    required this.calorieRange,
    required this.macros,
    required this.suggestion,
    required this.tier,
    required this.source,
    this.costEstimateUsd,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      foodName: json['food_name'] as String,
      calorieRange: json['calorie_range'] as String,
      macros: Map<String, String>.from(json['macros'] as Map),
      suggestion: json['suggestion'] as String,
      tier: json['tier'] as String,
      source: (json['source'] as String?) ?? 'mock',
      costEstimateUsd: (json['cost_estimate_usd'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'food_name': foodName,
      'calorie_range': calorieRange,
      'macros': macros,
      'suggestion': suggestion,
      'tier': tier,
      'source': source,
      'cost_estimate_usd': costEstimateUsd,
    };
  }
}
