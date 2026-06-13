import 'package:bookshelf/data/models/library_sync_state.dart';
import 'package:bookshelf/data/repositories/library_sync_cache_repository.dart';
import 'package:bookshelf/data/services/directory_pdf_scanner.dart';
import 'package:bookshelf/data/services/import_service.dart';

class LibrarySyncService {
  LibrarySyncService({
    required ImportService importService,
    required LibrarySyncCacheRepository cacheRepository,
  })  : _importService = importService,
        _cacheRepository = cacheRepository;

  final ImportService _importService;
  final LibrarySyncCacheRepository _cacheRepository;

  Future<LibrarySyncResult> syncFromDirectory(
    String directoryPath, {
    bool recursive = true,
  }) async {
    final scan = await DirectoryPdfScanner.scan(
      directoryPath,
      recursive: recursive,
    );

    if (scan.errorMessage != null && scan.pdfs.isEmpty) {
      return LibrarySyncResult(
        importedCount: 0,
        skippedCount: 0,
        failedCount: 1,
        errorMessage: scan.errorMessage,
      );
    }

    final scannedPaths = scan.pdfs.map((pdf) => pdf.relativePath).toSet();
    final cache = await _cacheRepository.load();

    if (cache != null &&
        cache.matchesDirectory(directoryPath) &&
        cache.hasSameFiles(scannedPaths)) {
      return LibrarySyncResult(
        importedCount: 0,
        skippedCount: scan.pdfs.length,
        failedCount: 0,
      );
    }

    final cachedPaths = cache?.matchesDirectory(directoryPath) == true
        ? cache!.filePaths
        : <String>{};
    final pathsToImport = scan.pdfs
        .where((pdf) => !cachedPaths.contains(pdf.relativePath))
        .toList();

    var imported = 0;
    var skipped = scan.pdfs.length - pathsToImport.length;
    var failed = 0;
    String? errorMessage = scan.errorMessage;

    for (final item in pathsToImport) {
      final result = await _importService.importFromPath(
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
          skipped++;
        case ImportFailure(:final message):
          failed++;
          errorMessage ??= message;
        case ImportCancelled():
          break;
      }

      await Future<void>.delayed(Duration.zero);
    }

    if (scan.pdfs.isNotEmpty) {
      await _cacheRepository.save(
        directoryPath: directoryPath,
        filePaths: scannedPaths,
      );
    }

    return LibrarySyncResult(
      importedCount: imported,
      skippedCount: skipped,
      failedCount: failed,
      errorMessage: errorMessage,
    );
  }

  Future<void> invalidateCache() => _cacheRepository.clear();
}
