import 'dart:async';

import 'package:bookshelf/core/providers/app_providers.dart';
import 'package:bookshelf/data/services/import_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class ShareImportListener extends ConsumerStatefulWidget {
  const ShareImportListener({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<ShareImportListener> createState() => _ShareImportListenerState();
}

class _ShareImportListenerState extends ConsumerState<ShareImportListener> {
  StreamSubscription<List<SharedMediaFile>>? _shareSubscription;

  @override
  void initState() {
    super.initState();
    _initSharing();
  }

  Future<void> _initSharing() async {
    final initial = await ReceiveSharingIntent.instance.getInitialMedia();
    if (initial.isNotEmpty) {
      await _handleSharedFiles(initial);
      await ReceiveSharingIntent.instance.reset();
    }

    _shareSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((files) async {
      await _handleSharedFiles(files);
      await ReceiveSharingIntent.instance.reset();
    });
  }

  Future<void> _handleSharedFiles(List<SharedMediaFile> files) async {
    if (!mounted) return;
    final importService = ref.read(importServiceProvider);

    for (final file in files) {
      if (!_isPdf(file)) continue;
      final result = await importService.importFromPath(
        file.path,
        originalFileName: _fileNameFromPath(file.path),
      );
      if (!mounted) return;
      _showImportSnackBar(result);
    }
  }

  bool _isPdf(SharedMediaFile file) {
    return file.path.toLowerCase().endsWith('.pdf');
  }

  String _fileNameFromPath(String path) {
    final segments = path.split('/');
    return segments.isNotEmpty ? segments.last : 'shared.pdf';
  }

  void _showImportSnackBar(ImportResult result) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final message = switch (result) {
      ImportSuccess() => '「${result.book.displayTitle}」を本棚に追加しました',
      ImportDuplicate() => '同じファイルは既に本棚にあります',
      ImportCancelled() => null,
      ImportFailure(:final message) => message,
    };
    if (message != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void dispose() {
    _shareSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
