import 'package:bookshelf/data/models/book_directory_group.dart';
import 'package:bookshelf/data/models/book_with_tags.dart';

enum LibrarySortOrder {
  titleAsc,
  titleDesc,
  recentlyOpened,
  importedNewest,
  importedOldest;

  String get storageKey => name;

  static LibrarySortOrder fromStorage(String? value) {
    return LibrarySortOrder.values.firstWhere(
      (e) => e.name == value,
      orElse: () => LibrarySortOrder.recentlyOpened,
    );
  }

  String get label => switch (this) {
        LibrarySortOrder.titleAsc => '名前順（A→Z）',
        LibrarySortOrder.titleDesc => '名前順（Z→A）',
        LibrarySortOrder.recentlyOpened => '最近開いた順',
        LibrarySortOrder.importedNewest => '追加日（新しい順）',
        LibrarySortOrder.importedOldest => '追加日（古い順）',
      };
}

void sortBooks(List<BookWithTags> books, LibrarySortOrder order) {
  books.sort(_bookComparator(order));
}

/// Returns a new list sorted by [order] without mutating [books].
List<BookWithTags> sortedBookCopies(
  List<BookWithTags> books,
  LibrarySortOrder order,
) {
  final copy = List<BookWithTags>.from(books);
  sortBooks(copy, order);
  return copy;
}

int Function(BookWithTags, BookWithTags) _bookComparator(LibrarySortOrder order) {
  return switch (order) {
    LibrarySortOrder.titleAsc => (a, b) => _compareTitle(a, b),
    LibrarySortOrder.titleDesc => (a, b) => _compareTitle(b, a),
    LibrarySortOrder.recentlyOpened => (a, b) {
      final aTime = a.book.lastOpenedAt ?? a.book.importedAt;
      final bTime = b.book.lastOpenedAt ?? b.book.importedAt;
      final cmp = bTime.compareTo(aTime);
      return cmp != 0 ? cmp : _compareTitle(a, b);
    },
    LibrarySortOrder.importedNewest => (a, b) {
      final cmp = b.book.importedAt.compareTo(a.book.importedAt);
      return cmp != 0 ? cmp : _compareTitle(a, b);
    },
    LibrarySortOrder.importedOldest => (a, b) {
      final cmp = a.book.importedAt.compareTo(b.book.importedAt);
      return cmp != 0 ? cmp : _compareTitle(a, b);
    },
  };
}

int _compareTitle(BookWithTags a, BookWithTags b) {
  final cmp = a.book.displayTitle.toLowerCase().compareTo(
        b.book.displayTitle.toLowerCase(),
      );
  return cmp != 0 ? cmp : a.book.id.compareTo(b.book.id);
}

void sortDirectoryGroups(List<BookDirectoryGroup> groups, LibrarySortOrder order) {
  groups.sort((a, b) => _compareDirectories(a, b, order));
}

int _compareDirectories(
  BookDirectoryGroup a,
  BookDirectoryGroup b,
  LibrarySortOrder order,
) {
  final cmp = switch (order) {
    LibrarySortOrder.titleAsc =>
      a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
    LibrarySortOrder.titleDesc =>
      b.displayName.toLowerCase().compareTo(a.displayName.toLowerCase()),
    LibrarySortOrder.recentlyOpened =>
      _maxLastOpened(b).compareTo(_maxLastOpened(a)),
    LibrarySortOrder.importedNewest =>
      _maxImported(b).compareTo(_maxImported(a)),
    LibrarySortOrder.importedOldest =>
      _minImported(a).compareTo(_minImported(b)),
  };
  return cmp != 0 ? cmp : a.path.compareTo(b.path);
}

DateTime _maxLastOpened(BookDirectoryGroup group) {
  var latest = group.books.first.book.importedAt;
  for (final item in group.books) {
    final opened = item.book.lastOpenedAt ?? item.book.importedAt;
    if (opened.isAfter(latest)) latest = opened;
  }
  return latest;
}

DateTime _maxImported(BookDirectoryGroup group) {
  var latest = group.books.first.book.importedAt;
  for (final item in group.books) {
    if (item.book.importedAt.isAfter(latest)) {
      latest = item.book.importedAt;
    }
  }
  return latest;
}

DateTime _minImported(BookDirectoryGroup group) {
  var earliest = group.books.first.book.importedAt;
  for (final item in group.books) {
    if (item.book.importedAt.isBefore(earliest)) {
      earliest = item.book.importedAt;
    }
  }
  return earliest;
}
