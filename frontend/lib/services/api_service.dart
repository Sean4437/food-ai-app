import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import '../models/analysis_result.dart';
import '../models/label_result.dart';

class ApiService {
  final String baseUrl;
  ApiService({required this.baseUrl});

  Map<String, String> _authHeaders(String? accessToken) {
    if (accessToken == null || accessToken.isEmpty) return {};
    return {'Authorization': 'Bearer $accessToken'};
  }

  Future<AnalysisResult> analyzeImage(
    Uint8List imageBytes,
    String filename, {
    String? accessToken,
    String? lang,
    String? foodName,
    String? note,
    String? context,
    int? portionPercent,
    int? heightCm,
    int? weightKg,
    int? age,
    String? gender,
    String? tone,
    String? persona,
    String? activityLevel,
    String? targetCalorieRange,
    String? goal,
    String? planSpeed,
    String? mealType,
    int? mealPhotoCount,
    String? adviceMode,
    String? labelContext,
    String? analyzeReason,
    bool forceReanalyze = false,
  }) async {
    final query = lang == null ? '' : '?lang=$lang';
    final uri = Uri.parse('$baseUrl/analyze$query');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_authHeaders(accessToken));
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
    if (gender != null && gender.trim().isNotEmpty) {
      request.fields['gender'] = gender.trim();
    }
    if (tone != null && tone.trim().isNotEmpty) {
      request.fields['tone'] = tone.trim();
    }
    if (persona != null && persona.trim().isNotEmpty) {
      request.fields['persona'] = persona.trim();
    }
    if (activityLevel != null && activityLevel.trim().isNotEmpty) {
      request.fields['activity_level'] = activityLevel.trim();
    }
    if (targetCalorieRange != null && targetCalorieRange.trim().isNotEmpty) {
      request.fields['target_calorie_range'] = targetCalorieRange.trim();
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
    if (analyzeReason != null && analyzeReason.trim().isNotEmpty) {
      request.fields['analyze_reason'] = analyzeReason.trim();
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
    String? accessToken,
  ) async {
    final uri = Uri.parse('$baseUrl/summarize_day');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json', ..._authHeaders(accessToken)},
      body: json.encode(payload),
    );
    if (response.statusCode != 200) {
      throw Exception('Summarize failed: ${response.statusCode}');
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> summarizeWeek(
    Map<String, dynamic> payload,
    String? accessToken,
  ) async {
    final uri = Uri.parse('$baseUrl/summarize_week');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json', ..._authHeaders(accessToken)},
      body: json.encode(payload),
    );
    if (response.statusCode != 200) {
      throw Exception('Summarize week failed: ${response.statusCode}');
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<LabelResult> analyzeLabel(
    Uint8List imageBytes,
    String filename, {
    String? accessToken,
    String? lang,
  }) async {
    final query = lang == null ? '' : '?lang=$lang';
    final uri = Uri.parse('$baseUrl/analyze_label$query');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_authHeaders(accessToken));
    request.files.add(http.MultipartFile.fromBytes('image', imageBytes, filename: filename));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception('Analyze label failed: ${response.statusCode}');
    }

    final jsonMap = json.decode(body) as Map<String, dynamic>;
    return LabelResult.fromJson(jsonMap);
  }

  Future<AnalysisResult> analyzeName(
    String foodName, {
    String? accessToken,
    String? lang,
    String? note,
    String? context,
    int? portionPercent,
    String? mealType,
    String? adviceMode,
    Map<String, dynamic>? profile,
  }) async {
    final uri = Uri.parse('$baseUrl/analyze_name');
    final payload = <String, dynamic>{
      'food_name': foodName,
      if (lang != null && lang.trim().isNotEmpty) 'lang': lang,
      if (note != null && note.trim().isNotEmpty) 'note': note,
      if (context != null && context.trim().isNotEmpty) 'context': context,
      if (portionPercent != null && portionPercent > 0) 'portion_percent': portionPercent,
      if (mealType != null && mealType.trim().isNotEmpty) 'meal_type': mealType,
      if (adviceMode != null && adviceMode.trim().isNotEmpty) 'advice_mode': adviceMode,
      if (profile != null) 'profile': profile,
    };
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json', ..._authHeaders(accessToken)},
      body: json.encode(payload),
    );
    if (response.statusCode != 200) {
      throw Exception('Analyze name failed: ${response.statusCode}');
    }
    final jsonMap = json.decode(response.body) as Map<String, dynamic>;
    return AnalysisResult.fromJson(jsonMap);
  }

  Future<Map<String, dynamic>> suggestMeal(
    Map<String, dynamic> payload,
    [String? accessToken],
  ) async {
    final uri = Uri.parse('$baseUrl/suggest_meal');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json', ..._authHeaders(accessToken)},
      body: json.encode(payload),
    );
    if (response.statusCode != 200) {
      throw Exception('Suggest meal failed: ${response.statusCode}');
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> accessStatus({
    String? accessToken,
  }) async {
    final uri = Uri.parse('$baseUrl/access_status');
    final response = await http.get(
      uri,
      headers: _authHeaders(accessToken),
    );
    if (response.statusCode != 200) {
      throw Exception('Access status failed: ${response.statusCode}');
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }
}
