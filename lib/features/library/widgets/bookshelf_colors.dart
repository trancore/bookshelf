import 'package:flutter/material.dart';

abstract final class BookshelfColors {
  static const Color accent = Color(0xFFC9A66B);

  static Color libraryBackground(BuildContext context, bool isBookshelfView) {
    if (!isBookshelfView) {
      return Theme.of(context).scaffoldBackgroundColor;
    }
    return wallBackground(Theme.of(context).brightness);
  }

  static Color wallBackground(Brightness brightness) {
    return brightness == Brightness.dark
        ? const Color(0xFF2A231C)
        : const Color(0xFFF3E8D8);
  }

  static Color shelfBack(Brightness brightness) {
    return brightness == Brightness.dark
        ? const Color(0xFF3D3228)
        : const Color(0xFFE8D4BC);
  }

  static List<Color> shelfPlankGradient(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const [
        Color(0xFF6B5344),
        Color(0xFF4A382C),
        Color(0xFF3A2B22),
      ];
    }
    return const [
      Color(0xFFB8895E),
      Color(0xFF9A7048),
      Color(0xFF7D5A3A),
    ];
  }
}
