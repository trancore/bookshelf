import 'package:bookshelf/data/models/book_with_tags.dart';
import 'package:bookshelf/features/library/widgets/book_spine_tile.dart';
import 'package:bookshelf/features/library/widgets/shelf_row_frame.dart';
import 'package:flutter/material.dart';

class BookshelfRow extends StatelessWidget {
  const BookshelfRow({
    required this.books,
    required this.onBookTap,
    required this.onBookLongPress,
    this.booksPerRow = 4,
    this.selectionMode = false,
    this.selectedBookIds = const {},
    super.key,
  });

  final List<BookWithTags> books;
  final void Function(BookWithTags book) onBookTap;
  final void Function(BookWithTags book) onBookLongPress;
  final int booksPerRow;
  final bool selectionMode;
  final Set<String> selectedBookIds;

  @override
  Widget build(BuildContext context) {
    return ShelfRowFrame(
      shelfHeight: BookSpineTile.tileHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slotWidth = constraints.maxWidth / booksPerRow;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final book in books)
                BookSpineTile(
                  item: book,
                  slotWidth: slotWidth,
                  selectionMode: selectionMode,
                  isSelected: selectedBookIds.contains(book.book.id),
                  onTap: () => onBookTap(book),
                  onLongPress: () => onBookLongPress(book),
                ),
            ],
          );
        },
      ),
    );
  }
}
