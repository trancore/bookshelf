import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

/// Helpers for reading files through Android Storage Access Framework.
abstract final class SafStorageHelper {
  static const _channel = MethodChannel('com.bookshelf.bookshelf/saf_io');

  /// Converts absolute storage paths to the form expected by the `saf` package.
  static String toSafStoragePath(String path) {
    const prefixes = [
      '/storage/emulated/0/',
      '/storage/emulated/0',
      '/sdcard/',
      '/sdcard',
    ];
    for (final prefix in prefixes) {
      if (path == prefix) return '';
      if (path.startsWith('$prefix/') || path.startsWith(prefix)) {
        var relative = path.substring(prefix.length);
        if (relative.startsWith('/')) relative = relative.substring(1);
        return relative;
      }
    }
    if (path.startsWith('/')) return path.substring(1);
    return path;
  }

  /// Returns file size in bytes when accessible through SAF.
  static Future<int?> documentLengthBytes(
    String sourcePath, {
    String? treeRootPath,
  }) async {
    if (kIsWeb || !Platform.isAndroid) {
      final file = File(sourcePath);
      if (!await file.exists()) return null;
      return file.length();
    }

    try {
      return await _channel.invokeMethod<int>('documentLength', {
        'sourcePath': sourcePath,
        'treeRootPath': treeRootPath,
      });
    } on PlatformException {
      return null;
    }
  }

  /// Copies a SAF-backed file directly into [destPath] via ContentResolver.
  static Future<bool> copyToFile({
    required String sourcePath,
    required String destPath,
    String? treeRootPath,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return false;

    try {
      await _channel.invokeMethod<void>('copyPathToFile', {
        'sourcePath': sourcePath,
        'treeRootPath': treeRootPath,
        'destPath': destPath,
      });
      return true;
    } on PlatformException {
      return false;
    }
  }

  /// Deletes a document via SAF on Android, or the local filesystem elsewhere.
  static Future<bool> deleteFile({
    required String sourcePath,
    String? treeRootPath,
  }) async {
    if (kIsWeb) return false;

    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _channel.invokeMethod<void>('deleteDocument', {
          'sourcePath': sourcePath,
          'treeRootPath': treeRootPath,
        });
        return true;
      } on PlatformException {
        // Fall through to direct file delete.
      }
    }

    final file = File(sourcePath);
    if (!await file.exists()) return false;
    await file.delete();
    return true;
  }

  /// Fallback when direct SAF copy fails.
  static Future<String?> materializeReadablePath(
    String sourcePath, {
    String? treeRootPath,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return null;

    final tempDir = await Directory.systemTemp.createTemp('bookshelf_saf_');
    final destPath = p.join(
      tempDir.path,
      p.basename(sourcePath).replaceAll(RegExp(r'[\\/:*?"<>|]'), '_'),
    );
    final ok = await copyToFile(
      sourcePath: sourcePath,
      destPath: destPath,
      treeRootPath: treeRootPath,
    );
    if (!ok) {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
      return null;
    }
    return destPath;
  }
}
