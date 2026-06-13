import 'package:bookshelf/data/models/book_with_tags.dart';
import 'package:bookshelf/data/models/reading_progress.dart';
import 'package:bookshelf/features/library/widgets/book_cover_image.dart';
import 'package:flutter/material.dart';

class BookListTile extends StatelessWidget {
  const BookListTile({
    required this.item,
    required this.onTap,
    required this.onLongPress,
    this.selectionMode = false,
    this.isSelected = false,
    super.key,
  });

  final BookWithTags item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool selectionMode;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final book = item.book;
    final theme = Theme.of(context);
    final reading = ReadingProgress.fromBook(book);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      color: isSelected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: selectionMode ? null : onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectionMode) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 52,
                  height: 72,
                  child: BookCoverImage(
                    bookId: book.id,
                    pdfPath: book.localPath,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (item.tags.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.tags.map((t) => t.name).join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                    if (reading.hasKnownLength || reading.hasStartedReading) ...[
                      const SizedBox(height: 8),
                      if (reading.hasKnownLength)
                        LinearProgressIndicator(
                          value: reading.progress.clamp(0, 1),
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(2),
                        )
                      else
                        const LinearProgressIndicator(
                          minHeight: 4,
                          borderRadius: BorderRadius.all(Radius.circular(2)),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        reading.hasKnownLength
                            ? '${book.lastReadPage} / ${book.pageCount} ページ'
                            : '${book.lastReadPage} ページまで読了',
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
