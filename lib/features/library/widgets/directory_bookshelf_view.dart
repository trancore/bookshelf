import 'package:bookshelf/core/utils/chunk_list.dart';
import 'package:bookshelf/data/models/book_directory_group.dart';
import 'package:bookshelf/data/models/book_with_tags.dart';
import 'package:bookshelf/data/models/library_sort_order.dart';
import 'package:bookshelf/features/library/widgets/directory_bookshelf_row.dart';
import 'package:flutter/material.dart';

class DirectoryBookshelfView extends StatelessWidget {
  const DirectoryBookshelfView({
    required this.parentPath,
    required this.books,
    required this.sortOrder,
    required this.onDirectoryTap,
    super.key,
  });

  final String parentPath;
  final List<BookWithTags> books;
  final LibrarySortOrder sortOrder;
  final void Function(BookDirectoryGroup group) onDirectoryTap;

  static const int directoriesPerShelf = 4;

  @override
  Widget build(BuildContext context) {
    final groups = listChildDirectoryGroups(
      books,
      parentPath,
      sortOrder: sortOrder,
    );
    if (groups.isEmpty) return const SizedBox.shrink();

    final shelves = chunkList(groups, directoriesPerShelf);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final shelf in shelves)
          DirectoryBookshelfRow(
            directories: shelf,
            onDirectoryTap: onDirectoryTap,
          ),
      ],
    );
  }
}
