import 'dart:typed_data';
import 'dart:convert';
import 'analysis_result.dart';
import 'label_result.dart';

enum MealType { breakfast, lunch, dinner, lateSnack, other }

class MealEntry {
  MealEntry({
    required this.id,
    required this.imageBytes,
    required this.filename,
    required this.time,
    required this.type,
    int? portionPercent,
    this.note,
    this.overrideFoodName,
    this.imageHash,
    this.mealId,
    this.lastAnalyzedNote,
    this.lastAnalyzedFoodName,
    this.lastAnalyzedAt,
    this.lastAnalyzeReason,
    this.labelImageBytes,
    this.labelFilename,
    this.labelResult,
  }) : portionPercent = portionPercent ?? 100;

  final String id;
  final Uint8List imageBytes;
  final String filename;
  DateTime time;
  MealType type;
  int portionPercent;
  String? mealId;
  String? note;
  String? overrideFoodName;
  String? imageHash;
  String? lastAnalyzedNote;
  String? lastAnalyzedFoodName;
  String? lastAnalyzedAt;
  String? lastAnalyzeReason;
  Uint8List? labelImageBytes;
  String? labelFilename;
  LabelResult? labelResult;
  AnalysisResult? result;
  bool loading = false;
  String? error;

  static String _mealTypeToString(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return 'breakfast';
      case MealType.lunch:
        return 'lunch';
      case MealType.dinner:
        return 'dinner';
      case MealType.lateSnack:
        return 'late_snack';
      case MealType.other:
        return 'other';
    }
  }

  static MealType _mealTypeFromString(String value) {
    switch (value) {
      case 'breakfast':
        return MealType.breakfast;
      case 'lunch':
        return MealType.lunch;
      case 'dinner':
        return MealType.dinner;
      case 'late_snack':
        return MealType.lateSnack;
      case 'other':
      default:
        return MealType.other;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_bytes': base64Encode(imageBytes),
      'filename': filename,
      'time': time.toIso8601String(),
      'type': _mealTypeToString(type),
      'portion_percent': portionPercent,
      'meal_id': mealId,
      'note': note,
      'override_food_name': overrideFoodName,
      'image_hash': imageHash,
      'last_analyzed_note': lastAnalyzedNote,
      'last_analyzed_food_name': lastAnalyzedFoodName,
      'last_analyzed_at': lastAnalyzedAt,
      'last_analyze_reason': lastAnalyzeReason,
      'label_image_bytes': labelImageBytes == null ? null : base64Encode(labelImageBytes!),
      'label_filename': labelFilename,
      'label_result': labelResult?.toJson(),
      'result': result?.toJson(),
    };
  }

  static MealEntry fromJson(Map<String, dynamic> json) {
    final bytes = base64Decode(json['image_bytes'] as String);
    final entry = MealEntry(
      id: json['id'] as String,
      imageBytes: Uint8List.fromList(bytes),
      filename: (json['filename'] as String?) ?? 'photo.jpg',
      time: DateTime.parse(json['time'] as String),
      type: _mealTypeFromString((json['type'] as String?) ?? 'other'),
      portionPercent: (json['portion_percent'] as num?)?.toInt() ?? 100,
      note: json['note'] as String?,
      overrideFoodName: json['override_food_name'] as String?,
      imageHash: json['image_hash'] as String?,
      mealId: json['meal_id'] as String?,
      lastAnalyzedNote: json['last_analyzed_note'] as String?,
      lastAnalyzedFoodName: json['last_analyzed_food_name'] as String?,
      lastAnalyzedAt: json['last_analyzed_at'] as String?,
      lastAnalyzeReason: json['last_analyze_reason'] as String?,
      labelImageBytes: json['label_image_bytes'] == null
          ? null
          : Uint8List.fromList(base64Decode(json['label_image_bytes'] as String)),
      labelFilename: json['label_filename'] as String?,
    );
    final labelJson = json['label_result'];
    if (labelJson is Map<String, dynamic>) {
      entry.labelResult = LabelResult.fromJson(labelJson);
    }
    final resultJson = json['result'];
    if (resultJson is Map<String, dynamic>) {
      entry.result = AnalysisResult.fromJson(resultJson);
    }
    return entry;
  }
}
