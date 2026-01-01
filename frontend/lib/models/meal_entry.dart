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
  });

  final String id;
  final Uint8List imageBytes;
  final String filename;
  DateTime time;
  MealType type;
  String? note;
  AnalysisResult? result;
  bool loading = false;
  String? error;
}
