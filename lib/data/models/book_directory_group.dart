import 'dart:convert';

import 'package:bookshelf/data/models/book_with_tags.dart';
import 'package:bookshelf/data/models/library_sort_order.dart';
import 'package:path/path.dart' as p;

/// A folder grouping of books under a path in the library tree.
class BookDirectoryGroup {
  const BookDirectoryGroup({
    required this.path,
    required this.displayName,
    required this.books,
  });

  /// Full relative directory path from the import root.
  final String path;
  final String displayName;

  /// All books in this folder and nested subfolders (for spine previews).
  final List<BookWithTags> books;

  int get bookCount => books.length;
}

String directoryPathFromFileName(String fileName) {
  final dir = p.dirname(fileName);
  if (dir == '.' || dir.isEmpty) return '';
  return dir;
}

String displayNameForDirectory(String directoryPath) {
  if (directoryPath.isEmpty) return 'その他';
  return p.basename(directoryPath);
}

bool bookBelongsToDirectory(String fileName, String directoryPath) {
  return directoryPathFromFileName(fileName) == directoryPath;
}

/// URL-safe encoding for folder paths in query parameters.
String encodeDirectoryPathParam(String path) {
  if (path.isEmpty) return '';
  return base64Url.encode(utf8.encode(path));
}

String decodeDirectoryPathParam(String? encoded) {
  if (encoded == null || encoded.isEmpty) return '';
  try {
    return utf8.decode(base64Url.decode(encoded));
  } catch (_) {
    return encoded;
  }
}

bool _isUnderParent(String bookDirPath, String parentPath) {
  if (parentPath.isEmpty) return true;
  return bookDirPath == parentPath || bookDirPath.startsWith('$parentPath/');
}

/// Whether [bookDirPath] lies in the subtree of [directoryPath] (inclusive).
bool isInDirectoryTree(String bookDirPath, String directoryPath) {
  if (directoryPath.isEmpty) return true;
  return bookDirPath == directoryPath || bookDirPath.startsWith('$directoryPath/');
}

/// Next directory level under [parentPath] for a book stored in [bookDirPath].
String? immediateChildDirectoryPath(String bookDirPath, String parentPath) {
  if (!_isUnderParent(bookDirPath, parentPath)) return null;
  if (bookDirPath == parentPath) return null;

  final String suffix;
  if (parentPath.isEmpty) {
    suffix = bookDirPath;
  } else {
    suffix = bookDirPath.substring(parentPath.length + 1);
  }

  final slash = suffix.indexOf('/');
  if (slash < 0) {
    return parentPath.isEmpty ? suffix : '$parentPath/$suffix';
  }
  final first = suffix.substring(0, slash);
  return parentPath.isEmpty ? first : '$parentPath/$first';
}

/// PDFs whose file lives directly in [parentPath] (not in a subfolder).
List<BookWithTags> booksDirectlyInDirectory(
  List<BookWithTags> books,
  String parentPath, {
  LibrarySortOrder sortOrder = LibrarySortOrder.titleAsc,
}) {
  final direct = books
      .where((b) => bookBelongsToDirectory(b.book.fileName, parentPath))
      .toList();
  sortBooks(direct, sortOrder);
  return direct;
}

/// Immediate child folders of [parentPath] that contain at least one book.
List<BookDirectoryGroup> listChildDirectoryGroups(
  List<BookWithTags> books,
  String parentPath, {
  LibrarySortOrder sortOrder = LibrarySortOrder.titleAsc,
}) {
  final childPaths = <String>{};
  for (final item in books) {
    final dir = directoryPathFromFileName(item.book.fileName);
    if (!_isUnderParent(dir, parentPath)) continue;
    final child = immediateChildDirectoryPath(dir, parentPath);
    if (child != null) childPaths.add(child);
  }

  final groups = childPaths.map((path) {
    final subtree = books
        .where(
          (b) => isInDirectoryTree(
            directoryPathFromFileName(b.book.fileName),
            path,
          ),
        )
        .toList();
    sortBooks(subtree, sortOrder);
    return BookDirectoryGroup(
      path: path,
      displayName: p.basename(path),
      books: subtree,
    );
  }).toList();

  sortDirectoryGroups(groups, sortOrder);
  return groups;
}
