import 'package:bookshelf/data/models/library_sync_state.dart';
import 'package:bookshelf/data/repositories/library_repository.dart';
import 'package:bookshelf/data/repositories/library_sync_cache_repository.dart';
import 'package:bookshelf/data/services/directory_pdf_scanner.dart';
import 'package:bookshelf/data/services/import_service.dart';

class LibrarySyncService {
  LibrarySyncService({
    required ImportService importService,
    required LibraryRepository libraryRepository,
    required LibrarySyncCacheRepository cacheRepository,
  })  : _importService = importService,
        _libraryRepository = libraryRepository,
        _cacheRepository = cacheRepository;

  final ImportService _importService;
  final LibraryRepository _libraryRepository;
  final LibrarySyncCacheRepository _cacheRepository;

  Future<LibrarySyncResult> syncFromDirectory(
    String directoryPath, {
    String? treeUri,
    bool recursive = true,
  }) async {
    final scan = await DirectoryPdfScanner.scan(
      directoryPath,
      recursive: recursive,
      treeUri: treeUri,
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
    final cachedPaths = cache?.matchesDirectory(directoryPath) == true
        ? cache!.filePaths
        : <String>{};

    final pathsToImport = <ScannedPdf>[];
    var skipped = 0;
    for (final pdf in scan.pdfs) {
      if (cachedPaths.contains(pdf.relativePath) &&
          await _libraryRepository.existsByFileName(pdf.relativePath)) {
        skipped++;
        continue;
      }
      pathsToImport.add(pdf);
    }

    final pathsToImportKeys = pathsToImport.map((pdf) => pdf.relativePath).toSet();

    if (pathsToImport.isEmpty) {
      if (scan.pdfs.isNotEmpty) {
        await _cacheRepository.save(
          directoryPath: directoryPath,
          filePaths: scannedPaths,
        );
      }
      return LibrarySyncResult(
        importedCount: 0,
        skippedCount: skipped,
        failedCount: 0,
        errorMessage: scan.errorMessage,
      );
    }

    var imported = 0;
    var failed = 0;
    String? errorMessage = scan.errorMessage;
    final syncedPaths = scan.pdfs
        .where((pdf) => !pathsToImportKeys.contains(pdf.relativePath))
        .map((pdf) => pdf.relativePath)
        .toSet();

    for (final item in pathsToImport) {
      final result = await _importService.importFromPath(
        item.sourcePath,
        originalFileName: item.relativePath,
        duplicateKey: item.relativePath,
        safRootDirectory: directoryPath,
        safRootTreeUri: treeUri,
        skipPdfMetadata: true,
        skipThumbnail: true,
      );

      switch (result) {
        case ImportSuccess():
          imported++;
          syncedPaths.add(item.relativePath);
        case ImportDuplicate():
          skipped++;
          syncedPaths.add(item.relativePath);
        case ImportFailure(:final message):
          failed++;
          errorMessage ??= message;
        case ImportCancelled():
          break;
      }

      await Future<void>.delayed(Duration.zero);
    }

    if (syncedPaths.isNotEmpty) {
      await _cacheRepository.save(
        directoryPath: directoryPath,
        filePaths: syncedPaths,
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
