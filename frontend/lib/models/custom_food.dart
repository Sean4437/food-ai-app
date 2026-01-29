import 'dart:convert';
import 'dart:typed_data';

class CustomFood {
  CustomFood({
    required this.id,
    required this.name,
    required this.summary,
    required this.calorieRange,
    required this.suggestion,
    required this.macros,
    required this.imageBytes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  String name;
  String summary;
  String calorieRange;
  String suggestion;
  Map<String, double> macros;
  Uint8List imageBytes;
  DateTime createdAt;
  DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'summary': summary,
      'calorie_range': calorieRange,
      'suggestion': suggestion,
      'macros': macros,
      'image_bytes': base64Encode(imageBytes),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static CustomFood fromJson(Map<String, dynamic> json) {
    final rawMacros = (json['macros'] as Map?) ?? {};
    final parsed = <String, double>{};
    rawMacros.forEach((key, value) {
      parsed[key.toString()] = _parseMacroValue(value, key.toString());
    });
    return CustomFood(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      summary: (json['summary'] as String?) ?? '',
      calorieRange: (json['calorie_range'] as String?) ?? '',
      suggestion: (json['suggestion'] as String?) ?? '',
      macros: parsed,
      imageBytes: Uint8List.fromList(base64Decode(json['image_bytes'] as String)),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
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
