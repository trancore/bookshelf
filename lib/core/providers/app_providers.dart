import 'package:bookshelf/data/db/database.dart';
import 'package:bookshelf/data/repositories/library_repository.dart';
import 'package:bookshelf/data/services/import_service.dart';
import 'package:bookshelf/data/services/thumbnail_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return LibraryRepository(ref.watch(databaseProvider));
});

final thumbnailServiceProvider = Provider<ThumbnailService>((ref) {
  return ThumbnailService();
});

final importServiceProvider = Provider<ImportService>((ref) {
  return ImportService(
    libraryRepository: ref.watch(libraryRepositoryProvider),
    thumbnailService: ref.watch(thumbnailServiceProvider),
  );
});
