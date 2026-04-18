import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/chat_models.dart';

class SatacenterApi {
  SatacenterApi({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<List<ProjectSummary>> fetchProjects() async {
    final response = await _client.get(Uri.parse('$baseUrl/projects'));
    _ensureSuccess(response, 'Could not load projects');

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final items = json['projects'] as List<dynamic>? ?? const [];
    return items
        .map((item) => ProjectSummary.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ChatResponse> sendMessage({
    required String message,
    required List<ChatTurn> history,
    String? project,
    int topK = 5,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'message': message,
        'project': project,
        'top_k': topK,
        'history': history.map((item) => item.toJson()).toList(),
      }),
    );
    _ensureSuccess(response, 'Could not send the question');
    return ChatResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  void dispose() {
    _client.close();
  }

  void _ensureSuccess(http.Response response, String prefix) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw Exception('$prefix: ${response.statusCode} ${response.body}');
  }
}
