import 'dart:io';

import 'package:bookshelf/data/db/database.dart';
import 'package:bookshelf/data/repositories/library_repository.dart';
import 'package:bookshelf/data/services/directory_pdf_scanner.dart';
import 'package:bookshelf/data/services/directory_picker_service.dart';
import 'package:bookshelf/data/services/saf_storage_helper.dart';
import 'package:bookshelf/data/services/thumbnail_service.dart';
import 'package:bookshelf/features/import/import_progress.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:uuid/uuid.dart';

sealed class ImportResult {
  const ImportResult();
}

class ImportSuccess extends ImportResult {
  const ImportSuccess(this.book);
  final Book book;
}

class ImportDuplicate extends ImportResult {
  const ImportDuplicate();
}

class ImportCancelled extends ImportResult {
  const ImportCancelled();
}

class ImportFailure extends ImportResult {
  const ImportFailure(this.message);
  final String message;
}

class DirectoryImportSummary {
  const DirectoryImportSummary({
    required this.directoryPath,
    required this.foundCount,
    required this.importedCount,
    required this.duplicateCount,
    required this.failedCount,
    required this.failures,
  });

  final String directoryPath;
  final int foundCount;
  final int importedCount;
  final int duplicateCount;
  final int failedCount;
  final List<String> failures;

  bool get isCancelled => directoryPath.isEmpty && foundCount == 0 && importedCount == 0;
}

class ImportService {
  ImportService({
    required LibraryRepository libraryRepository,
    required ThumbnailService thumbnailService,
  })  : _library = libraryRepository,
        _thumbnails = thumbnailService;

  final LibraryRepository _library;
  final ThumbnailService _thumbnails;
  final _uuid = const Uuid();

