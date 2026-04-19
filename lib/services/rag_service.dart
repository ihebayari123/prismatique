import 'dart:convert';
import 'package:http/http.dart' as http;

class RAGService {
  static const String baseUrl = 'http://172.20.10.2:8010';
  
  // Health check to verify backend connection
  static Future<bool> checkHealth() async {
    try {
      print('🏥 Health check: $baseUrl/health');
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(const Duration(seconds: 5));
      
      print('🏥 Health check response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('🏥 Health check failed: $e');
      return false;
    }
  }
  
  // Get list of projects
  static Future<List<String>> getProjects() async {
    try {
      print('🔄 Fetching projects from: $baseUrl/projects');
      final response = await http.get(
        Uri.parse('$baseUrl/projects'),
      ).timeout(const Duration(seconds: 20));

      print('📡 Projects response status: ${response.statusCode}');
      print('📡 Projects response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Decoded JSON: $data');
        
        if (data is Map && data['projects'] is List) {
          // Extract project names from objects
          final projects = (data['projects'] as List)
              .map((p) => p['project'] as String)
              .toList();
          print('✅ Projects loaded: ${projects.length} found - $projects');
          return projects;
        } else {
          print('❌ Response format wrong. Expected {projects: [...]}, got: $data');
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
      }
      return [];
    } catch (e) {
      print('❌ Error fetching projects: $e');
      print('❌ Error type: ${e.runtimeType}');
      return [];
    }
  }

  // Chat with RAG
  static Future<ChatResponse?> chat({
    required String message,
    String? project,
    int topK = 5,
    List<Map<String, String>>? history,
  }) async {
    try {
      print('💬 Sending chat message to: $baseUrl/chat');
      
      // First check if backend is healthy
      final healthOk = await checkHealth();
      if (!healthOk) {
        print('❌ Backend health check failed - server may not be running');
        return null;
      }
      print('✅ Backend is healthy');
      
      final body = {
        'message': message,
        'project': project,
        'top_k': topK,
        'history': history ?? [],
      };
      print('💬 Request body: $body');

      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Connection': 'keep-alive',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 180));

      print('💬 Chat response status: ${response.statusCode}');
      print('💬 Chat response: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Chat response decoded successfully');
        return ChatResponse.fromJson(data);
      } else {
        print('❌ Chat HTTP error: ${response.statusCode} - ${response.body}');
      }
      return null;
    } catch (e) {
      print('❌ Error sending chat message: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Suggestion: Ensure backend is running: cd C:\\hackaton_project && .\\\.venv\\Scripts\\python.exe -m uvicorn app:app --host 0.0.0.0 --port 8010');
      return null;
    }
  }

  // Query with RAG (one-shot)
  static Future<QueryResponse?> query({
    required String question,
    String? project,
    int topK = 5,
    bool useLlm = true,
  }) async {
    try {
      final body = {
        'question': question,
        'project': project,
        'top_k': topK,
        'use_llm': useLlm,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/query'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 180));  // 3 minutes for LLM inference

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return QueryResponse.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error querying RAG: $e');
      return null;
    }
  }
}

class ChatResponse {
  final String answer;
  final List<Source> sources;
  final String? status;

  ChatResponse({
    required this.answer,
    required this.sources,
    this.status,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      answer: json['answer'] ?? '',
      sources: (json['sources'] as List?)
              ?.map((s) => Source.fromJson(s))
              .toList() ??
          [],
      status: json['status'],
    );
  }
}

class QueryResponse {
  final String answer;
  final List<Source> sources;

  QueryResponse({
    required this.answer,
    required this.sources,
  });

  factory QueryResponse.fromJson(Map<String, dynamic> json) {
    return QueryResponse(
      answer: json['answer'] ?? '',
      sources: (json['sources'] as List?)
              ?.map((s) => Source.fromJson(s))
              .toList() ??
          [],
    );
  }
}

class Source {
  final String project;
  final String filename;
  final int page;
  final int chunkIndex;
  final double score;
  final String snippet;

  Source({
    required this.project,
    required this.filename,
    required this.page,
    required this.chunkIndex,
    required this.score,
    required this.snippet,
  });

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(
      project: json['project'] ?? '',
      filename: json['filename'] ?? '',
      page: json['page'] ?? 0,
      chunkIndex: json['chunk_index'] ?? 0,
      score: (json['score'] ?? 0.0).toDouble(),
      snippet: json['snippet'] ?? '',
    );
  }
}
