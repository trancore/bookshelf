import 'package:bookshelf/data/db/database.dart';

class BookWithTags {
  const BookWithTags({
    required this.book,
    required this.tags,
  });

  final Book book;
  final List<Tag> tags;
}
