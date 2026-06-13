import 'package:bookshelf/features/library/widgets/bookshelf_colors.dart';
import 'package:flutter/material.dart';

/// Wooden plank under a shelf row.
class ShelfPlank extends StatelessWidget {
  const ShelfPlank({
    required this.brightness,
    this.bottomMargin = 20,
    super.key,
  });

  final Brightness brightness;
  final double bottomMargin;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 16,
      margin: EdgeInsets.only(bottom: bottomMargin),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: BookshelfColors.shelfPlankGradient(brightness),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: brightness == Brightness.dark ? 0.45 : 0.22,
            ),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(
                alpha: brightness == Brightness.dark ? 0.08 : 0.25,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
