import 'package:bookshelf/features/library/widgets/bookshelf_colors.dart';
import 'package:bookshelf/features/library/widgets/shelf_plank.dart';
import 'package:flutter/material.dart';

/// Shelf back panel plus plank; [child] sits on the shelf surface.
class ShelfRowFrame extends StatelessWidget {
  const ShelfRowFrame({
    required this.child,
    required this.shelfHeight,
    this.horizontalPadding = const EdgeInsets.fromLTRB(12, 16, 12, 0),
    this.outerPadding = const EdgeInsets.fromLTRB(12, 4, 12, 0),
    this.plankBottomMargin = 20,
    super.key,
  });

  final Widget child;
  final double shelfHeight;
  final EdgeInsets horizontalPadding;
  final EdgeInsets outerPadding;
  final double plankBottomMargin;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Padding(
      padding: outerPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: horizontalPadding,
            decoration: BoxDecoration(
              color: BookshelfColors.shelfBack(brightness),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: brightness == Brightness.dark ? 0.35 : 0.12,
                  ),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SizedBox(
              height: shelfHeight,
              width: double.infinity,
              child: child,
            ),
          ),
          ShelfPlank(
            brightness: brightness,
            bottomMargin: plankBottomMargin,
          ),
        ],
      ),
    );
  }
}
