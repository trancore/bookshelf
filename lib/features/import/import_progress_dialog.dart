import 'package:bookshelf/features/import/import_progress.dart';
import 'package:flutter/material.dart';

class ImportProgressDialog extends StatelessWidget {
  const ImportProgressDialog({
    required this.current,
    required this.total,
    required this.status,
    super.key,
  });

  final int current;
  final int total;
  final String status;

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? current / total : null;
    return AlertDialog(
      title: const Text('PDFを読み込み中'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 16),
          Text(
            status,
            textAlign: TextAlign.center,
          ),
          if (total > 0) ...[
            const SizedBox(height: 8),
            Text(
              '$current / $total 件',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> showImportProgress(
  BuildContext context, {
  required ValueNotifier<DirectoryImportProgress> progress,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return ValueListenableBuilder(
        valueListenable: progress,
        builder: (context, value, _) {
          return ImportProgressDialog(
            current: value.current,
            total: value.total,
            status: value.status,
          );
        },
      );
    },
  );
}
