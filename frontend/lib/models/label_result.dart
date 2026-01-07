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
      if (value is num) {
        parsedMacros[key.toString()] = value.toDouble();
      } else if (value is String) {
        final cleaned = value.replaceAll('%', '').trim();
        final numeric = double.tryParse(cleaned);
        if (numeric != null) {
          parsedMacros[key.toString()] = numeric;
        }
      }
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
