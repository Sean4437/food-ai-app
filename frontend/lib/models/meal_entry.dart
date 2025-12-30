import 'dart:io';
import 'analysis_result.dart';

enum MealType { breakfast, lunch, dinner, lateSnack, other }

class MealEntry {
  MealEntry({
    required this.image,
    required this.time,
    required this.type,
    this.note,
  });

  final File image;
  DateTime time;
  MealType type;
  String? note;
  AnalysisResult? result;
  bool loading = false;
  String? error;
}
