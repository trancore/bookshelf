import 'package:bookshelf/core/providers/library_providers.dart';
import 'package:bookshelf/core/providers/library_sync_providers.dart';
import 'package:bookshelf/core/providers/settings_providers.dart';
import 'package:bookshelf/data/models/app_settings.dart';
import 'package:bookshelf/data/models/book_directory_group.dart';
import 'package:bookshelf/data/models/library_sort_order.dart';
import 'package:bookshelf/features/library/book_context_actions.dart';
import 'package:bookshelf/features/library/library_import_actions.dart';
import 'package:bookshelf/features/library/library_navigation.dart';
import 'package:bookshelf/features/library/library_selection_actions.dart';
import 'package:bookshelf/features/library/widgets/bookshelf_colors.dart';
import 'package:bookshelf/features/library/widgets/bookshelf_view.dart';
import 'package:bookshelf/features/library/widgets/directory_browser_body.dart';
import 'package:bookshelf/features/library/widgets/library_sort_menu_button.dart';
import 'package:bookshelf/features/library/widgets/library_tag_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  bool _importing = false;

  LibraryImportActions get _importActions => LibraryImportActions(
        ref: ref,
        context: context,
        isImporting: _importing,
        setImporting: (value) => setState(() => _importing = value),
      );

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksStreamProvider);
    final syncState = ref.watch(librarySyncProvider);
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
            : const Text('Bookshelf'),
        backgroundColor: wallColor,
        scrolledUnderElevation: 0,
        actions: booksAsync.maybeWhen(
          data: (books) {
            final directBooks = booksDirectlyInDirectory(
              sortedBookCopies(books, settings.librarySortOrder),
              '',
              sortOrder: settings.librarySortOrder,
            );
            return buildLibrarySelectionAppBarActions(
              context: context,
              ref: ref,
              selectableBooks: directBooks,
              trailingActions: [
                if (!selection.isActive) ...[
                  const LibrarySortMenuButton(),
                  IconButton(
                    onPressed: () => context.pushNamed('settings'),
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: '設定',
                  ),
                  if (_importing)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    IconButton(
                      onPressed: _importActions.showImportOptionsSheet,
                      icon: const Icon(Icons.add),
                      tooltip: 'PDFを追加',
                    ),
                ],
              ],
            );
          },
          orElse: () => [
            if (!selection.isActive) ...[
              const LibrarySortMenuButton(),
              IconButton(
                onPressed: () => context.pushNamed('settings'),
                icon: const Icon(Icons.settings_outlined),
                tooltip: '設定',
              ),
            ],
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: SearchBar(
              hintText: 'タイトル・ファイル名で検索',
              leading: const Icon(Icons.search),
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
              ),
              onChanged: ref.read(librarySearchQueryProvider.notifier).setQuery,
            ),
          ),
          const LibraryTagFilterBar(),
          if (syncState.isSyncing && settings.hasDefaultDirectory)
            const _LibrarySyncBanner(),
          Expanded(
            child: booksAsync.when(
              data: (books) {
                if (books.isEmpty) {
                  return _EmptyLibrary(
                    isBookshelfView: isBookshelfView,
                    onImport: _importing ? null : _importActions.importSinglePdf,
                    onImportFolder:
                        _importing ? null : () => _importActions.importFromDirectory(),
                    onImportDefaultFolder: settings.hasDefaultDirectory && !_importing
                        ? _importActions.importFromDefaultDirectory
                        : null,
                  );
                }
                final sortedBooks = sortedBookCopies(books, settings.librarySortOrder);
                return DirectoryBrowserBody(
                  parentPath: '',
                  books: sortedBooks,
                  isBookshelfView: isBookshelfView,
                  sortOrder: settings.librarySortOrder,
                  onDirectoryTap: (group) => openLibraryFolder(context, group),
                  onBookTap: (book) => openReader(context, book),
                  onBookLongPress: (book) =>
                      showBookContextActions(context, ref, book),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('読み込みに失敗しました\n$error')),
            ),
          ),
        ],
      ),
      floatingActionButton: selection.isActive
          ? null
          : FloatingActionButton.extended(
              onPressed: _importing ? null : _importActions.showImportOptionsSheet,
              icon: const Icon(Icons.add),
              label: const Text('追加'),
            ),
    ),
    );
  }
}

class _LibrarySyncBanner extends StatelessWidget {
  const _LibrarySyncBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '本棚をバックグラウンドで更新しています…',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({
    required this.isBookshelfView,
    required this.onImport,
    required this.onImportFolder,
    this.onImportDefaultFolder,
  });

  final bool isBookshelfView;
  final VoidCallback? onImport;
  final VoidCallback? onImportFolder;
  final VoidCallback? onImportDefaultFolder;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (isBookshelfView) const EmptyBookshelfDecoration(),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Material(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
              elevation: 2,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.menu_book_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '本棚は空です',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'PDFまたはフォルダを追加して、棚に並べましょう',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: onImport,
                      icon: const Icon(Icons.add),
                      label: const Text('PDFを1件追加'),
                    ),
                    const SizedBox(height: 8),
                    if (onImportDefaultFolder != null) ...[
                      FilledButton.tonalIcon(
                        onPressed: onImportDefaultFolder,
                        icon: const Icon(Icons.folder_special_outlined),
                        label: const Text('デフォルトフォルダから追加'),
                      ),
                      const SizedBox(height: 8),
                    ],
                    OutlinedButton.icon(
                      onPressed: onImportFolder,
                      icon: const Icon(Icons.folder_open_outlined),
                      label: const Text('フォルダを選んで追加'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
