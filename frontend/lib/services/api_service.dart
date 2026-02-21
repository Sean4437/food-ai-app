import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import '../models/analysis_result.dart';
import '../models/label_result.dart';

class ApiException implements Exception {
  final int statusCode;
  final String code;
  final String message;
  ApiException(this.statusCode, this.code, this.message);

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}

class CatalogSearchException implements Exception {
  CatalogSearchException(
    this.code, {
    this.statusCode,
    this.message,
  });

  final String code;
  final int? statusCode;
  final String? message;

  @override
  String toString() =>
      'CatalogSearchException(code=$code, status=$statusCode, message=$message)';
}

class ApiService {
  final String baseUrl;
  ApiService({required this.baseUrl});

  String _bodyText(http.Response response) =>
      utf8.decode(response.bodyBytes, allowMalformed: true);

  dynamic _decodeJson(http.Response response) => json.decode(_bodyText(response));

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
    String? containerType,
    String? containerSize,
    String? containerDepth,
    int? containerDiameterCm,
    int? containerCapacityMl,
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
    int? todayConsumedKcal,
    int? todayRemainingKcal,
    int? todayProteinG,
    String? labelContext,
    String? analyzeReason,
    String? referenceObject,
    double? referenceLengthCm,
    bool forceReanalyze = false,
  }) async {
    final query = lang == null ? '' : '?lang=$lang';
    final uri = Uri.parse('$baseUrl/analyze$query');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_authHeaders(accessToken));
    request.files.add(
        http.MultipartFile.fromBytes('image', imageBytes, filename: filename));
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
    if (containerType != null && containerType.trim().isNotEmpty) {
      request.fields['container_type'] = containerType.trim();
    }
    if (containerSize != null && containerSize.trim().isNotEmpty) {
      request.fields['container_size'] = containerSize.trim();
    }
    if (containerDepth != null && containerDepth.trim().isNotEmpty) {
      request.fields['container_depth'] = containerDepth.trim();
    }
    if (containerDiameterCm != null && containerDiameterCm > 0) {
      request.fields['container_diameter_cm'] = containerDiameterCm.toString();
    }
    if (containerCapacityMl != null && containerCapacityMl > 0) {
      request.fields['container_capacity_ml'] = containerCapacityMl.toString();
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
    if (todayConsumedKcal != null && todayConsumedKcal > 0) {
      request.fields['today_consumed_kcal'] = todayConsumedKcal.toString();
    }
    if (todayRemainingKcal != null) {
      request.fields['today_remaining_kcal'] = todayRemainingKcal.toString();
    }
    if (todayProteinG != null && todayProteinG > 0) {
      request.fields['today_protein_g'] = todayProteinG.toString();
    }
    if (labelContext != null && labelContext.trim().isNotEmpty) {
      request.fields['label_context'] = labelContext.trim();
    }
    if (analyzeReason != null && analyzeReason.trim().isNotEmpty) {
      request.fields['analyze_reason'] = analyzeReason.trim();
    }
    if (referenceObject != null && referenceObject.trim().isNotEmpty) {
      request.fields['reference_object'] = referenceObject.trim();
    }
    if (referenceLengthCm != null && referenceLengthCm > 0) {
      request.fields['reference_length_cm'] = referenceLengthCm.toString();
    }
    if (forceReanalyze) {
      request.fields['force_reanalyze'] = 'true';
    }

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      String code = 'unknown';
      String message = body;
      try {
        final decoded = json.decode(body);
        if (decoded is Map<String, dynamic>) {
          code = (decoded['detail'] ?? decoded['code'] ?? code).toString();
          message =
              (decoded['message'] ?? decoded['detail'] ?? message).toString();
        }
      } catch (_) {}
      throw ApiException(response.statusCode, code, message);
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
      headers: {
        'Content-Type': 'application/json',
        ..._authHeaders(accessToken)
      },
      body: json.encode(payload),
    );
    if (response.statusCode != 200) {
      throw Exception('Summarize failed: ${response.statusCode}');
    }
    return _decodeJson(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> summarizeWeek(
    Map<String, dynamic> payload,
    String? accessToken,
  ) async {
    final uri = Uri.parse('$baseUrl/summarize_week');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        ..._authHeaders(accessToken)
      },
      body: json.encode(payload),
    );
    if (response.statusCode != 200) {
      throw Exception('Summarize week failed: ${response.statusCode}');
    }
    return _decodeJson(response) as Map<String, dynamic>;
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
    request.files.add(
        http.MultipartFile.fromBytes('image', imageBytes, filename: filename));

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
    String? containerType,
    String? containerSize,
    String? containerDepth,
    int? containerDiameterCm,
    int? containerCapacityMl,
    Map<String, dynamic>? profile,
  }) async {
    final uri = Uri.parse('$baseUrl/analyze_name');
    final payload = <String, dynamic>{
      'food_name': foodName,
      if (lang != null && lang.trim().isNotEmpty) 'lang': lang,
      if (note != null && note.trim().isNotEmpty) 'note': note,
      if (context != null && context.trim().isNotEmpty) 'context': context,
      if (portionPercent != null && portionPercent > 0)
        'portion_percent': portionPercent,
      if (mealType != null && mealType.trim().isNotEmpty) 'meal_type': mealType,
      if (adviceMode != null && adviceMode.trim().isNotEmpty)
        'advice_mode': adviceMode,
      if (containerType != null && containerType.trim().isNotEmpty)
        'container_type': containerType,
      if (containerSize != null && containerSize.trim().isNotEmpty)
        'container_size': containerSize,
      if (containerDepth != null && containerDepth.trim().isNotEmpty)
        'container_depth': containerDepth,
      if (containerDiameterCm != null && containerDiameterCm > 0)
        'container_diameter_cm': containerDiameterCm,
      if (containerCapacityMl != null && containerCapacityMl > 0)
        'container_capacity_ml': containerCapacityMl,
      if (profile != null) 'profile': profile,
    };
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        ..._authHeaders(accessToken)
      },
      body: json.encode(payload),
    );
    if (response.statusCode != 200) {
      throw Exception('Analyze name failed: ${response.statusCode}');
    }
    final jsonMap = _decodeJson(response) as Map<String, dynamic>;
    return AnalysisResult.fromJson(jsonMap);
  }

  Future<List<Map<String, dynamic>>> searchFoods(
    String query, {
    String? accessToken,
    String? lang,
    int limit = 8,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    final params = <String, String>{
      'q': trimmed,
      'limit': limit.clamp(1, 20).toString(),
      if (lang != null && lang.trim().isNotEmpty) 'lang': lang.trim(),
    };
    final uri =
        Uri.parse('$baseUrl/foods/search').replace(queryParameters: params);
    try {
      final response = await http.get(
        uri,
        headers: _authHeaders(accessToken),
      );
      if (response.statusCode != 200) {
        String detail = _bodyText(response);
        try {
          final decoded = _decodeJson(response);
          if (decoded is Map<String, dynamic>) {
            detail =
                (decoded['detail'] ?? decoded['message'] ?? detail).toString();
          }
        } catch (_) {}
        throw CatalogSearchException(
          'http_error',
          statusCode: response.statusCode,
          message: detail,
        );
      }
      final decoded = _decodeJson(response);
      if (decoded is! Map<String, dynamic>) {
        throw CatalogSearchException('invalid_payload',
            message: 'response is not an object');
      }
      final rawItems = decoded['items'];
      if (rawItems is! List) {
        throw CatalogSearchException('invalid_payload',
            message: 'items is not a list');
      }
      final items = <Map<String, dynamic>>[];
      for (final row in rawItems) {
        if (row is Map<String, dynamic>) {
          items.add(row);
        } else if (row is Map) {
          items.add(row.map((key, value) => MapEntry(key.toString(), value)));
        }
      }
      return items;
    } on CatalogSearchException {
      rethrow;
    } catch (err) {
      throw CatalogSearchException('network_error', message: err.toString());
    }
  }

  Future<void> reportFoodSearchMiss(
    String query, {
    String? accessToken,
    String? lang,
    String source = 'name_input',
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final uri = Uri.parse('$baseUrl/foods/search_miss');
    final payload = <String, dynamic>{
      'query': trimmed,
      if (lang != null && lang.trim().isNotEmpty) 'lang': lang.trim(),
      'source': source,
    };
    try {
      await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          ..._authHeaders(accessToken)
        },
        body: json.encode(payload),
      );
    } catch (_) {
      // Ignore telemetry failures.
    }
  }

  Future<Map<String, dynamic>> suggestMeal(
    Map<String, dynamic> payload,
    String? accessToken,
  ) async {
    final uri = Uri.parse('$baseUrl/suggest_meal');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        ..._authHeaders(accessToken)
      },
      body: json.encode(payload),
    );
    if (response.statusCode != 200) {
      throw Exception('Suggest meal failed: ${response.statusCode}');
    }
    return _decodeJson(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> accessStatus({
    String? accessToken,
  }) async {
    final uri = Uri.parse('$baseUrl/access_status');
    final response = await http
        .get(
          uri,
          headers: _authHeaders(accessToken),
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw Exception('Access status failed: ${response.statusCode}');
    }
    return _decodeJson(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> chat(
    Map<String, dynamic> payload,
    String? accessToken,
  ) async {
    final uri = Uri.parse('$baseUrl/chat');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        ..._authHeaders(accessToken)
      },
      body: json.encode(payload),
    );
    if (response.statusCode != 200) {
      throw ChatApiException(response.statusCode, _bodyText(response));
    }
    return _decodeJson(response) as Map<String, dynamic>;
  }
}

class ChatApiException implements Exception {
  ChatApiException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() => 'ChatApiException($statusCode)';
}
