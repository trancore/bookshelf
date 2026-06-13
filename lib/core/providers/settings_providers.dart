import 'package:bookshelf/core/providers/library_sync_providers.dart';
import 'package:bookshelf/data/models/app_settings.dart';
import 'package:bookshelf/data/models/library_sort_order.dart';
import 'package:bookshelf/data/models/reader_settings.dart';
import 'package:bookshelf/data/repositories/settings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);

class AppSettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    _loadFromStorage();
    return AppSettings.defaults();
  }

  Future<void> _loadFromStorage() async {
    final loaded = await ref.read(settingsRepositoryProvider).load();
    state = loaded;
  }

  Future<void> _persist() async {
    await ref.read(settingsRepositoryProvider).save(state);
  }

  Future<void> setDefaultDirectory(String? path) async {
    final previousPath = state.defaultDirectoryPath;
    state = state.copyWith(
      defaultDirectoryPath: path,
      clearDefaultDirectory: path == null || path.isEmpty,
    );
    await _persist();

    if (previousPath != path) {
      await ref.read(librarySyncCacheRepositoryProvider).clear();
      if (path != null && path.isNotEmpty) {
        // ignore: unawaited_futures
        ref.read(librarySyncProvider.notifier).syncFromDefaultDirectory(
              directoryPath: path,
              recursive: state.defaultDirectoryRecursive,
            );
      }
    }
  }

  Future<void> setDefaultDirectoryRecursive(bool value) async {
    state = state.copyWith(defaultDirectoryRecursive: value);
    await _persist();
  }

  Future<void> setLibraryViewMode(LibraryViewMode mode) async {
    state = state.copyWith(libraryViewMode: mode);
    await _persist();
  }

  Future<void> setLibrarySortOrder(LibrarySortOrder order) async {
    state = state.copyWith(librarySortOrder: order);
    await _persist();
  }

  Future<void> setReaderSettings(ReaderSettings settings) async {
    state = state.copyWith(readerSettings: settings);
    await _persist();
  }

  Future<void> setThemePreference(AppThemePreference preference) async {
    state = state.copyWith(themePreference: preference);
    await _persist();
  }
}
