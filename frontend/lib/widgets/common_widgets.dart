import 'package:flutter/material.dart';
import '../models/models.dart';

class SourceCard extends StatelessWidget {
  final SourceReference source;
  final VoidCallback onOpenCitation;

  const SourceCard({
    super.key,
    required this.source,
    required this.onOpenCitation,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(top: 8),
      color: scheme.surfaceContainerHighest.withOpacity(0.45),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onOpenCitation,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.description_outlined, size: 16, color: scheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      source.filename,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Page ${source.pageNumber}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  if (source.similarityScore != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      '${(source.similarityScore! * 100).toStringAsFixed(0)}% match',
                      style: TextStyle(fontSize: 11, color: scheme.outline),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '"${source.excerpt}"',
                style: TextStyle(
                  fontSize: 12.5,
                  fontStyle: FontStyle.italic,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: scheme.primary.withOpacity(0.75)),
            const SizedBox(height: 14),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 18),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}