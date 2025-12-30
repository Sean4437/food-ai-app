class AnalysisResult {
  final String foodName;
  final String calorieRange;
  final Map<String, String> macros;
  final String suggestion;
  final String tier;

  AnalysisResult({
    required this.foodName,
    required this.calorieRange,
    required this.macros,
    required this.suggestion,
    required this.tier,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      foodName: json['food_name'] as String,
      calorieRange: json['calorie_range'] as String,
      macros: Map<String, String>.from(json['macros'] as Map),
      suggestion: json['suggestion'] as String,
      tier: json['tier'] as String,
    );
  }
}
