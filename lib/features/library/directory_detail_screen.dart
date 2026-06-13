import 'package:bookshelf/core/providers/library_providers.dart';
import 'package:bookshelf/core/providers/settings_providers.dart';
import 'package:bookshelf/data/models/app_settings.dart';
import 'package:bookshelf/data/models/book_directory_group.dart';
import 'package:bookshelf/data/models/library_sort_order.dart';
import 'package:bookshelf/features/library/book_context_actions.dart';
import 'package:bookshelf/features/library/library_navigation.dart';
import 'package:bookshelf/features/library/library_selection_actions.dart';
import 'package:bookshelf/features/library/widgets/bookshelf_colors.dart';
import 'package:bookshelf/features/library/widgets/directory_browser_body.dart';
import 'package:bookshelf/features/library/widgets/library_sort_menu_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DirectoryDetailScreen extends ConsumerWidget {
  const DirectoryDetailScreen({
    required this.directoryPath,
    super.key,
  });

  final String directoryPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(booksStreamProvider);
    final settings = ref.watch(appSettingsProvider);
    final selection = ref.watch(librarySelectionProvider);
    final isBookshelfView = settings.libraryViewMode == LibraryViewMode.bookshelf;
    final wallColor = BookshelfColors.libraryBackground(context, isBookshelfView);

    return PopScope(
      canPop: !selection.isActive,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ref.read(librarySelectionProvider.notifier).exit();
      },
      child: Scaffold(
      backgroundColor: wallColor,
      appBar: AppBar(
        title: selection.isActive
            ? Text('${selection.selectedIds.length} 件選択')
            : _DirectoryTitle(directoryPath: directoryPath),
        backgroundColor: wallColor,
        scrolledUnderElevation: 0,
        actions: booksAsync.maybeWhen(
          data: (allBooks) {
            final directBooks = booksDirectlyInDirectory(
              sortedBookCopies(allBooks, settings.librarySortOrder),
              directoryPath,
              sortOrder: settings.librarySortOrder,
            );
            return buildLibrarySelectionAppBarActions(
              context: context,
              ref: ref,
              selectableBooks: directBooks,
              trailingActions: [
                if (!selection.isActive) const LibrarySortMenuButton(),
              ],
            );
          },
          orElse: () => [
            if (!selection.isActive) const LibrarySortMenuButton(),
          ],
        ),
      ),
      body: booksAsync.when(
        data: (allBooks) {
          final sortedBooks = sortedBookCopies(allBooks, settings.librarySortOrder);
          return DirectoryBrowserBody(
            parentPath: directoryPath,
            books: sortedBooks,
            isBookshelfView: isBookshelfView,
            sortOrder: settings.librarySortOrder,
            onDirectoryTap: (group) => openLibraryFolder(context, group),
            onBookTap: (book) => openReader(context, book),
            onBookLongPress: (book) => showBookContextActions(context, ref, book),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('読み込みに失敗しました\n$error')),
      ),
    ),
    );
  }
}

class _DirectoryTitle extends StatelessWidget {
  const _DirectoryTitle({required this.directoryPath});

  final String directoryPath;

  @override
  Widget build(BuildContext context) {
    final segments = directoryPath.isEmpty
        ? <String>[]
        : directoryPath.split('/').where((s) => s.isNotEmpty).toList();

    if (segments.isEmpty) {
      return const Text('その他');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(segments.last),
        if (segments.length > 1)
          Text(
            directoryPath,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
      ],
    );
  }
}
