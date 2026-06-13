import 'package:bookshelf/core/utils/chunk_list.dart';
import 'package:bookshelf/data/models/book_with_tags.dart';
import 'package:bookshelf/features/library/widgets/bookshelf_row.dart';
import 'package:flutter/material.dart';

/// Shelf layout helpers and empty-state decoration.
abstract final class BookshelfLayout {
  static int booksPerShelfForWidth(double width) {
    if (width >= 900) return 6;
    if (width >= 600) return 5;
    return 4;
  }

  /// Shelf rows as slivers (for [CustomScrollView] parents).
  static List<Widget> buildBookSlivers({
    required BuildContext context,
    required List<BookWithTags> books,
    required void Function(BookWithTags book) onBookTap,
    required void Function(BookWithTags book) onBookLongPress,
    bool selectionMode = false,
    Set<String> selectedBookIds = const {},
    EdgeInsets padding = const EdgeInsets.only(top: 8),
  }) {
    if (books.isEmpty) return [];

    final width = MediaQuery.sizeOf(context).width;
    final perShelf = booksPerShelfForWidth(width);
    final shelves = chunkList(books, perShelf);

    return [
      SliverPadding(
        padding: padding,
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => BookshelfRow(
              books: shelves[index],
              booksPerRow: perShelf,
              selectionMode: selectionMode,
              selectedBookIds: selectedBookIds,
              onBookTap: onBookTap,
              onBookLongPress: onBookLongPress,
            ),
            childCount: shelves.length,
          ),
        ),
      ),
    ];
  }
}

/// 本がないときに見せる空の本棚（3段）。
class EmptyBookshelfDecoration extends StatelessWidget {
  const EmptyBookshelfDecoration({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 24),
      children: const [
        _EmptyShelfRow(),
        _EmptyShelfRow(),
        _EmptyShelfRow(),
      ],
    );
  }
}

class _EmptyShelfRow extends StatelessWidget {
  const _EmptyShelfRow();

  @override
  Widget build(BuildContext context) {
    return BookshelfRow(
      books: const [],
      onBookTap: (_) {},
      onBookLongPress: (_) {},
    );
  }
}
