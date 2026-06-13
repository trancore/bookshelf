import 'package:bookshelf/data/models/book_with_tags.dart';
import 'package:bookshelf/data/models/reading_progress.dart';
import 'package:bookshelf/features/library/widgets/book_cover_image.dart';
import 'package:bookshelf/features/library/widgets/bookshelf_colors.dart';
import 'package:flutter/material.dart';

class BookSpineTile extends StatelessWidget {
  const BookSpineTile({
    required this.item,
    required this.onTap,
    required this.onLongPress,
    this.slotWidth,
    this.selectionMode = false,
    this.isSelected = false,
    super.key,
  });

  final BookWithTags item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool selectionMode;
  final bool isSelected;

  /// Column width on the shelf (always 1 / [booksPerRow] of the row).
  final double? slotWidth;

  static const double bookWidth = 85;
  static const double bookHeight = 118;
  static const double layoutWidth = bookWidth + 6;
  static const double titleAreaHeight = 34;
  static const double tileHeight = bookHeight + 6 + titleAreaHeight;

  double get _tiltDegrees {
    final hash = item.book.id.hashCode;
    return ((hash % 5) - 2) * 0.9;
  }

  @override
  Widget build(BuildContext context) {
    final book = item.book;
    final reading = ReadingProgress.fromBook(book);
    final theme = Theme.of(context);

    final tile = SizedBox(
      width: layoutWidth,
      height: tileHeight,
      child: Column(
          children: [
            SizedBox(
              height: bookHeight,
              width: bookWidth,
              child: ClipRect(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Transform.rotate(
                    angle: _tiltDegrees * 3.14159 / 180,
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: bookWidth,
                      height: bookHeight,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.28),
                            blurRadius: 6,
                            offset: const Offset(2, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            BookCoverImage(
                              bookId: book.id,
                              pdfPath: book.localPath,
                            ),
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              width: 4,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.black.withValues(alpha: 0.35),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (reading.showIndicator)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: LinearProgressIndicator(
                                  value: reading.hasKnownLength
                                      ? reading.progress.clamp(0, 1)
                                      : null,
                                  minHeight: 3,
                                  backgroundColor: Colors.black26,
                                  color: BookshelfColors.accent,
                                ),
                              ),
                            if (selectionMode)
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? theme.colorScheme.primary.withValues(alpha: 0.35)
                                        : Colors.black.withValues(alpha: 0.08),
                                    border: isSelected
                                        ? Border.all(
                                            color: theme.colorScheme.primary,
                                            width: 2,
                                          )
                                        : null,
                                  ),
                                  child: Align(
                                    alignment: Alignment.topRight,
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(
                                        isSelected
                                            ? Icons.check_circle
                                            : Icons.circle_outlined,
                                        size: 22,
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: titleAreaHeight,
              child: Text(
                book.displayTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  height: 1.15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
    );

    return GestureDetector(
      onTap: onTap,
      onLongPress: selectionMode ? null : onLongPress,
      child: slotWidth != null
          ? SizedBox(
              width: slotWidth,
              child: Align(
                alignment: Alignment.topLeft,
                child: tile,
              ),
            )
          : tile,
    );
  }
}