  Future<Directory> booksDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'books'));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<DirectoryImportSummary> pickDirectoryAndImport({
    bool recursive = true,
    void Function(DirectoryImportProgress progress)? onProgress,
  }) async {
    final directoryPath = await DirectoryPickerService.pickDirectory(
      dialogTitle: 'PDFフォルダを選択',
    );
    if (directoryPath == null) {
      return const DirectoryImportSummary(
        directoryPath: '',
        foundCount: 0,
        importedCount: 0,
        duplicateCount: 0,
        failedCount: 0,
        failures: [],
      );
    }
    return importPdfsFromDirectory(
      directoryPath,
      recursive: recursive,
      onProgress: onProgress,
    );
  }

  Future<DirectoryImportSummary> importPdfsFromDirectory(
    String directoryPath, {
    bool recursive = true,
    void Function(DirectoryImportProgress progress)? onProgress,
  }) async {
    void report(int current, int total, String status) {
      onProgress?.call((current: current, total: total, status: status));
    }

    report(0, 0, 'フォルダをスキャンしています…');
    final scan = await DirectoryPdfScanner.scan(
      directoryPath,
      recursive: recursive,
    );

    if (scan.pdfs.isEmpty) {
      report(0, 0, 'スキャン完了');
      final failures = <String>[];
      if (scan.errorMessage != null) failures.add(scan.errorMessage!);
      return DirectoryImportSummary(
        directoryPath: directoryPath,
        foundCount: 0,
        importedCount: 0,
        duplicateCount: 0,
        failedCount: failures.isNotEmpty ? 1 : 0,
        failures: failures,
      );
    }

    report(0, scan.pdfs.length, '${scan.pdfs.length} 件の PDF を検出しました');

    var imported = 0;
    var duplicate = 0;
    var failed = 0;
    final failures = <String>[];
    if (scan.errorMessage != null) {
      failures.add(scan.errorMessage!);
    }

    for (var i = 0; i < scan.pdfs.length; i++) {
      final item = scan.pdfs[i];
      report(
        i + 1,
        scan.pdfs.length,
        'インポート中: ${item.relativePath}',
      );

      final result = await importFromPath(
        item.sourcePath,
        originalFileName: item.relativePath,
        duplicateKey: item.relativePath,
        safRootDirectory: directoryPath,
        skipPdfMetadata: true,
        skipThumbnail: true,
      );

      switch (result) {
        case ImportSuccess():
          imported++;
        case ImportDuplicate():
          duplicate++;
        case ImportFailure(:final message):
          failed++;
          failures.add('${item.relativePath}: $message');
        case ImportCancelled():
          break;
      }

      // Let the UI repaint between large files.
      await Future<void>.delayed(Duration.zero);
    }

    report(scan.pdfs.length, scan.pdfs.length, '完了');

    return DirectoryImportSummary(
      directoryPath: directoryPath,
      foundCount: scan.pdfs.length,
      importedCount: imported,
      duplicateCount: duplicate,
      failedCount: failed,
      failures: failures,
    );
  }

  Future<ImportResult> pickAndImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      allowMultiple: false,
      withData: false,
    );
    if (result == null || result.files.isEmpty) {
      return const ImportCancelled();
    }
    final path = result.files.single.path;
    if (path == null) {
      return const ImportFailure('ファイルパスを取得できませんでした');
    }
    return importFromPath(path, originalFileName: result.files.single.name);
  }

  Future<ImportResult> importFromPath(
    String sourcePath, {
    String? originalFileName,
    String? duplicateKey,
    String? safRootDirectory,
    bool skipPdfMetadata = false,
    bool skipThumbnail = false,
  }) async {
    String? tempReadablePath;
    try {
      final fileName = originalFileName ?? p.basename(sourcePath);
      final dedupeKey = duplicateKey ?? fileName;

      var fileSize = await _sourceFileSize(
        sourcePath,
        safRootDirectory: safRootDirectory,
      );

      final bookId = _uuid.v4();
      final booksDir = await booksDirectory();
      final destPath = p.join(booksDir.path, '$bookId.pdf');

      final copied = await _copyIntoLibrary(
        sourcePath: sourcePath,
        destPath: destPath,
        safRootDirectory: safRootDirectory,
        onTempPath: (temp) => tempReadablePath = temp,
      );
      if (!copied) {
        return const ImportFailure('ストレージからファイルを読み取れませんでした');
      }

      final source = File(destPath);
      fileSize ??= await source.length();

      if (await _library.existsByFileNameAndSize(dedupeKey, fileSize)) {
        await source.delete();
        return const ImportDuplicate();
      }

      var pageCount = 0;
      if (!skipPdfMetadata) {
        try {
          final doc = await PdfDocument.openFile(destPath);
          try {
            pageCount = doc.pages.length;
          } finally {
            doc.dispose();
          }
        } catch (e) {
          await source.delete();
          return ImportFailure('PDFを開けませんでした: $e');
        }
      }

      final displayTitle =
          p.basenameWithoutExtension(p.basename(sourcePath));
      final book = await _library.insertBook(
        id: bookId,
        fileName: dedupeKey,
        displayTitle: displayTitle,
        localPath: destPath,
        pageCount: pageCount,
        fileSizeBytes: fileSize,
        sourcePath: sourcePath,
        sourceTreeRootPath: safRootDirectory,
      );

      if (!skipThumbnail) {
        await _thumbnails.generateThumbnail(bookId: bookId, pdfPath: destPath);
      }

      return ImportSuccess(book);
    } finally {
      if (tempReadablePath != null) {
        try {
          final temp = File(tempReadablePath!);
          await temp.delete();
          final parent = temp.parent;
          if (parent.path.contains('bookshelf_saf_')) {
            await parent.delete(recursive: true);
          }
        } catch (_) {
          // Best-effort cleanup.
        }
      }
    }
  }

  Future<bool> _copyIntoLibrary({
    required String sourcePath,
    required String destPath,
    String? safRootDirectory,
    void Function(String tempPath)? onTempPath,
  }) async {
    if (!kIsWeb && Platform.isAndroid) {
      final needsSaf =
          safRootDirectory != null || !await _canReadDirectly(sourcePath);
      if (needsSaf) {
        final ok = await SafStorageHelper.copyToFile(
          sourcePath: sourcePath,
          destPath: destPath,
          treeRootPath: safRootDirectory,
        );
        if (ok) return true;

        final temp = await SafStorageHelper.materializeReadablePath(
          sourcePath,
          treeRootPath: safRootDirectory,
        );
        if (temp == null) return false;
        onTempPath?.call(temp);
        await File(temp).copy(destPath);
        return true;
      }
    }

    final source = File(sourcePath);
    if (!await source.exists()) return false;
    await source.copy(destPath);
    return true;
  }

  Future<int?> _sourceFileSize(
    String sourcePath, {
    String? safRootDirectory,
  }) async {
    if (!kIsWeb && Platform.isAndroid) {
      final needsSaf =
          safRootDirectory != null || !await _canReadDirectly(sourcePath);
      if (needsSaf) {
        return SafStorageHelper.documentLengthBytes(
          sourcePath,
          treeRootPath: safRootDirectory,
        );
      }
    }

    final file = File(sourcePath);
    if (!await file.exists()) return null;
    return file.length();
  }

  Future<bool> _canReadDirectly(String path) async {
    try {
      final raf = await File(path).open(mode: FileMode.read);
      try {
        await raf.read(1);
        return true;
      } finally {
        await raf.close();
      }
    } catch (_) {
      return false;
    }
  }

  Future<void> deleteBookAssets(
    Book book, {
    String? fallbackSourceTreeRootPath,
  }) async {
    final localFile = File(book.localPath);
    if (await localFile.exists()) {
      await localFile.delete();
    }
    await _thumbnails.deleteThumbnail(book.id);

    final sourcePath = _resolveSourcePath(
      book,
      fallbackSourceTreeRootPath: fallbackSourceTreeRootPath,
    );
    if (sourcePath == null || sourcePath == book.localPath) return;

    await SafStorageHelper.deleteFile(
      sourcePath: sourcePath,
      treeRootPath: book.sourceTreeRootPath ?? fallbackSourceTreeRootPath,
    );
  }

  String? _resolveSourcePath(
    Book book, {
    String? fallbackSourceTreeRootPath,
  }) {
    final stored = book.sourcePath;
    if (stored != null && stored.isNotEmpty) return stored;

    final root = fallbackSourceTreeRootPath;
    if (root == null || root.isEmpty) return null;
    return p.join(root, book.fileName);
  }
}
