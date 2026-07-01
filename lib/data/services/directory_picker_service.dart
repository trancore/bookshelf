import 'dart:io';

import 'package:bookshelf/data/services/saf_directory_access.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// Result of picking a directory on the current platform.
class PickedDirectory {
  const PickedDirectory({
    required this.path,
    this.treeUri,
  });

  final String path;

  /// Android SAF tree URI. Null on other platforms.
  final String? treeUri;
}

/// Picks a directory path on the current platform.
abstract final class DirectoryPickerService {
  static Future<PickedDirectory?> pickDirectory({String? dialogTitle}) async {
    if (!kIsWeb && Platform.isAndroid) {
      final picked = await SafDirectoryAccess.pickDirectory();
      if (picked == null) return null;
      return PickedDirectory(path: picked.path, treeUri: picked.treeUri);
    }

    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: dialogTitle ?? 'PDFフォルダを選択',
    );
    if (path == null) return null;
    return PickedDirectory(path: path);
  }
}
