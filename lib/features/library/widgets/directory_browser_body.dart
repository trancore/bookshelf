import 'package:bookshelf/core/providers/library_providers.dart';
import 'package:bookshelf/data/models/book_directory_group.dart';
import 'package:bookshelf/data/models/book_with_tags.dart';
import 'package:bookshelf/data/models/library_sort_order.dart';
import 'package:bookshelf/features/library/widgets/book_cover_image.dart';
import 'package:bookshelf/features/library/widgets/book_list_tile.dart';
import 'package:bookshelf/features/library/widgets/bookshelf_view.dart';
import 'package:bookshelf/features/library/widgets/directory_bookshelf_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows child folders and PDFs directly inside [parentPath].
class DirectoryBrowserBody extends ConsumerWidget {
  const DirectoryBrowserBody({
    required this.parentPath,
    required this.books,
    required this.isBookshelfView,
    required this.sortOrder,
    required this.onDirectoryTap,
    required this.onBookTap,
    required this.onBookLongPress,
    super.key,
  });

  final String parentPath;
  final List<BookWithTags> books;
  final bool isBookshelfView;
  final LibrarySortOrder sortOrder;
  final void Function(BookDirectoryGroup group) onDirectoryTap;
  final void Function(BookWithTags book) onBookTap;
  final void Function(BookWithTags book) onBookLongPress;

  void _handleBookTap(WidgetRef ref, BookWithTags book) {
    final selection = ref.read(librarySelectionProvider);
    if (selection.isActive) {
      ref.read(librarySelectionProvider.notifier).toggle(book.book.id);
      return;
    }
    onBookTap(book);
  }

  void _handleBookLongPress(WidgetRef ref, BookWithTags book) {
    final selection = ref.read(librarySelectionProvider);
    if (selection.isActive) {
      ref.read(librarySelectionProvider.notifier).toggle(book.book.id);
      return;
    }
    onBookLongPress(book);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(librarySelectionProvider);
    final childGroups = listChildDirectoryGroups(
      books,
      parentPath,
      sortOrder: sortOrder,
    );
    final directBooks = booksDirectlyInDirectory(
      books,
      parentPath,
      sortOrder: sortOrder,
    );

    if (childGroups.isEmpty && directBooks.isEmpty) {
      return const Center(child: Text('このフォルダは空です'));
    }

    if (!isBookshelfView) {
      return CustomScrollView(
        slivers: [
          if (childGroups.isNotEmpty && !selection.isActive) ...[
            SliverToBoxAdapter(
              child: _SectionLabel(
                title: parentPath.isEmpty ? 'フォルダ' : 'サブフォルダ',
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _FolderListTile(
                  group: childGroups[index],
                  onTap: () => onDirectoryTap(childGroups[index]),
                ),
                childCount: childGroups.length,
              ),
            ),
          ],
          if (directBooks.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _SectionLabel(
                title: parentPath.isEmpty ? 'PDF' : 'このフォルダの PDF',
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final book = directBooks[index];
                  return BookListTile(
                    item: book,
                    selectionMode: selection.isActive,
                    isSelected: selection.selectedIds.contains(book.book.id),
                    onTap: () => _handleBookTap(ref, book),
                    onLongPress: () => _handleBookLongPress(ref, book),
                  );
                },
                childCount: directBooks.length,
              ),
            ),
          ],
          const SliverPadding(padding: EdgeInsets.only(bottom: 88)),
        ],
      );
    }

    return CustomScrollView(
      slivers: [
        if (childGroups.isNotEmpty && !selection.isActive) ...[
          SliverToBoxAdapter(
            child: _SectionLabel(
              title: parentPath.isEmpty ? 'フォルダ' : 'サブフォルダ',
            ),
          ),
          SliverToBoxAdapter(
            child: DirectoryBookshelfView(
              parentPath: parentPath,
              books: books,
              sortOrder: sortOrder,
              onDirectoryTap: onDirectoryTap,
            ),
          ),
        ],
        if (directBooks.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _SectionLabel(
              title: parentPath.isEmpty ? 'PDF' : 'このフォルダの PDF',
            ),
          ),
          ...BookshelfLayout.buildBookSlivers(
            context: context,
            books: directBooks,
            selectionMode: selection.isActive,
            selectedBookIds: selection.selectedIds,
            onBookTap: (book) => _handleBookTap(ref, book),
            onBookLongPress: (book) => _handleBookLongPress(ref, book),
          ),
        ],
        const SliverPadding(padding: EdgeInsets.only(bottom: 88)),
      ],
    );
  }
}

class _FolderListTile extends StatelessWidget {
  const _FolderListTile({
    required this.group,
    required this.onTap,
  });

  final BookDirectoryGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = group.books.take(3).toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 88,
                height: 56,
                child: Stack(
                  children: [
                    for (var i = 0; i < preview.length; i++)
                      Positioned(
                        left: i * 22.0,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            width: 40,
                            height: 56,
                            child: BookCoverImage(
                              bookId: preview[i].book.id,
                              pdfPath: preview[i].book.localPath,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.folder_outlined,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            group.displayName,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${group.path}\n${group.bookCount} 冊',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
