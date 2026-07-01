import 'package:bookshelf/data/models/library_sort_order.dart';
import 'package:bookshelf/data/models/reader_settings.dart';
import 'package:flutter/material.dart';

enum LibraryViewMode {
  bookshelf,
  list;

  String get storageKey => name;

  static LibraryViewMode fromStorage(String? value) {
    return LibraryViewMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => LibraryViewMode.bookshelf,
    );
  }
}

enum AppThemePreference {
  system,
  light,
  dark;

  String get storageKey => name;

  static AppThemePreference fromStorage(String? value) {
    return AppThemePreference.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AppThemePreference.system,
    );
  }

  ThemeMode toThemeMode() => switch (this) {
        AppThemePreference.system => ThemeMode.system,
        AppThemePreference.light => ThemeMode.light,
        AppThemePreference.dark => ThemeMode.dark,
      };

  String get label => switch (this) {
        AppThemePreference.system => 'システム設定に従う',
        AppThemePreference.light => 'ライト',
        AppThemePreference.dark => 'ダーク',
      };
}

class AppSettings {
  const AppSettings({
    this.defaultDirectoryPath,
    this.defaultDirectoryTreeUri,
    this.defaultDirectoryRecursive = true,
    this.libraryViewMode = LibraryViewMode.bookshelf,
    this.librarySortOrder = LibrarySortOrder.recentlyOpened,
    this.readerSettings = const ReaderSettings(),
    this.themePreference = AppThemePreference.system,
  });

  final String? defaultDirectoryPath;
  final String? defaultDirectoryTreeUri;
  final bool defaultDirectoryRecursive;
  final LibraryViewMode libraryViewMode;
  final LibrarySortOrder librarySortOrder;
  final ReaderSettings readerSettings;
  final AppThemePreference themePreference;

  bool get hasDefaultDirectory =>
      defaultDirectoryPath != null && defaultDirectoryPath!.isNotEmpty;

  factory AppSettings.defaults() => const AppSettings();

  AppSettings copyWith({
    String? defaultDirectoryPath,
    String? defaultDirectoryTreeUri,
    bool clearDefaultDirectory = false,
    bool? defaultDirectoryRecursive,
    LibraryViewMode? libraryViewMode,
    LibrarySortOrder? librarySortOrder,
    ReaderSettings? readerSettings,
    AppThemePreference? themePreference,
  }) {
    return AppSettings(
      defaultDirectoryPath: clearDefaultDirectory
          ? null
          : (defaultDirectoryPath ?? this.defaultDirectoryPath),
      defaultDirectoryTreeUri: clearDefaultDirectory
          ? null
          : (defaultDirectoryTreeUri ?? this.defaultDirectoryTreeUri),
      defaultDirectoryRecursive:
          defaultDirectoryRecursive ?? this.defaultDirectoryRecursive,
      libraryViewMode: libraryViewMode ?? this.libraryViewMode,
      librarySortOrder: librarySortOrder ?? this.librarySortOrder,
      readerSettings: readerSettings ?? this.readerSettings,
      themePreference: themePreference ?? this.themePreference,
    );
  }
}
