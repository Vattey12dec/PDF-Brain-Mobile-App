import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/app_providers.dart';
import 'documents_and_viewer_screens.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _questionCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  static const List<String> _suggestedPrompts = [
    'Summarize the main concepts and objectives in this PDF.',
    'Solve the exercises or tables in this assignment step-by-step.',
    'What are the key definitions and formulas mentioned?',
    'List the main conclusions and key takeaways.',
  ];

  @override
  void dispose() {
    _questionCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _submitQuestion([String? presetQuestion]) async {
    final text = (presetQuestion ?? _questionCtrl.text).trim();
    if (text.isEmpty) return;

    final chatProv = context.read<ChatProvider>();
    if (chatProv.isAsking) return;

    if (presetQuestion == null) {
      _questionCtrl.clear();
    }

    _scrollToBottom();
    await chatProv.askQuestion(text);
    _scrollToBottom();
  }

  void _openCitationInViewer(
      BuildContext context, SourceReferenceModel source) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(
          documentId: source.documentId,
          filename: source.filename,
          initialPage: source.pageNumber,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final docProv = context.watch<DocumentProvider>();
    final chatProv = context.watch<ChatProvider>();
    final readyDocs = docProv.readyDocuments;
    final turns = chatProv.activeSessionTurns;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask PDF Brain'),
        actions: [
          if (turns.isNotEmpty)
            IconButton(
              tooltip: 'New Chat',
              icon: const Icon(Icons.add_comment_outlined),
              onPressed: chatProv.isAsking
                  ? null
                  : () {
                      chatProv.startNewSession();
                    },
            ),
        ],
      ),
      body: Column(
        children: [
          // Document Filter Bar
          if (readyDocs.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.15),
                  ),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All Ready PDFs'),
                      selected: chatProv.selectedDocumentIds.isEmpty,
                      onSelected: (_) => chatProv.clearDocumentFilters(),
                    ),
                    const SizedBox(width: 8),
                    ...readyDocs.map((doc) {
                      final isSelected =
                          chatProv.selectedDocumentIds.contains(doc.id);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            doc.filename,
                            overflow: TextOverflow.ellipsis,
                          ),
                          selected: isSelected,
                          onSelected: (_) =>
                              chatProv.toggleDocumentSelection(doc.id),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

          // Main Messages List or Empty State
          Expanded(
            child: readyDocs.isEmpty
                ? _buildNoDocumentsState(context)
                : turns.isEmpty && !chatProv.isAsking
                    ? _buildEmptyChatState(context)
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(16),
                        itemCount:
                            turns.length + (chatProv.isAsking ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == turns.length) {
                            return const _TypingIndicatorCard();
                          }
                          final turn = turns[index];
                          return _TurnExchangeWidget(
                            turn: turn,
                            onTapSource: (source) =>
                                _openCitationInViewer(context, source),
                          );
                        },
                      ),
          ),

          // Error Banner with Retry
          if (chatProv.error != null)
            Container(
              width: double.infinity,
              color: theme.colorScheme.errorContainer,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: theme.colorScheme.onErrorContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      chatProv.error!,
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: chatProv.isAsking
                        ? null
                        : () => chatProv.retryLastQuestion(),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),

          // Question Input Bar
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.15),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _questionCtrl,
                      enabled: readyDocs.isNotEmpty && !chatProv.isAsking,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submitQuestion(),
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: readyDocs.isEmpty
                            ? 'Upload and index a PDF first to ask questions...'
                            : 'Ask a question about your uploaded PDFs...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: (readyDocs.isEmpty || chatProv.isAsking)
                        ? null
                        : () => _submitQuestion(),
                    icon: chatProv.isAsking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDocumentsState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.picture_as_pdf_outlined,
              size: 56,
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'No Ready PDFs Available',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload a PDF document from the Home or Documents tab and wait for RAG indexing to complete before asking questions.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChatState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'Ask Anything About Your PDFs',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Answers are grounded in your uploaded documents with clickable page citations.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _suggestedPrompts.map((prompt) {
                  return ActionChip(
                    avatar: const Icon(Icons.lightbulb_outline, size: 16),
                    label: Text(prompt),
                    onPressed: () => _submitQuestion(prompt),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingIndicatorCard extends StatelessWidget {
  const _TypingIndicatorCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Searching PDF chunks & generating grounded answer...',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _TurnExchangeWidget extends StatelessWidget {
  final ChatTurnModel turn;
  final void Function(SourceReferenceModel source) onTapSource;

  const _TurnExchangeWidget({
    required this.turn,
    required this.onTapSource,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNotFound = !turn.foundInDocuments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // User Question Bubble
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 680),
            margin: const EdgeInsets.only(bottom: 12, left: 48),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              turn.question,
              style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontSize: 15,
              ),
            ),
          ),
        ),

        // AI Answer Bubble
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 760),
            margin: const EdgeInsets.only(bottom: 20, right: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isNotFound
                  ? theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.35)
                  : theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isNotFound
                    ? theme.colorScheme.outlineVariant
                    : theme.colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isNotFound
                          ? Icons.info_outline_rounded
                          : Icons.auto_awesome_rounded,
                      size: 18,
                      color: isNotFound
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isNotFound
                          ? 'Not Found in Uploaded PDFs'
                          : 'PDF Brain Answer',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isNotFound
                            ? theme.colorScheme.secondary
                            : theme.colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Copy Answer',
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: turn.answer));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Answer copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                MarkdownBody(
                  data: turn.answer,
                  selectable: true,
                ),
                if (turn.sources.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Text(
                    'Verified Page Citations (${turn.sources.length}):',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: turn.sources.map((src) {
                      return InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => onTapSource(src),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer
                                .withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.menu_book_rounded,
                                size: 14,
                                color:
                                    theme.colorScheme.onSecondaryContainer,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '${src.filename} • Page ${src.pageNumber}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: theme
                                        .colorScheme.onSecondaryContainer,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}