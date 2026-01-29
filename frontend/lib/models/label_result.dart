class LabelResult {
  final String? labelName;
  final String calorieRange;
  final Map<String, double> macros;
  final bool? isBeverage;
  final double? confidence;

  LabelResult({
    this.labelName,
    required this.calorieRange,
    required this.macros,
    this.isBeverage,
    this.confidence,
  });

  factory LabelResult.fromJson(Map<String, dynamic> json) {
    final rawMacros = (json['macros'] as Map?) ?? {};
    final parsedMacros = <String, double>{};
    rawMacros.forEach((key, value) {
      parsedMacros[key.toString()] = _parseMacroValue(value, key.toString());
    });
    return LabelResult(
      labelName: json['label_name'] as String?,
      calorieRange: (json['calorie_range'] as String?) ?? '',
      macros: parsedMacros,
      isBeverage: json['is_beverage'] as bool?,
      confidence: (json['confidence'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label_name': labelName,
      'calorie_range': calorieRange,
      'macros': macros,
      'is_beverage': isBeverage,
      'confidence': confidence,
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
