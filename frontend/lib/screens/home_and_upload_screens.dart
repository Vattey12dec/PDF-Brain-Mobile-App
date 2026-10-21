import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/config/app_config.dart';
import '../providers/app_providers.dart';
import '../widgets/common_widgets.dart';
import 'documents_and_viewer_screens.dart';
import 'chat_screen.dart';
import 'history_and_profile_screens.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentProvider>().loadDocuments();
      context.read<ChatProvider>().loadConversations();
    });
  }

  void _switchTab(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeDashboardScreen(onNavigateTab: _switchTab),
      DocumentsScreen(onOpenChatTab: () => _switchTab(2)),
      const ChatScreen(),
      HistoryScreen(onOpenChatTab: () => _switchTab(2)),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _switchTab,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.folder_outlined), label: 'Documents'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Ask AI'),
          NavigationDestination(icon: Icon(Icons.history_outlined), label: 'History'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class HomeDashboardScreen extends StatelessWidget {
  final ValueChanged<int> onNavigateTab;

  const HomeDashboardScreen({super.key, required this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final docProv = context.watch<DocumentProvider>();
    final chatProv = context.watch<ChatProvider>();
    final fullName = auth.user?.userMetadata?['full_name'] ?? auth.user?.email ?? 'Student';

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Brain'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Upload PDF',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UploadDocumentsScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await docProv.loadDocuments();
          await chatProv.loadConversations();
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Hello, $fullName',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Upload course PDFs and ask grounded questions with verifiable page citations.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.picture_as_pdf_outlined),
                          const SizedBox(height: 8),
                          Text(
                            '${docProv.documents.length}',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Text('Indexed PDFs'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.forum_outlined),
                          const SizedBox(height: 8),
                          Text(
                            '${chatProv.conversations.length}',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Text('Saved Chats'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('Upload PDF Documents'),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UploadDocumentsScreen()),
              ),
            ),
            const SizedBox(height: 24),
            if (docProv.documents.isEmpty)
              EmptyStateView(
                icon: Icons.cloud_upload_outlined,
                title: 'Your Knowledge Base Is Empty',
                message: 'Upload your first lecture slide deck, textbook chapter, or research paper to begin.',
                action: OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UploadDocumentsScreen()),
                  ),
                  child: const Text('Select PDF File'),
                ),
              )
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Documents', style: Theme.of(context).textTheme.titleMedium),
                  TextButton(
                    onPressed: () => onNavigateTab(1),
                    child: const Text('View All'),
                  ),
                ],
              ),
              ...docProv.documents.take(3).map(
                    (doc) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                        title: Text(doc.filename, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${doc.pageCount} pages • ${doc.chunkCount} chunks • ${doc.status.toUpperCase()}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.question_answer_outlined),
                          tooltip: 'Ask about this PDF',
                          onPressed: () {
                            chatProv.setSingleDocumentScope(doc.id);
                            onNavigateTab(2);
                          },
                        ),
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

class UploadDocumentsScreen extends StatefulWidget {
  const UploadDocumentsScreen({super.key});

  @override
  State<UploadDocumentsScreen> createState() => _UploadDocumentsScreenState();
}

class _UploadDocumentsScreenState extends State<UploadDocumentsScreen> {
  final List<PlatformFile> _selectedFiles = [];
  bool _isUploading = false;
  int _activeStageIndex = -1;
  String? _statusMessage;
  String? _errorMessage;

  static const List<String> _pipelineStages = [
    '1. Uploading PDF to secure server',
    '2. Extracting page-by-page text (PyMuPDF)',
    '3. Creating overlapping text chunks',
    '4. Generating Gemini vector embeddings',
    '5. Indexing vectors in ChromaDB',
    '6. Ready for Question Answering',
  ];

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
      withData: true,
    );
    if (result == null) return;

    setState(() {
      _errorMessage = null;
      for (final f in result.files) {
        if (!f.name.toLowerCase().endsWith('.pdf')) {
          _errorMessage = '${f.name} is not a PDF file.';
          continue;
        }
        if (f.size > AppConfig.maxUploadSizeMb * 1024 * 1024) {
          _errorMessage = '${f.name} exceeds ${AppConfig.maxUploadSizeMb} MB limit.';
          continue;
        }
        final alreadyAdded = _selectedFiles.any((existing) => existing.name == f.name && existing.size == f.size);
        if (!alreadyAdded) {
          _selectedFiles.add(f);
        }
      }
    });
  }

  Future<void> _uploadAll() async {
    if (_selectedFiles.isEmpty || _isUploading) return;
    setState(() {
      _isUploading = true;
      _errorMessage = null;
      _activeStageIndex = 0;
    });

    final docProv = context.read<DocumentProvider>();

    for (final file in List<PlatformFile>.from(_selectedFiles)) {
      if (file.bytes == null) continue;
      setState(() {
        _statusMessage = 'Processing ${file.name}...';
        _activeStageIndex = 1;
      });

      final uploaded = await docProv.uploadPdf(filename: file.name, bytes: file.bytes!);
      if (uploaded == null) {
        setState(() {
          _errorMessage = docProv.error ?? 'Failed to process ${file.name}';
          _isUploading = false;
        });
        return;
      }

      setState(() {
        _activeStageIndex = 5;
        _selectedFiles.remove(file);
      });
    }

    setState(() {
      _isUploading = false;
      _statusMessage = 'All selected PDFs have been indexed and are ready!';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload PDF Documents')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.add_circle_outline),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Select PDF Files (Max 25 MB each)'),
            ),
            onPressed: _isUploading ? null : _pickFiles,
          ),
          const SizedBox(height: 16),
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
              ),
            ),
          if (_selectedFiles.isNotEmpty) ...[
            Text('Selected Files (${_selectedFiles.length})', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._selectedFiles.map(
              (f) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                  title: Text(f.name),
                  subtitle: Text('${(f.size / 1024).toStringAsFixed(1)} KB'),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isUploading
                        ? null
                        : () => setState(() => _selectedFiles.remove(f)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.cloud_upload),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(_isUploading ? 'Processing & Indexing...' : 'Start Upload & RAG Indexing'),
              ),
              onPressed: _isUploading ? null : _uploadAll,
            ),
          ],
          if (_activeStageIndex >= 0) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _statusMessage ?? 'RAG Indexing Pipeline',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(_pipelineStages.length, (idx) {
                      final isDone = _activeStageIndex >= idx && !_isUploading && _errorMessage == null;
                      final isCurrent = _isUploading && idx <= 4;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              isDone
                                  ? Icons.check_circle
                                  : (isCurrent ? Icons.sync : Icons.radio_button_unchecked),
                              size: 18,
                              color: isDone ? Colors.green : Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(_pipelineStages[idx])),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}