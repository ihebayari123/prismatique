class ProjectSummary {
  const ProjectSummary({
    required this.project,
    required this.documentCount,
    required this.chunkCount,
    required this.pageCount,
  });

  final String project;
  final int documentCount;
  final int chunkCount;
  final int? pageCount;

  factory ProjectSummary.fromJson(Map<String, dynamic> json) {
    return ProjectSummary(
      project: json['project'] as String? ?? '',
      documentCount: (json['document_count'] as num?)?.toInt() ?? 0,
      chunkCount: (json['chunk_count'] as num?)?.toInt() ?? 0,
      pageCount: (json['page_count'] as num?)?.toInt(),
    );
  }
}

class SourceSnippet {
  const SourceSnippet({
    required this.project,
    required this.filename,
    required this.page,
    required this.chunkIndex,
    required this.score,
    required this.snippet,
  });

  final String project;
  final String filename;
  final int? page;
  final int chunkIndex;
  final double score;
  final String snippet;

  factory SourceSnippet.fromJson(Map<String, dynamic> json) {
    return SourceSnippet(
      project: json['project'] as String? ?? '',
      filename: json['filename'] as String? ?? '',
      page: (json['page'] as num?)?.toInt(),
      chunkIndex: (json['chunk_index'] as num?)?.toInt() ?? 0,
      score: (json['score'] as num?)?.toDouble() ?? 0,
      snippet: json['snippet'] as String? ?? '',
    );
  }
}

class ChatTurn {
  const ChatTurn({
    required this.role,
    required this.content,
    this.sources = const [],
  });

  final String role;
  final String content;
  final List<SourceSnippet> sources;

  bool get isUser => role == 'user';

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
    };
  }
}

class ChatResponse {
  const ChatResponse({
    required this.answer,
    required this.sources,
    required this.project,
    required this.llmError,
  });

  final String answer;
  final List<SourceSnippet> sources;
  final String? project;
  final String? llmError;

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    final rawSources = (json['sources'] as List<dynamic>? ?? const []);
    return ChatResponse(
      answer: json['answer'] as String? ?? '',
      project: json['project'] as String?,
      llmError: json['llm_error'] as String?,
      sources: rawSources
          .map((item) => SourceSnippet.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
