import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme([bool? isDark]) {
    if (isDark != null) {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    } else {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    }
    notifyListeners();
  }
}

class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  void setTab(int index) {
    if (_currentIndex == index) return;
    _currentIndex = index;
    notifyListeners();
  }
}

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;
  ThemeMode _themeMode = ThemeMode.light;

  AuthProvider() {
    _user = Supabase.instance.client.auth.currentUser;
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme([bool? isDark]) {
    if (isDark != null) {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    } else {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    }
    notifyListeners();
  }

  String get displayName {
    final meta = _user?.userMetadata;
    if (meta != null &&
        meta['full_name'] != null &&
        meta['full_name'].toString().isNotEmpty) {
      return meta['full_name'].toString();
    }
    return _user?.email?.split('@').first ?? 'Scholar';
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> signIn({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      _user = res.user;
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Unable to sign in. Please check your connection.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': fullName.trim()},
      );
      _user = res.user;
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Unable to register account. Please check your connection.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email.trim());
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Failed to send password reset email.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    _user = null;
    notifyListeners();
  }
}

class DocumentProvider extends ChangeNotifier {
  final ApiService _apiService;
  List<PdfDocumentModel> _documents = [];
  bool _isLoading = false;
  bool _isUploading = false;
  int _uploadStageIndex = 0;
  String? _error;

  DocumentProvider([ApiService? apiService])
      : _apiService = apiService ?? ApiService();

  List<PdfDocumentModel> get documents => _documents;
  List<PdfDocumentModel> get readyDocuments =>
      _documents.where((d) => d.isReady).toList();
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  int get uploadStageIndex => _uploadStageIndex;
  String? get error => _error;

  static const List<String> pipelineStages = [
    'Uploading PDF to secure server',
    'Extracting page-by-page text (PyMuPDF)',
    'Creating overlapping text chunks',
    'Generating Gemini vector embeddings',
    'Indexing vectors in ChromaDB',
    'Ready for Question Answering',
  ];

  Future<void> loadDocuments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _documents = await _apiService.fetchDocuments();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Uint8List> downloadDocumentBytes(String documentId) async {
    return await _apiService.downloadDocumentBytes(documentId);
  }

