import 'package:bookshelf/data/models/book_directory_group.dart';
import 'package:bookshelf/features/library/widgets/book_cover_image.dart';
import 'package:bookshelf/features/library/widgets/book_spine_tile.dart';
import 'package:flutter/material.dart';

/// Folder on the shelf: several PDF first-page covers stacked like spines.
class DirectorySpineTile extends StatelessWidget {
  const DirectorySpineTile({
    required this.group,
    required this.onTap,
    super.key,
  });

  final BookDirectoryGroup group;
  final VoidCallback onTap;

  static const double tileWidth = 96;
  static const double tileHorizontalMargin = 6;
  static const double layoutWidth = tileWidth + tileHorizontalMargin * 2;
  static const double _miniSpineWidth = 40;
  static const double _miniSpineHeight = 108;
  static const double _spineOffset = 13;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = group.books.take(5).toList();
    final stackWidth =
        _miniSpineWidth + _spineOffset * (preview.length - 1).clamp(0, 4);

    final tile = SizedBox(
      width: layoutWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: tileWidth,
            height: BookSpineTile.bookHeight,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: SizedBox(
                width: stackWidth,
                height: _miniSpineHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomLeft,
                  children: [
                    for (var i = 0; i < preview.length; i++)
                      Positioned(
                        left: i * _spineOffset,
                        bottom: 0,
                        child: _MiniSpine(
                          bookId: preview[i].book.id,
                          pdfPath: preview[i].book.localPath,
                          tiltIndex: i,
                        ),
                      ),
                    if (group.bookCount > preview.length)
                      Positioned(
                        right: 0,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+${group.bookCount - preview.length}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            group.displayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.left,
            style: theme.textTheme.labelSmall?.copyWith(
              height: 1.15,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '${group.bookCount} 冊',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: tile,
    );
  }
}

class _MiniSpine extends StatelessWidget {
  const _MiniSpine({
    required this.bookId,
    required this.pdfPath,
    required this.tiltIndex,
  });

  final String bookId;
  final String pdfPath;
  final int tiltIndex;

  @override
  Widget build(BuildContext context) {
    final tilt = ((tiltIndex % 5) - 2) * 0.85;

    return Transform.rotate(
      angle: tilt * 3.14159 / 180,
      alignment: Alignment.bottomCenter,
      child: Container(
        width: DirectorySpineTile._miniSpineWidth,
        height: DirectorySpineTile._miniSpineHeight,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(3),
            topRight: Radius.circular(3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 4,
              offset: const Offset(1, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(3),
            topRight: Radius.circular(3),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              BookCoverImage(bookId: bookId, pdfPath: pdfPath),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 3,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
