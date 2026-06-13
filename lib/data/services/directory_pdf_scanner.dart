import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:bookshelf/data/services/saf_storage_helper.dart';
import 'package:path/path.dart' as p;
import 'package:saf/saf.dart';

class ScannedPdf {
  const ScannedPdf({
    required this.sourcePath,
    required this.relativePath,
  });

  final String sourcePath;
  final String relativePath;
}

class DirectoryScanResult {
  const DirectoryScanResult({
    required this.pdfs,
    this.errorMessage,
  });

  final List<ScannedPdf> pdfs;
  final String? errorMessage;
}

abstract final class DirectoryPdfScanner {
  /// Scans [rootPath] for PDF files. On Android uses SAF (recursive). Else uses [Directory.list].
  static Future<DirectoryScanResult> scan(
    String rootPath, {
    bool recursive = true,
  }) async {
    if (!kIsWeb && Platform.isAndroid) {
      return _scanAndroid(rootPath);
    }
    return _scanFileSystem(rootPath, recursive: recursive);
  }

  static Future<DirectoryScanResult> _scanAndroid(String rootPath) async {
    try {
      final safPath = SafStorageHelper.toSafStoragePath(rootPath);
      final paths = await Saf.getFilesPathFor(safPath, fileType: 'application');
      if (paths == null) {
        return const DirectoryScanResult(
          pdfs: [],
          errorMessage: 'フォルダ内のファイル一覧を取得できませんでした。設定でフォルダを選び直すか、もう一度フォルダを指定してください。',
        );
      }

      final pdfs = <ScannedPdf>[];
      final safRoot = SafStorageHelper.toSafStoragePath(rootPath);

      for (final path in paths) {
        if (!path.toLowerCase().endsWith('.pdf')) continue;

        final safFile = SafStorageHelper.toSafStoragePath(path);
        final relative = safRoot.isNotEmpty && safFile.startsWith('$safRoot/')
            ? safFile.substring(safRoot.length + 1)
            : p.basename(path);
        pdfs.add(ScannedPdf(sourcePath: path, relativePath: relative));
      }

      pdfs.sort((a, b) => a.relativePath.compareTo(b.relativePath));
      return DirectoryScanResult(pdfs: pdfs);
    } catch (e) {
      return DirectoryScanResult(
        pdfs: [],
        errorMessage: 'フォルダのスキャンに失敗しました: $e',
      );
    }
  }

  static Future<DirectoryScanResult> _scanFileSystem(
    String rootPath, {
    required bool recursive,
  }) async {
    final root = Directory(rootPath);
    if (!await root.exists()) {
      return const DirectoryScanResult(
        pdfs: [],
        errorMessage: 'フォルダが見つかりません',
      );
    }

    final pdfs = <ScannedPdf>[];
    final normalizedRoot = _normalizePath(rootPath);

    try {
      await _walkDirectory(
        root,
        normalizedRoot: normalizedRoot,
        out: pdfs,
        recursive: recursive,
      );
    } catch (e) {
      return DirectoryScanResult(
        pdfs: pdfs,
        errorMessage: '一部のフォルダを読み取れませんでした: $e',
      );
    }

    pdfs.sort((a, b) => a.relativePath.compareTo(b.relativePath));
    return DirectoryScanResult(pdfs: pdfs);
  }

  static Future<void> _walkDirectory(
    Directory dir, {
    required String normalizedRoot,
    required List<ScannedPdf> out,
    required bool recursive,
  }) async {
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is File) {
        final path = _normalizePath(entity.path);
        if (!path.toLowerCase().endsWith('.pdf')) continue;
        out.add(
          ScannedPdf(
            sourcePath: path,
            relativePath: _relativeToRoot(normalizedRoot, path),
          ),
        );
      } else if (recursive && entity is Directory) {
        try {
          await _walkDirectory(
            entity,
            normalizedRoot: normalizedRoot,
            out: out,
            recursive: true,
          );
        } catch (_) {
          // Skip unreadable subdirectories.
        }
      }
    }
  }

  static String _normalizePath(String path) {
    return p.normalize(p.absolute(path));
  }

  static String _relativeToRoot(String normalizedRoot, String filePath) {
    final relative = p.relative(filePath, from: normalizedRoot);
    if (relative == '.' || relative.startsWith('..')) {
      return p.basename(filePath);
    }
    return relative;
  }
}