  Future<PdfDocumentModel?> uploadPdf({
    required String filename,
    required Uint8List bytes,
  }) async {
    _isUploading = true;
    _uploadStageIndex = 0;
    _error = null;
    notifyListeners();

    bool active = true;
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 650));
      if (!active || !_isUploading) return false;
      if (_uploadStageIndex < pipelineStages.length - 2) {
        _uploadStageIndex++;
        notifyListeners();
      }
      return active && _isUploading;
    });

    try {
      final uploaded = await _apiService.uploadPdfBytes(
        filename: filename,
        bytes: bytes,
      );
      active = false;
      _uploadStageIndex = pipelineStages.length - 1;
      _documents = [uploaded, ..._documents.where((d) => d.id != uploaded.id)];
      notifyListeners();
      return uploaded;
    } catch (e) {
      active = false;
      _error = e.toString();
      notifyListeners();
      return null;
    } finally {
      active = false;
      _isUploading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteDocument(String documentId) async {
    try {
      await _apiService.deleteDocument(documentId);
      _documents.removeWhere((d) => d.id == documentId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}

class ChatProvider extends ChangeNotifier {
  final ApiService _apiService;
  List<ChatTurnModel> _activeSessionTurns = [];
  List<ChatTurnModel> _historyItems = [];
  final Set<String> _selectedDocumentIds = {};
  String _conversationTitle = 'New Chat';
  bool _isAsking = false;
  bool _isLoadingHistory = false;
  String? _error;
  String? _lastAttemptedQuestion;

  ChatProvider([ApiService? apiService])
      : _apiService = apiService ?? ApiService();

  List<ChatTurnModel> get activeSessionTurns => _activeSessionTurns;
  List<ChatTurnModel> get historyItems => _historyItems;
  List<ChatTurnModel> get conversations => _historyItems;
  List<ChatTurnModel> get pinnedHistoryItems =>
      _historyItems.where((i) => i.isPinned).toList();
  List<ChatTurnModel> get unpinnedHistoryItems =>
      _historyItems.where((i) => !i.isPinned).toList();

  Set<String> get selectedDocumentIds => _selectedDocumentIds;
  String get conversationTitle => _conversationTitle;
  bool get isAsking => _isAsking;
  bool get isLoading => _isAsking;
  bool get isLoadingHistory => _isLoadingHistory;
  String? get error => _error;

  ChatTurnModel? get currentPrimaryTurn =>
      _activeSessionTurns.isNotEmpty ? _activeSessionTurns.last : null;

  bool get isCurrentConversationPinned =>
      currentPrimaryTurn?.isPinned ?? false;

  void toggleDocumentSelection(String docId) {
    if (_selectedDocumentIds.contains(docId)) {
      _selectedDocumentIds.remove(docId);
    } else {
      _selectedDocumentIds.add(docId);
    }
    notifyListeners();
  }

  void toggleDocumentFilter(String docId) => toggleDocumentSelection(docId);

  void attachDocument(String docId) {
    _selectedDocumentIds.add(docId);
    notifyListeners();
  }

  void removeAttachedDocument(String docId) {
    _selectedDocumentIds.remove(docId);
    notifyListeners();
  }

  void selectOnlyDocument(String docId, {String? customTitle}) {
    _selectedDocumentIds
      ..clear()
      ..add(docId);
    _activeSessionTurns = [];
    _conversationTitle = customTitle ?? 'New Chat';
    _error = null;
    notifyListeners();
  }

  void setSingleDocumentScope(String docId, {String? customTitle}) {
    selectOnlyDocument(docId, customTitle: customTitle);
  }

  void clearDocumentFilters() {
    _selectedDocumentIds.clear();
    notifyListeners();
  }

  void clearDocumentFilter() => clearDocumentFilters();

  void clearChat() {
    _activeSessionTurns = [];
    _error = null;
    notifyListeners();
  }

  void startNewSession({List<String>? initialDocIds}) {
    _activeSessionTurns = [];
    _selectedDocumentIds.clear();
    if (initialDocIds != null) {
      _selectedDocumentIds.addAll(initialDocIds);
    }
    _conversationTitle = 'New Chat';
    _error = null;
    notifyListeners();
  }

  void startNewConversation({List<String>? initialDocIds}) {
    startNewSession(initialDocIds: initialDocIds);
  }

  void reopenConversation(ChatTurnModel item) {
    _activeSessionTurns = [item];
    _conversationTitle = item.title;
    _selectedDocumentIds
      ..clear()
      ..addAll(item.documentIds);
    _error = null;
    notifyListeners();
  }

  Future<void> openConversation(dynamic itemOrId) async {
    if (itemOrId is ChatTurnModel) {
      reopenConversation(itemOrId);
      return;
    }
    if (itemOrId is String) {
      for (final item in _historyItems) {
        if (item.id == itemOrId) {
          reopenConversation(item);
          return;
        }
      }
    }
  }

  Future<bool> askQuestion(String question) async {
    final cleaned = question.trim();
    if (cleaned.isEmpty) return false;
    _isAsking = true;
    _error = null;
    _lastAttemptedQuestion = cleaned;
    notifyListeners();

    try {
      final isFirstTurn = _activeSessionTurns.isEmpty;
      final desiredTitle = isFirstTurn
          ? ChatTurnModel.defaultTitleFromQuestion(cleaned)
          : _conversationTitle;

      final turn = await _apiService.askQuestion(
        question: cleaned,
        documentIds: _selectedDocumentIds.isEmpty
            ? null
            : _selectedDocumentIds.toList(),
        title: desiredTitle,
      );

      if (isFirstTurn) {
        _conversationTitle = turn.title;
      }

      _activeSessionTurns = [..._activeSessionTurns, turn];
      _historyItems = [turn, ..._historyItems.where((h) => h.id != turn.id)];
      _sortHistory();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isAsking = false;
      notifyListeners();
    }
  }

  Future<void> retryLastQuestion() async {
    if (_lastAttemptedQuestion != null &&
        _lastAttemptedQuestion!.isNotEmpty) {
      await askQuestion(_lastAttemptedQuestion!);
    } else {
      _error = null;
      notifyListeners();
    }
  }

  Future<void> loadHistory() async {
    _isLoadingHistory = true;
    _error = null;
    notifyListeners();
    try {
      _historyItems = await _apiService.fetchChatHistory();
      _sortHistory();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> loadConversations() => loadHistory();

  Future<void> togglePinHistoryItem(ChatTurnModel item) async {
    final newPinned = !item.isPinned;
    _applyLocalUpdate(item.id, isPinned: newPinned);
    try {
      final updated = await _apiService.updateHistoryItem(
        historyId: item.id,
        isPinned: newPinned,
      );
      _applyServerUpdate(updated);
    } catch (e) {
      _applyLocalUpdate(item.id, isPinned: item.isPinned);
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> renameHistoryItem(String historyId, String newTitle) async {
    final cleaned = newTitle.trim();
    if (cleaned.isEmpty) return;
    _applyLocalUpdate(historyId, title: cleaned);
    if (currentPrimaryTurn?.id == historyId) {
      _conversationTitle = cleaned;
    }
    try {
      final updated = await _apiService.updateHistoryItem(
        historyId: historyId,
        title: cleaned,
      );
      _applyServerUpdate(updated);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteHistoryItem(String id) async {
    try {
      await _apiService.deleteHistoryItem(id);
      _historyItems.removeWhere((item) => item.id == id);
      _activeSessionTurns.removeWhere((item) => item.id == id);
      if (_activeSessionTurns.isEmpty) {
        _conversationTitle = 'New Chat';
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteConversation(String id) => deleteHistoryItem(id);

  void _applyLocalUpdate(String id, {String? title, bool? isPinned}) {
    _historyItems = _historyItems.map((h) {
      if (h.id == id) return h.copyWith(title: title, isPinned: isPinned);
      return h;
    }).toList();
    _activeSessionTurns = _activeSessionTurns.map((t) {
      if (t.id == id) return t.copyWith(title: title, isPinned: isPinned);
      return t;
    }).toList();
    _sortHistory();
    notifyListeners();
  }

  void _applyServerUpdate(ChatTurnModel updated) {
    _historyItems =
        _historyItems.map((h) => h.id == updated.id ? updated : h).toList();
    _activeSessionTurns = _activeSessionTurns
        .map((t) => t.id == updated.id ? updated : t)
        .toList();
    _sortHistory();
    notifyListeners();
  }

  void _sortHistory() {
    _historyItems.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });
  }
}