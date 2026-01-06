import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import '../models/analysis_result.dart';

class ApiService {
  final String baseUrl;
  ApiService({required this.baseUrl});

  Future<AnalysisResult> analyzeImage(
    Uint8List imageBytes,
    String filename, {
    String? lang,
    String? foodName,
    String? note,
    int? portionPercent,
    int? heightCm,
    int? weightKg,
    int? age,
    String? goal,
    String? planSpeed,
    String? mealType,
    int? mealPhotoCount,
  }) async {
    final query = lang == null ? '' : '?lang=$lang';
    final uri = Uri.parse('$baseUrl/analyze$query');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(http.MultipartFile.fromBytes('image', imageBytes, filename: filename));
    if (foodName != null && foodName.trim().isNotEmpty) {
      request.fields['food_name'] = foodName.trim();
    }
    if (note != null && note.trim().isNotEmpty) {
      request.fields['note'] = note.trim();
    }
    if (portionPercent != null && portionPercent > 0) {
      request.fields['portion_percent'] = portionPercent.toString();
    }
    if (heightCm != null && heightCm > 0) {
      request.fields['height_cm'] = heightCm.toString();
    }
    if (weightKg != null && weightKg > 0) {
      request.fields['weight_kg'] = weightKg.toString();
    }
    if (age != null && age > 0) {
      request.fields['age'] = age.toString();
    }
    if (goal != null && goal.trim().isNotEmpty) {
      request.fields['goal'] = goal.trim();
    }
    if (planSpeed != null && planSpeed.trim().isNotEmpty) {
      request.fields['plan_speed'] = planSpeed.trim();
    }
    if (mealType != null && mealType.trim().isNotEmpty) {
      request.fields['meal_type'] = mealType.trim();
    }
    if (mealPhotoCount != null && mealPhotoCount > 0) {
      request.fields['meal_photo_count'] = mealPhotoCount.toString();
    }

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception('Analyze failed: ${response.statusCode}');
    }

    final jsonMap = json.decode(body) as Map<String, dynamic>;
    return AnalysisResult.fromJson(jsonMap);
  }

}
