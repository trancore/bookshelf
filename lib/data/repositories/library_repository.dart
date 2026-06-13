import 'package:bookshelf/data/db/database.dart';
import 'package:bookshelf/data/models/book_with_tags.dart';
import 'package:drift/drift.dart';

class LibraryRepository {
  LibraryRepository(this._db);

  final AppDatabase _db;

  Stream<List<BookWithTags>> watchBooks({String? query, int? tagId}) {
    final search = query?.trim().toLowerCase();
    return _db.select(_db.books).watch().asyncMap((books) async {
      var filtered = books;
      if (search != null && search.isNotEmpty) {
        filtered = books.where((b) {
          return b.displayTitle.toLowerCase().contains(search) ||
              b.fileName.toLowerCase().contains(search);
        }).toList();
      }

      final results = <BookWithTags>[];
      for (final book in filtered) {
        final tags = await getTagsForBook(book.id);
        if (tagId != null && !tags.any((t) => t.id == tagId)) {
          continue;
        }
        results.add(BookWithTags(book: book, tags: tags));
      }

      return results;
    });
  }

  Stream<List<Tag>> watchTagsStream() {
    return _db.select(_db.tags).watch();
  }

  Future<bool> existsByFileNameAndSize(String fileName, int fileSizeBytes) async {
    final existing = await (_db.select(_db.books)
          ..where(
            (t) => t.fileName.equals(fileName) & t.fileSizeBytes.equals(fileSizeBytes),
          ))
        .getSingleOrNull();
    return existing != null;
  }

  Future<Book> insertBook({
    required String id,
    required String fileName,
    required String displayTitle,
    required String localPath,
    required int pageCount,
    required int fileSizeBytes,
    String? sourcePath,
    String? sourceTreeRootPath,
  }) async {
    final companion = BooksCompanion.insert(
      id: id,
      fileName: fileName,
      displayTitle: displayTitle,
      localPath: localPath,
      pageCount: Value(pageCount),
      importedAt: DateTime.now(),
      fileSizeBytes: fileSizeBytes,
      sourcePath: Value(sourcePath),
      sourceTreeRootPath: Value(sourceTreeRootPath),
    );
    await _db.into(_db.books).insert(companion);
    return (await getBook(id))!;
  }

  Future<Book?> getBook(String id) {
    return (_db.select(_db.books)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> updateReadingProgress(String id, int pageNumber) async {
    await (_db.update(_db.books)..where((t) => t.id.equals(id))).write(
      BooksCompanion(
        lastReadPage: Value(pageNumber),
        lastOpenedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updatePageCount(String id, int pageCount) async {
    if (pageCount <= 0) return;
    await (_db.update(_db.books)..where((t) => t.id.equals(id))).write(
      BooksCompanion(pageCount: Value(pageCount)),
    );
  }

  Future<void> updateDisplayTitle(String id, String title) async {
    await (_db.update(_db.books)..where((t) => t.id.equals(id))).write(
      BooksCompanion(displayTitle: Value(title)),
    );
  }

  Future<void> deleteBook(String id) async {
    await (_db.delete(_db.books)..where((t) => t.id.equals(id))).go();
  }

  Future<List<Tag>> getTagsForBook(String bookId) async {
    final query = _db.select(_db.tags).join([
      innerJoin(
        _db.bookTags,
        _db.bookTags.tagId.equalsExp(_db.tags.id) &
            _db.bookTags.bookId.equals(bookId),
      ),
    ]);
    return query.map((row) => row.readTable(_db.tags)).get();
  }

  Future<Tag> getOrCreateTag(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Tag name cannot be empty');
    }
    final existing = await (_db.select(_db.tags)..where((t) => t.name.equals(trimmed)))
        .getSingleOrNull();
    if (existing != null) return existing;

    final id = await _db.into(_db.tags).insert(TagsCompanion.insert(name: trimmed));
    return (_db.select(_db.tags)..where((t) => t.id.equals(id))).getSingle();
  }

  Future<void> addTagToBook(String bookId, String tagName) async {
    final tag = await getOrCreateTag(tagName);
    await _db.into(_db.bookTags).insert(
      BookTagsCompanion.insert(bookId: bookId, tagId: tag.id),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<void> removeTagFromBook(String bookId, int tagId) async {
    await (_db.delete(_db.bookTags)
          ..where((t) => t.bookId.equals(bookId) & t.tagId.equals(tagId)))
        .go();
  }
}
