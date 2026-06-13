import 'package:flutter/material.dart';

enum ReaderBackgroundStyle {
  white,
  grey,
  dark,
  sepia;

  String get storageKey => name;

  static ReaderBackgroundStyle fromStorage(String? value) {
    return ReaderBackgroundStyle.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReaderBackgroundStyle.grey,
    );
  }

  String get label => switch (this) {
        ReaderBackgroundStyle.white => '白',
        ReaderBackgroundStyle.grey => 'グレー',
        ReaderBackgroundStyle.dark => 'ダーク',
        ReaderBackgroundStyle.sepia => 'セピア',
      };

  Color get color => switch (this) {
        ReaderBackgroundStyle.white => Colors.white,
        ReaderBackgroundStyle.grey => const Color(0xFFBDBDBD),
        ReaderBackgroundStyle.dark => const Color(0xFF1E1E1E),
        ReaderBackgroundStyle.sepia => const Color(0xFFF4ECD8),
      };
}

/// Which direction swiping advances to the next page.
enum ReaderPageTurnDirection {
  /// Western style: swipe left for next page.
  leftToRight,
  /// Manga style (右開き): swipe right for next page.
  rightToLeft;

  String get storageKey => name;

  static ReaderPageTurnDirection fromStorage(String? value) {
    return ReaderPageTurnDirection.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReaderPageTurnDirection.leftToRight,
    );
  }

  String get label => switch (this) {
        ReaderPageTurnDirection.leftToRight => '左開き',
        ReaderPageTurnDirection.rightToLeft => '右開き',
      };

  String get description => switch (this) {
        ReaderPageTurnDirection.leftToRight => '左へスワイプで次のページ',
        ReaderPageTurnDirection.rightToLeft => '右へスワイプで次のページ',
      };

  bool get pageViewReverse => this == ReaderPageTurnDirection.rightToLeft;
}

enum ReaderPageMargin {
  small,
  medium,
  large;

  String get storageKey => name;

  static ReaderPageMargin fromStorage(String? value) {
    return ReaderPageMargin.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReaderPageMargin.medium,
    );
  }

  String get label => switch (this) {
        ReaderPageMargin.small => '狭い',
        ReaderPageMargin.medium => '標準',
        ReaderPageMargin.large => '広い',
      };

  double get pixels => switch (this) {
        ReaderPageMargin.small => 4,
        ReaderPageMargin.medium => 8,
        ReaderPageMargin.large => 16,
      };
}

class ReaderSettings {
  const ReaderSettings({
    this.pageTurnDirection = ReaderPageTurnDirection.leftToRight,
    this.backgroundStyle = ReaderBackgroundStyle.grey,
    this.showPageNavigator = true,
    this.resumeFromLastPage = true,
    this.pageMargin = ReaderPageMargin.medium,
  });

  final ReaderPageTurnDirection pageTurnDirection;
  final ReaderBackgroundStyle backgroundStyle;
  final bool showPageNavigator;
  final bool resumeFromLastPage;
  final ReaderPageMargin pageMargin;

  factory ReaderSettings.defaults() => const ReaderSettings();

  ReaderSettings copyWith({
    ReaderPageTurnDirection? pageTurnDirection,
    ReaderBackgroundStyle? backgroundStyle,
    bool? showPageNavigator,
    bool? resumeFromLastPage,
    ReaderPageMargin? pageMargin,
  }) {
    return ReaderSettings(
      pageTurnDirection: pageTurnDirection ?? this.pageTurnDirection,
      backgroundStyle: backgroundStyle ?? this.backgroundStyle,
      showPageNavigator: showPageNavigator ?? this.showPageNavigator,
      resumeFromLastPage: resumeFromLastPage ?? this.resumeFromLastPage,
      pageMargin: pageMargin ?? this.pageMargin,
    );
  }

  Color get backgroundColor => backgroundStyle.color;

  double get pageMarginPixels => pageMargin.pixels;
}
