import 'package:bookshelf/core/providers/app_providers.dart';
import 'package:bookshelf/core/providers/settings_providers.dart';
import 'package:bookshelf/data/services/directory_picker_service.dart';
import 'package:bookshelf/data/services/import_service.dart';
import 'package:bookshelf/features/import/import_progress.dart';
import 'package:bookshelf/features/import/import_progress_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// PDF import flows for the library screen.
class LibraryImportActions {
  LibraryImportActions({
    required this.ref,
    required this.context,
    required this.isImporting,
    required this.setImporting,
  });

  final WidgetRef ref;
  final BuildContext context;
  final bool isImporting;
  final void Function(bool value) setImporting;

  Future<void> importSinglePdf() async {
    if (isImporting) return;
    setImporting(true);
    try {
      final result = await ref.read(importServiceProvider).pickAndImport();
      if (!context.mounted) return;
      _showSingleImportMessage(result);
    } finally {
      if (context.mounted) setImporting(false);
    }
  }

  Future<void> importFromDirectory({String? directoryPath}) async {
    if (isImporting) return;

    final path = directoryPath ??
        await DirectoryPickerService.pickDirectory(
          dialogTitle: 'PDFフォルダを選択',
        );
    if (!context.mounted || path == null) return;

    await _runDirectoryImport(path);
  }

  Future<void> importFromDefaultDirectory() async {
    final settings = ref.read(appSettingsProvider);
    if (!settings.hasDefaultDirectory) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('設定でデフォルトフォルダを指定してください')),
      );
      return;
    }
    await importFromDirectory(directoryPath: settings.defaultDirectoryPath);
  }

  void showImportOptionsSheet() {
    final settings = ref.read(appSettingsProvider);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('PDFを1件追加'),
              subtitle: const Text('ファイルを1つ選ぶ'),
              onTap: () {
                Navigator.pop(sheetContext);
                importSinglePdf();
              },
            ),
            if (settings.hasDefaultDirectory)
              ListTile(
                leading: const Icon(Icons.folder_special_outlined),
                title: const Text('デフォルトフォルダから追加'),
                subtitle: Text(
                  settings.defaultDirectoryPath!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  importFromDefaultDirectory();
                },
              ),
            ListTile(
              leading: const Icon(Icons.folder_open_outlined),
              title: const Text('フォルダを選んで追加'),
              subtitle: const Text('別のフォルダ内の PDF をまとめて読み込む'),
              onTap: () {
                Navigator.pop(sheetContext);
                importFromDirectory();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runDirectoryImport(String directoryPath) async {
    if (isImporting) return;

    setImporting(true);
    final progress = ValueNotifier<DirectoryImportProgress>((
      current: 0,
      total: 0,
      status: '準備しています…',
    ));

    if (context.mounted) {
      // ignore: unawaited_futures
      showImportProgress(context, progress: progress);
    }

    try {
      final summary = await ref.read(importServiceProvider).importPdfsFromDirectory(
            directoryPath,
            recursive: true,
            onProgress: (value) => progress.value = value,
          );
      if (context.mounted) _showDirectoryImportMessage(summary);
    } finally {
      if (context.mounted) {
        final navigator = Navigator.of(context, rootNavigator: true);
        if (navigator.canPop()) navigator.pop();
        setImporting(false);
      }
    }
  }

  void _showDirectoryImportMessage(DirectoryImportSummary summary) {
    if (summary.isCancelled) return;

    final message = switch (summary.foundCount) {
      0 => summary.failures.isNotEmpty
          ? summary.failures.first
          : 'フォルダ内に PDF が見つかりませんでした（サブフォルダも検索済み）',
      _ =>
        '${summary.importedCount} 件を追加'
        '${summary.duplicateCount > 0 ? '（${summary.duplicateCount} 件は重複のためスキップ）' : ''}'
        '${summary.failedCount > 0 ? '（${summary.failedCount} 件は失敗）' : ''}',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: summary.failures.length > 1 ? 6 : 4),
        action: summary.failures.length > 1
            ? SnackBarAction(
                label: '詳細',
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('インポート結果'),
                      content: SingleChildScrollView(
                        child: Text(summary.failures.join('\n')),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('閉じる'),
                        ),
                      ],
                    ),
                  );
                },
              )
            : null,
      ),
    );
  }

  void _showSingleImportMessage(ImportResult result) {
    final message = switch (result) {
      ImportSuccess(:final book) => '「${book.displayTitle}」を追加しました',
      ImportDuplicate() => '同じファイルは既に本棚にあります',
      ImportCancelled() => null,
      ImportFailure(:final message) => message,
    };
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
