import 'package:bookshelf/data/models/book_directory_group.dart';
import 'package:bookshelf/data/models/book_with_tags.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void openLibraryFolder(BuildContext context, BookDirectoryGroup group) {
  context.pushNamed(
    'folder',
    queryParameters: {'path': encodeDirectoryPathParam(group.path)},
  );
}

void openReader(
  BuildContext context,
  BookWithTags item, {
  bool fromStart = false,
}) {
  context.pushNamed(
    'reader',
    pathParameters: {'bookId': item.book.id},
    queryParameters: fromStart ? const {'fromStart': 'true'} : const {},
  );
}
