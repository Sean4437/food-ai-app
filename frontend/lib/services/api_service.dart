import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/analysis_result.dart';

class ApiService {
  final String baseUrl;
  ApiService({required this.baseUrl});

  Future<AnalysisResult> analyzeImage(File imageFile, {String? lang}) async {
    final query = lang == null ? '' : '?lang=$lang';
    final uri = Uri.parse('$baseUrl/analyze$query');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception('Analyze failed: ${response.statusCode}');
    }

    final jsonMap = json.decode(body) as Map<String, dynamic>;
    return AnalysisResult.fromJson(jsonMap);
  }
}
