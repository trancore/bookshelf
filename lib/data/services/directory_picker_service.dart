import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:saf/saf.dart';

/// Picks a directory path on the current platform.
abstract final class DirectoryPickerService {
  static Future<String?> pickDirectory({String? dialogTitle}) async {
    if (!kIsWeb && Platform.isAndroid) {
      return _pickDirectoryAndroid();
    }
    return FilePicker.platform.getDirectoryPath(
      dialogTitle: dialogTitle ?? 'PDFフォルダを選択',
    );
  }

  static Future<String?> _pickDirectoryAndroid() async {
    final granted = await Saf.getDynamicDirectoryPermission();
    if (granted != true) return null;

    final directories = await Saf.getPersistedPermissionDirectories();
    if (directories == null || directories.isEmpty) return null;
    return directories.last;
  }
}
