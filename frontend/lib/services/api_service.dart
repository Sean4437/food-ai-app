import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import '../models/analysis_result.dart';
import '../models/label_result.dart';

class ApiService {
  final String baseUrl;
  ApiService({required this.baseUrl});

  Future<AnalysisResult> analyzeImage(
    Uint8List imageBytes,
    String filename, {
    String? lang,
    String? foodName,
    String? note,
    String? context,
    int? portionPercent,
    int? heightCm,
    int? weightKg,
    int? age,
    String? goal,
    String? planSpeed,
    String? mealType,
    int? mealPhotoCount,
    String? adviceMode,
    String? labelContext,
    bool forceReanalyze = false,
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
    if (context != null && context.trim().isNotEmpty) {
      request.fields['context'] = context.trim();
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
    if (adviceMode != null && adviceMode.trim().isNotEmpty) {
      request.fields['advice_mode'] = adviceMode.trim();
    }
    if (labelContext != null && labelContext.trim().isNotEmpty) {
      request.fields['label_context'] = labelContext.trim();
    }
    if (forceReanalyze) {
      request.fields['force_reanalyze'] = 'true';
    }

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception('Analyze failed: ${response.statusCode}');
    }

    final jsonMap = json.decode(body) as Map<String, dynamic>;
    return AnalysisResult.fromJson(jsonMap);
  }

  Future<Map<String, dynamic>> summarizeDay(
    Map<String, dynamic> payload,
  ) async {
    final uri = Uri.parse('$baseUrl/summarize_day');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );
    if (response.statusCode != 200) {
      throw Exception('Summarize failed: ${response.statusCode}');
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<LabelResult> analyzeLabel(
    Uint8List imageBytes,
    String filename, {
    String? lang,
  }) async {
    final query = lang == null ? '' : '?lang=$lang';
    final uri = Uri.parse('$baseUrl/analyze_label$query');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(http.MultipartFile.fromBytes('image', imageBytes, filename: filename));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception('Analyze label failed: ${response.statusCode}');
    }

    final jsonMap = json.decode(body) as Map<String, dynamic>;
    return LabelResult.fromJson(jsonMap);
  }

  Future<Map<String, dynamic>> suggestMeal(
    Map<String, dynamic> payload,
  ) async {
    final uri = Uri.parse('$baseUrl/suggest_meal');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );
    if (response.statusCode != 200) {
      throw Exception('Suggest meal failed: ${response.statusCode}');
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }
}
