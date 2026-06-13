import 'package:bookshelf/data/models/book_directory_group.dart';
import 'package:bookshelf/features/library/widgets/book_spine_tile.dart';
import 'package:bookshelf/features/library/widgets/directory_spine_tile.dart';
import 'package:bookshelf/features/library/widgets/shelf_row_frame.dart';
import 'package:flutter/material.dart';

class DirectoryBookshelfRow extends StatelessWidget {
  const DirectoryBookshelfRow({
    required this.directories,
    required this.onDirectoryTap,
    super.key,
  });

  final List<BookDirectoryGroup> directories;
  final void Function(BookDirectoryGroup group) onDirectoryTap;

  @override
  Widget build(BuildContext context) {
    return ShelfRowFrame(
      shelfHeight: BookSpineTile.bookHeight + 52,
      horizontalPadding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      outerPadding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      plankBottomMargin: 28,
      child: Align(
        alignment: Alignment.bottomLeft,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.bottomLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final group in directories)
                DirectorySpineTile(
                  group: group,
                  onTap: () => onDirectoryTap(group),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
