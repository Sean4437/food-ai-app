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
      if (value is num) {
        parsed[key.toString()] = value.toDouble();
      } else if (value is String) {
        final cleaned = value.replaceAll('%', '').trim();
        parsed[key.toString()] = double.tryParse(cleaned) ?? 0;
      }
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
