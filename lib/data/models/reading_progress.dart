import 'package:bookshelf/data/db/database.dart';

/// Normalized reading progress for list and spine tiles.
class ReadingProgress {
  const ReadingProgress({
    required this.hasKnownLength,
    required this.progress,
    required this.showIndicator,
    required this.hasStartedReading,
  });

  final bool hasKnownLength;
  final double progress;
  final bool showIndicator;
  final bool hasStartedReading;

  factory ReadingProgress.fromBook(Book book) {
    final hasKnownLength = book.pageCount > 0;
    final progress =
        hasKnownLength ? book.lastReadPage / book.pageCount : 0.0;
    final hasStartedReading = book.lastReadPage > 1;
    return ReadingProgress(
      hasKnownLength: hasKnownLength,
      progress: progress,
      showIndicator: hasKnownLength ? progress > 0 : hasStartedReading,
      hasStartedReading: hasStartedReading,
    );
  }
}
