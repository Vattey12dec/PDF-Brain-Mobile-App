import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/app_config.dart';
import '../models/models.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  final http.Client _httpClient;

  ApiService({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  Map<String, String> _authHeaders({bool jsonContent = true}) {
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;
    if (token == null || token.isEmpty) {
      throw const ApiException('Your session has expired. Please sign in again.', statusCode: 401);
    }
    return {
      'Authorization': 'Bearer $token',
      if (jsonContent) 'Content-Type': 'application/json',
    };
  }

  String _extractErrorDetail(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['detail'] != null) {
        return decoded['detail'].toString();
      }
    } catch (_) {}
    return 'Request failed with status ${response.statusCode}.';
  }

  Future<List<PdfDocumentModel>> fetchDocuments() async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/documents');
      final response = await _httpClient
          .get(uri, headers: _authHeaders())
          .timeout(const Duration(seconds: 25));

      if (response.statusCode != 200) {
        throw ApiException(_extractErrorDetail(response), statusCode: response.statusCode);
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = data['documents'] as List<dynamic>? ?? [];
      return list
          .map((item) => PdfDocumentModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on TimeoutException {
      throw const ApiException('Server connection timed out while loading documents.');
    }
  }

  Future<PdfDocumentModel> uploadPdfBytes({
    required String filename,
    required Uint8List bytes,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/documents/upload');
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(_authHeaders(jsonContent: false));

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
          contentType: MediaType('application', 'pdf'),
        ),
      );

      final streamed = await request.send().timeout(const Duration(seconds: 120));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode != 201) {
        throw ApiException(_extractErrorDetail(response), statusCode: response.statusCode);
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return PdfDocumentModel.fromJson(decoded);
    } on TimeoutException {
      throw const ApiException('Upload & indexing timed out. Please try a smaller PDF.');
    }
  }

  Future<Uint8List> downloadDocumentBytes(String documentId) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/documents/$documentId/file');
      final response = await _httpClient
          .get(uri, headers: _authHeaders(jsonContent: false))
          .timeout(const Duration(seconds: 45));

      if (response.statusCode != 200) {
        throw ApiException(_extractErrorDetail(response), statusCode: response.statusCode);
      }
      return response.bodyBytes;
    } on TimeoutException {
      throw const ApiException('Timed out while downloading PDF file.');
    }
  }

  Future<void> deleteDocument(String documentId) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/documents/$documentId');
    final response = await _httpClient
        .delete(uri, headers: _authHeaders())
        .timeout(const Duration(seconds: 25));

    if (response.statusCode != 200 && response.statusCode != 204) {
  throw ApiException(_extractErrorDetail(response), statusCode: response.statusCode);
}
  }

  Future<ChatTurnModel> askQuestion({
    required String question,
    List<String>? documentIds,
    String? title,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/chat/ask');
      final body = jsonEncode({
        'question': question,
        if (documentIds != null && documentIds.isNotEmpty) 'document_ids': documentIds,
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
      });

      final response = await _httpClient
          .post(uri, headers: _authHeaders(), body: body)
          .timeout(const Duration(seconds: 120));

      if (response.statusCode != 200) {
        throw ApiException(_extractErrorDetail(response), statusCode: response.statusCode);
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return ChatTurnModel.fromJson(decoded);
    } on TimeoutException {
      throw const ApiException('The AI service took too long to respond. Please retry.');
    }
  }

  Future<List<ChatTurnModel>> fetchChatHistory() async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/chat/history');
    final response = await _httpClient
        .get(uri, headers: _authHeaders())
        .timeout(const Duration(seconds: 25));

    if (response.statusCode != 200) {
      throw ApiException(_extractErrorDetail(response), statusCode: response.statusCode);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final items = decoded['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => ChatTurnModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChatTurnModel> updateHistoryItem({
    required String historyId,
    String? title,
    bool? isPinned,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/chat/history/$historyId');
    final body = jsonEncode({
      if (title != null) 'title': title,
      if (isPinned != null) 'is_pinned': isPinned,
    });

    final response = await _httpClient
        .patch(uri, headers: _authHeaders(), body: body)
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw ApiException(_extractErrorDetail(response), statusCode: response.statusCode);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return ChatTurnModel.fromJson(decoded);
  }

  Future<void> deleteHistoryItem(String historyId) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/chat/history/$historyId');
    final response = await _httpClient
        .delete(uri, headers: _authHeaders())
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 204) {
      throw ApiException(_extractErrorDetail(response), statusCode: response.statusCode);
    }
  }
}