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
  final String? nutritionSource;
  final String? aiOriginalCalorieRange;
  final Map<String, double>? aiOriginalMacros;
  final double? costEstimateUsd;
  final double? confidence;
  final bool? isBeverage;
  final bool? isFood;
  final String? nonFoodReason;
  final String? referenceUsed;
  final String? containerGuessType;
  final String? containerGuessSize;
  final String? catalogImageUrl;
  final String? catalogThumbUrl;
  final String? catalogImageSource;
  final String? catalogImageLicense;

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
    this.nutritionSource,
    this.aiOriginalCalorieRange,
    this.aiOriginalMacros,
    this.costEstimateUsd,
    this.confidence,
    this.isBeverage,
    this.isFood,
    this.nonFoodReason,
    this.referenceUsed,
    this.containerGuessType,
    this.containerGuessSize,
    this.catalogImageUrl,
    this.catalogThumbUrl,
    this.catalogImageSource,
    this.catalogImageLicense,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    final rawMacros = (json['macros'] as Map?) ?? {};
    final parsedMacros = <String, double>{};
    rawMacros.forEach((key, value) {
      parsedMacros[key.toString()] = _parseMacroValue(value, key.toString());
    });
    final rawOriginalMacros = (json['ai_original_macros'] as Map?) ?? {};
    final parsedOriginalMacros = <String, double>{};
    rawOriginalMacros.forEach((key, value) {
      parsedOriginalMacros[key.toString()] =
          _parseMacroValue(value, key.toString());
    });
    return AnalysisResult(
      foodName: json['food_name'] as String,
      calorieRange: json['calorie_range'] as String,
      macros: parsedMacros,
      foodItems:
          (json['food_items'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      judgementTags: (json['judgement_tags'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      dishSummary: json['dish_summary'] as String?,
      suggestion: json['suggestion'] as String,
      tier: json['tier'] as String,
      source: (json['source'] as String?) ?? 'mock',
      nutritionSource: json['nutrition_source'] as String?,
      aiOriginalCalorieRange: json['ai_original_calorie_range'] as String?,
      aiOriginalMacros:
          parsedOriginalMacros.isEmpty ? null : parsedOriginalMacros,
      costEstimateUsd: (json['cost_estimate_usd'] as num?)?.toDouble(),
      confidence: (json['confidence'] as num?)?.toDouble(),
      isBeverage: json['is_beverage'] as bool?,
      isFood: json['is_food'] as bool?,
      nonFoodReason: json['non_food_reason'] as String?,
      referenceUsed: json['reference_used'] as String?,
      containerGuessType: json['container_guess_type'] as String?,
      containerGuessSize: json['container_guess_size'] as String?,
      catalogImageUrl: (json['catalog_image_url'] as String?) ??
          (json['image_url'] as String?),
      catalogThumbUrl: (json['catalog_thumb_url'] as String?) ??
          (json['thumb_url'] as String?),
      catalogImageSource: (json['catalog_image_source'] as String?) ??
          (json['image_source'] as String?),
      catalogImageLicense: (json['catalog_image_license'] as String?) ??
          (json['image_license'] as String?),
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
      'nutrition_source': nutritionSource,
      'ai_original_calorie_range': aiOriginalCalorieRange,
      'ai_original_macros': aiOriginalMacros,
      'cost_estimate_usd': costEstimateUsd,
      'confidence': confidence,
      'is_beverage': isBeverage,
      'is_food': isFood,
      'non_food_reason': nonFoodReason,
      'reference_used': referenceUsed,
      'container_guess_type': containerGuessType,
      'container_guess_size': containerGuessSize,
      'catalog_image_url': catalogImageUrl,
      'catalog_thumb_url': catalogThumbUrl,
      'catalog_image_source': catalogImageSource,
      'catalog_image_license': catalogImageLicense,
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
      if (isMg) return numeric;
      if (value.toLowerCase().contains('g')) return numeric * 1000;
      return numeric; // no unit -> treat as mg
    }
    if (isMg) {
      return numeric / 1000;
    }
    return numeric;
  }
  return 0;
}
