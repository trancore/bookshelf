import 'package:bookshelf/core/providers/app_providers.dart';
import 'package:bookshelf/data/models/book_with_tags.dart';
import 'package:bookshelf/features/library/library_navigation.dart';
import 'package:bookshelf/features/library/library_selection_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showBookContextActions(
  BuildContext context,
  WidgetRef ref,
  BookWithTags item,
) async {
  final action = await showModalBottomSheet<String>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.first_page_outlined),
            title: const Text('最初から読む'),
            subtitle: item.book.lastReadPage > 1
                ? Text('現在 ${item.book.lastReadPage} ページ')
                : null,
            onTap: () => Navigator.pop(context, 'readFromStart'),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('タイトルを編集'),
            onTap: () => Navigator.pop(context, 'rename'),
          ),
          ListTile(
            leading: const Icon(Icons.label_outline),
            title: const Text('タグを追加'),
            onTap: () => Navigator.pop(context, 'tag'),
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
            title: Text('削除', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            onTap: () => Navigator.pop(context, 'delete'),
          ),
        ],
      ),
    ),
  );

  if (!context.mounted || action == null) return;

  switch (action) {
    case 'readFromStart':
      await _readFromStart(context, ref, item);
    case 'rename':
      await _renameBook(context, ref, item);
    case 'tag':
      await _addTag(context, ref, item);
    case 'delete':
      await _deleteBook(context, ref, item);
  }
}

Future<void> _readFromStart(
  BuildContext context,
  WidgetRef ref,
  BookWithTags item,
) async {
  await ref.read(libraryRepositoryProvider).updateReadingProgress(item.book.id, 1);
  if (!context.mounted) return;
  openReader(context, item, fromStart: true);
}

Future<void> _renameBook(
  BuildContext context,
  WidgetRef ref,
  BookWithTags item,
) async {
  final controller = TextEditingController(text: item.book.displayTitle);
  final newTitle = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('タイトルを編集'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: '表示タイトル'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('保存'),
        ),
      ],
    ),
  );
  if (newTitle != null && newTitle.isNotEmpty) {
    await ref.read(libraryRepositoryProvider).updateDisplayTitle(item.book.id, newTitle);
  }
}

Future<void> _addTag(BuildContext context, WidgetRef ref, BookWithTags item) async {
  final controller = TextEditingController();
  final tagName = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('タグを追加'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: '例: 技術書'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('追加'),
        ),
      ],
    ),
  );
  if (tagName != null && tagName.isNotEmpty) {
    await ref.read(libraryRepositoryProvider).addTagToBook(item.book.id, tagName);
  }
}

Future<void> _deleteBook(
  BuildContext context,
  WidgetRef ref,
  BookWithTags item,
) async {
  await deleteBooks(context, ref, [item]);
}
