import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/models.dart';
import '../providers/app_providers.dart';
import '../widgets/common_widgets.dart';
import 'home_and_upload_screens.dart';

class DocumentsScreen extends StatelessWidget {
  final VoidCallback onOpenChatTab;

  const DocumentsScreen({super.key, required this.onOpenChatTab});

  @override
  Widget build(BuildContext context) {
    final docProv = context.watch<DocumentProvider>();
    final chatProv = context.read<ChatProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Documents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UploadDocumentsScreen()),
            ),
          ),
        ],
      ),
      body: docProv.isLoading
          ? const Center(child: CircularProgressIndicator())
          : docProv.documents.isEmpty
              ? EmptyStateView(
                  icon: Icons.folder_open_outlined,
                  title: 'No PDF Documents Uploaded',
                  message: 'Upload a PDF to extract text, generate embeddings, and start asking questions.',
                  action: FilledButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload PDF'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UploadDocumentsScreen()),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docProv.documents.length,
                  itemBuilder: (context, index) {
                    final doc = docProv.documents[index];
                    return _DocumentListCard(
                      document: doc,
                      onOpenPdf: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PdfViewerScreen(
                            documentId: doc.id,
                            filename: doc.filename,
                          ),
                        ),
                      ),
                      onAskQuestions: () {
                        chatProv.setSingleDocumentScope(doc.id);
                        onOpenChatTab();
                      },
                      onDelete: () async {
                        await docProv.deleteDocument(doc.id);
                      },
                    );
                  },
                ),
    );
  }
}

class _DocumentListCard extends StatelessWidget {
  final PdfDocumentModel document;
  final VoidCallback onOpenPdf;
  final VoidCallback onAskQuestions;
  final VoidCallback onDelete;

  const _DocumentListCard({
    required this.document,
    required this.onOpenPdf,
    required this.onAskQuestions,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat.yMMMd().format(document.createdAt.toLocal());
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    document.filename,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Chip(
                  label: Text(document.status.toUpperCase(), style: const TextStyle(fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Uploaded $formattedDate • ${document.pageCount} pages • ${document.chunkCount} indexed chunks',
              style: TextStyle(fontSize: 12.5, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            if (document.errorMessage != null) ...[
              const SizedBox(height: 6),
              Text(
                document.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('Open PDF'),
                  onPressed: onOpenPdf,
                ),
                const SizedBox(width: 6),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.chat_outlined, size: 18),
                  label: const Text('Ask AI'),
                  onPressed: document.isReady ? onAskQuestions : null,
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  tooltip: 'Delete PDF & Vectors',
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PdfViewerScreen extends StatefulWidget {
  final String documentId;
  final String filename;
  final int initialPage;

  const PdfViewerScreen({
    super.key,
    required this.documentId,
    required this.filename,
    this.initialPage = 1,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final PdfViewerController _pdfController = PdfViewerController();
  Uint8List? _pdfBytes;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final bytes = await context.read<DocumentProvider>().downloadDocumentBytes(widget.documentId);
      if (mounted) {
        setState(() {
          _pdfBytes = bytes;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.filename),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous Page',
            onPressed: () => _pdfController.previousPage(),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next Page',
            onPressed: () => _pdfController.nextPage(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? EmptyStateView(
                  icon: Icons.error_outline,
                  title: 'Could Not Load PDF',
                  message: _error!,
                )
              : SfPdfViewer.memory(
                  _pdfBytes!,
                  controller: _pdfController,
                  onDocumentLoaded: (_) {
                    if (widget.initialPage > 1) {
                      _pdfController.jumpToPage(widget.initialPage);
                    }
                  },
                ),
    );
  }
}