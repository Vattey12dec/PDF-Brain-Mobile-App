class DocumentModel {
  final String id;
  final String ownerId;
  final String filename;
  final int fileSizeBytes;
  final int pageCount;
  final int chunkCount;
  final String status;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DocumentModel({
    required this.id,
    required this.ownerId,
    required this.filename,
    required this.fileSizeBytes,
    required this.pageCount,
    required this.chunkCount,
    required this.status,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isReady => status == 'ready';

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      filename: json['filename'] as String,
      fileSizeBytes: (json['file_size_bytes'] as num?)?.toInt() ?? 0,
      pageCount: (json['page_count'] as num?)?.toInt() ?? 0,
      chunkCount: (json['chunk_count'] as num?)?.toInt() ?? 0,
      status: json['status'] as String,
      errorMessage: json['error_message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class DocumentProcessingStatus {
  final String id;
  final String filename;
  final String status;
  final int pageCount;
  final int chunkCount;
  final String? errorMessage;

  const DocumentProcessingStatus({
    required this.id,
    required this.filename,
    required this.status,
    required this.pageCount,
    required this.chunkCount,
    this.errorMessage,
  });

  factory DocumentProcessingStatus.fromJson(Map<String, dynamic> json) {
    return DocumentProcessingStatus(
      id: json['id'] as String,
      filename: json['filename'] as String,
      status: json['status'] as String,
      pageCount: (json['page_count'] as num?)?.toInt() ?? 0,
      chunkCount: (json['chunk_count'] as num?)?.toInt() ?? 0,
      errorMessage: json['error_message'] as String?,
    );
  }
}

class SourceReference {
  final String documentId;
  final String filename;
  final int pageNumber;
  final String excerpt;
  final double? similarityScore;

  const SourceReference({
    required this.documentId,
    required this.filename,
    required this.pageNumber,
    required this.excerpt,
    this.similarityScore,
  });

  factory SourceReference.fromJson(Map<String, dynamic> json) {
    return SourceReference(
      documentId: json['document_id'] as String,
      filename: json['filename'] as String,
      pageNumber: (json['page_number'] as num).toInt(),
      excerpt: json['excerpt'] as String,
      similarityScore: (json['similarity_score'] as num?)?.toDouble(),
    );
  }
}

class AskQuestionRequest {
  final String question;
  final List<String>? documentIds;
  final String? conversationId;

  const AskQuestionRequest({
    required this.question,
    this.documentIds,
    this.conversationId,
  });

  Map<String, dynamic> toJson() => {
        'question': question,
        if (documentIds != null && documentIds!.isNotEmpty)
          'document_ids': documentIds,
        if (conversationId != null) 'conversation_id': conversationId,
      };
}

class AskQuestionResponse {
  final String conversationId;
  final String messageId;
  final String answer;
  final bool foundInDocuments;
  final List<SourceReference> sources;

  const AskQuestionResponse({
    required this.conversationId,
    required this.messageId,
    required this.answer,
    required this.foundInDocuments,
    required this.sources,
  });

  factory AskQuestionResponse.fromJson(Map<String, dynamic> json) {
    final rawSources = (json['sources'] as List<dynamic>? ?? []);
    return AskQuestionResponse(
      conversationId: json['conversation_id'] as String,
      messageId: json['message_id'] as String,
      answer: json['answer'] as String,
      foundInDocuments: json['found_in_documents'] as bool,
      sources: rawSources
          .map((item) => SourceReference.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String role;
  final String content;
  final bool foundInDocuments;
  final List<SourceReference> sources;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.foundInDocuments,
    required this.sources,
    required this.createdAt,
  });

  bool get isUser => role == 'user';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final rawSources = (json['sources'] as List<dynamic>? ?? []);
    return ChatMessage(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      foundInDocuments: json['found_in_documents'] as bool? ?? true,
      sources: rawSources
          .map((s) => SourceReference.fromJson(s as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class ConversationModel {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;

  const ConversationModel({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.messages = const [],
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final rawMessages = (json['messages'] as List<dynamic>? ?? []);
    return ConversationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      messages: rawMessages
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PdfDocumentModel {
  final String id;
  final String filename;
  final int fileSizeBytes;
  final int pageCount;
  final int chunkCount;
  final String status;
  final String? errorMessage;
  final DateTime createdAt;

  const PdfDocumentModel({
    required this.id,
    required this.filename,
    required this.fileSizeBytes,
    required this.pageCount,
    required this.chunkCount,
    required this.status,
    this.errorMessage,
    required this.createdAt,
  });

  bool get isReady => status == 'ready';
  bool get hasFailed => status == 'failed';
  bool get isProcessing => status == 'processing';

  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    final kb = fileSizeBytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(2)} MB';
  }

  factory PdfDocumentModel.fromJson(Map<String, dynamic> json) {
    return PdfDocumentModel(
      id: json['id'] as String,
      filename: json['filename'] as String,
      fileSizeBytes: (json['file_size_bytes'] as num?)?.toInt() ?? 0,
      pageCount: (json['page_count'] as num?)?.toInt() ?? 0,
      chunkCount: (json['chunk_count'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'processing',
      errorMessage: json['error_message'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class SourceReferenceModel {
  final String documentId;
  final String filename;
  final int pageNumber;
  final String excerpt;
  final double similarityScore;

  const SourceReferenceModel({
    required this.documentId,
    required this.filename,
    required this.pageNumber,
    required this.excerpt,
    required this.similarityScore,
  });

  factory SourceReferenceModel.fromJson(Map<String, dynamic> json) {
    return SourceReferenceModel(
      documentId: json['document_id'] as String,
      filename: json['filename'] as String,
      pageNumber: (json['page_number'] as num?)?.toInt() ?? 1,
      excerpt: json['excerpt'] as String? ?? '',
      similarityScore: (json['similarity_score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ChatTurnModel {
  final String id;
  final String title;
  final bool isPinned;
  final String question;
  final String answer;
  final bool foundInDocuments;
  final List<SourceReferenceModel> sources;
  final List<String> documentIds;
  final DateTime createdAt;
  DateTime get updatedAt => createdAt;

  const ChatTurnModel({
    required this.id,
    required this.title,
    this.isPinned = false,
    required this.question,
    required this.answer,
    required this.foundInDocuments,
    required this.sources,
    this.documentIds = const [],
    required this.createdAt,
  });

  ChatTurnModel copyWith({
    String? title,
    bool? isPinned,
  }) {
    return ChatTurnModel(
      id: id,
      title: title ?? this.title,
      isPinned: isPinned ?? this.isPinned,
      question: question,
      answer: answer,
      foundInDocuments: foundInDocuments,
      sources: sources,
      documentIds: documentIds,
      createdAt: createdAt,
    );
  }

  static String defaultTitleFromQuestion(String q) {
    final trimmed = q.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.isEmpty) return 'New Conversation';
    return trimmed.length <= 52 ? trimmed : '${trimmed.substring(0, 50)}...';
  }

  factory ChatTurnModel.fromJson(Map<String, dynamic> json) {
    final rawSources = json['sources'] as List<dynamic>? ?? [];
    final rawDocIds = json['document_ids'] as List<dynamic>? ?? [];
    final questionText = json['question'] as String? ?? '';
    final rawTitle = (json['title'] as String?)?.trim();

    return ChatTurnModel(
      id: (json['id'] ?? json['history_id']) as String,
      title: (rawTitle != null && rawTitle.isNotEmpty)
          ? rawTitle
          : defaultTitleFromQuestion(questionText),
      isPinned: json['is_pinned'] as bool? ?? false,
      question: questionText,
      answer: json['answer'] as String? ?? '',
      foundInDocuments: json['found_in_documents'] as bool? ?? true,
      sources: rawSources
          .map((e) => SourceReferenceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      documentIds: rawDocIds.map((e) => e.toString()).toList(),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

// Top-level alias (must live outside any class or function).
typedef PdfDocument = PdfDocumentModel;