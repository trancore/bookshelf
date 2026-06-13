import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

class Books extends Table {
  TextColumn get id => text()();
  TextColumn get fileName => text()();
  TextColumn get displayTitle => text()();
  TextColumn get localPath => text()();
  IntColumn get pageCount => integer().withDefault(const Constant(0))();
  IntColumn get lastReadPage => integer().withDefault(const Constant(1))();
  DateTimeColumn get lastOpenedAt => dateTime().nullable()();
  DateTimeColumn get importedAt => dateTime()();
  IntColumn get fileSizeBytes => integer()();
  TextColumn get sourcePath => text().nullable()();
  TextColumn get sourceTreeRootPath => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {name},
      ];
}

class BookTags extends Table {
  TextColumn get bookId => text().references(Books, #id, onDelete: KeyAction.cascade)();
  IntColumn get tagId => integer().references(Tags, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column<Object>> get primaryKey => {bookId, tagId};
}

@DriftDatabase(tables: [Books, Tags, BookTags])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(books, books.sourcePath);
            await m.addColumn(books, books.sourceTreeRootPath);
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'bookshelf.sqlite'));
    return NativeDatabase(file);
  });
}
