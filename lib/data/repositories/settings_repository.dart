import 'package:bookshelf/data/models/app_settings.dart';
import 'package:bookshelf/data/models/library_sort_order.dart';
import 'package:bookshelf/data/models/reader_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const _keyDefaultDirectory = 'default_directory_path';
  static const _keyDefaultDirectoryTreeUri = 'default_directory_tree_uri';
  static const _keyDefaultDirectoryRecursive = 'default_directory_recursive';
  static const _keyLibraryViewMode = 'library_view_mode';
  static const _keyLibrarySortOrder = 'library_sort_order';
  static const _keyReaderPageTurnDirection = 'reader_page_turn_direction';
  static const _keyReaderBackground = 'reader_background';
  static const _keyReaderShowPageNavigator = 'reader_show_page_navigator';
  static const _keyReaderResumeFromLastPage = 'reader_resume_from_last_page';
  static const _keyReaderPageMargin = 'reader_page_margin';
  static const _keyThemePreference = 'theme_preference';

  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  Future<AppSettings> load() async {
    final prefs = await _prefs();
    return AppSettings(
      defaultDirectoryPath: prefs.getString(_keyDefaultDirectory),
      defaultDirectoryTreeUri: prefs.getString(_keyDefaultDirectoryTreeUri),
      defaultDirectoryRecursive: prefs.getBool(_keyDefaultDirectoryRecursive) ?? true,
      libraryViewMode: LibraryViewMode.fromStorage(prefs.getString(_keyLibraryViewMode)),
      librarySortOrder: LibrarySortOrder.fromStorage(
        prefs.getString(_keyLibrarySortOrder),
      ),
      readerSettings: ReaderSettings(
        pageTurnDirection: ReaderPageTurnDirection.fromStorage(
          prefs.getString(_keyReaderPageTurnDirection),
        ),
        backgroundStyle: ReaderBackgroundStyle.fromStorage(
          prefs.getString(_keyReaderBackground),
        ),
        showPageNavigator:
            prefs.getBool(_keyReaderShowPageNavigator) ?? true,
        resumeFromLastPage:
            prefs.getBool(_keyReaderResumeFromLastPage) ?? true,
        pageMargin: ReaderPageMargin.fromStorage(
          prefs.getString(_keyReaderPageMargin),
        ),
      ),
      themePreference: AppThemePreference.fromStorage(prefs.getString(_keyThemePreference)),
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await _prefs();
    if (settings.hasDefaultDirectory) {
      await prefs.setString(_keyDefaultDirectory, settings.defaultDirectoryPath!);
      if (settings.defaultDirectoryTreeUri != null &&
          settings.defaultDirectoryTreeUri!.isNotEmpty) {
        await prefs.setString(
          _keyDefaultDirectoryTreeUri,
          settings.defaultDirectoryTreeUri!,
        );
      } else {
        await prefs.remove(_keyDefaultDirectoryTreeUri);
      }
    } else {
      await prefs.remove(_keyDefaultDirectory);
      await prefs.remove(_keyDefaultDirectoryTreeUri);
    }
    await prefs.setBool(_keyDefaultDirectoryRecursive, settings.defaultDirectoryRecursive);
    await prefs.setString(_keyLibraryViewMode, settings.libraryViewMode.storageKey);
    await prefs.setString(_keyLibrarySortOrder, settings.librarySortOrder.storageKey);
    final reader = settings.readerSettings;
    await prefs.setString(
      _keyReaderPageTurnDirection,
      reader.pageTurnDirection.storageKey,
    );
    await prefs.setString(_keyReaderBackground, reader.backgroundStyle.storageKey);
    await prefs.setBool(_keyReaderShowPageNavigator, reader.showPageNavigator);
    await prefs.setBool(_keyReaderResumeFromLastPage, reader.resumeFromLastPage);
    await prefs.setString(_keyReaderPageMargin, reader.pageMargin.storageKey);
    await prefs.setString(_keyThemePreference, settings.themePreference.storageKey);
  }
}
