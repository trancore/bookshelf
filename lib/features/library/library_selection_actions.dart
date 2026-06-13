import 'package:bookshelf/core/providers/app_providers.dart';
import 'package:bookshelf/core/providers/library_providers.dart';
import 'package:bookshelf/core/providers/library_sync_providers.dart';
import 'package:bookshelf/core/providers/settings_providers.dart';
import 'package:bookshelf/data/models/book_with_tags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> deleteBooks(
  BuildContext context,
  WidgetRef ref,
  List<BookWithTags> items,
) async {
  if (items.isEmpty) return;

  final message = items.length == 1
      ? '「${items.first.book.displayTitle}」を削除しますか？\nPDFファイルも端末から削除されます。'
      : '${items.length} 冊を削除しますか？\nPDFファイルも端末から削除されます。';

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(items.length == 1 ? '本を削除' : '本を一括削除'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('削除'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  final importService = ref.read(importServiceProvider);
  final repo = ref.read(libraryRepositoryProvider);
  final syncCache = ref.read(librarySyncCacheRepositoryProvider);
  final defaultDirectory = ref.read(appSettingsProvider).defaultDirectoryPath;
  for (final item in items) {
    await importService.deleteBookAssets(
      item.book,
      fallbackSourceTreeRootPath: defaultDirectory,
    );
    await repo.deleteBook(item.book.id);
    await syncCache.removeFilePath(item.book.fileName);
  }

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(items.length == 1 ? '削除しました' : '${items.length} 冊を削除しました'),
      ),
    );
  }
}

Future<void> deleteSelectedBooks(
  BuildContext context,
  WidgetRef ref, {
  required List<BookWithTags> books,
}) async {
  final selection = ref.read(librarySelectionProvider);
  final selected = books
      .where((item) => selection.selectedIds.contains(item.book.id))
      .toList();
  if (selected.isEmpty) return;

  await deleteBooks(context, ref, selected);
  ref.read(librarySelectionProvider.notifier).exit();
}

List<Widget> buildLibrarySelectionAppBarActions({
  required BuildContext context,
  required WidgetRef ref,
  required List<BookWithTags> selectableBooks,
  List<Widget> trailingActions = const [],
}) {
  final selection = ref.watch(librarySelectionProvider);

  if (!selection.isActive) {
    return [
      IconButton(
        onPressed: selectableBooks.isEmpty
            ? null
            : () => ref.read(librarySelectionProvider.notifier).enter(),
        icon: const Icon(Icons.checklist_outlined),
        tooltip: '選択',
      ),
      ...trailingActions,
    ];
  }

  final selectableIds = selectableBooks.map((b) => b.book.id).toSet();
  final allSelected = selectableIds.isNotEmpty &&
      selectableIds.every(selection.selectedIds.contains);

  return [
    IconButton(
      onPressed: selectableIds.isEmpty
          ? null
          : () {
              if (allSelected) {
                ref.read(librarySelectionProvider.notifier).clear();
              } else {
                ref.read(librarySelectionProvider.notifier).selectAll(selectableIds);
              }
            },
      icon: Icon(allSelected ? Icons.deselect : Icons.select_all),
      tooltip: allSelected ? '選択解除' : 'すべて選択',
    ),
    IconButton(
      onPressed: selection.selectedIds.isEmpty
          ? null
          : () => deleteSelectedBooks(context, ref, books: selectableBooks),
      icon: const Icon(Icons.delete_outline),
      tooltip: '削除',
    ),
    IconButton(
      onPressed: () => ref.read(librarySelectionProvider.notifier).exit(),
      icon: const Icon(Icons.close),
      tooltip: 'キャンセル',
    ),
  ];
}
