import 'dart:typed_data';
import 'analysis_result.dart';

enum MealType { breakfast, lunch, dinner, lateSnack, other }

class MealEntry {
  MealEntry({
    required this.id,
    required this.imageBytes,
    required this.filename,
    required this.time,
    required this.type,
    this.note,
    this.overrideFoodName,
    this.imageHash,
    this.lastAnalyzedNote,
    this.lastAnalyzedFoodName,
  });

  final String id;
  final Uint8List imageBytes;
  final String filename;
  DateTime time;
  MealType type;
  String? note;
  String? overrideFoodName;
  String? imageHash;
  String? lastAnalyzedNote;
  String? lastAnalyzedFoodName;
  AnalysisResult? result;
  bool loading = false;
  String? error;
}
