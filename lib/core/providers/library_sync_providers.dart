import 'dart:async';

import 'package:bookshelf/core/providers/app_providers.dart';
import 'package:bookshelf/core/providers/settings_providers.dart';
import 'package:bookshelf/data/models/library_sync_state.dart';
import 'package:bookshelf/data/repositories/library_sync_cache_repository.dart';
import 'package:bookshelf/data/services/library_sync_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final librarySyncCacheRepositoryProvider = Provider<LibrarySyncCacheRepository>((ref) {
  return LibrarySyncCacheRepository();
});

final librarySyncServiceProvider = Provider<LibrarySyncService>((ref) {
  return LibrarySyncService(
    importService: ref.watch(importServiceProvider),
    cacheRepository: ref.watch(librarySyncCacheRepositoryProvider),
  );
});

final librarySyncProvider =
    NotifierProvider<LibrarySyncNotifier, LibrarySyncState>(LibrarySyncNotifier.new);

class LibrarySyncNotifier extends Notifier<LibrarySyncState> {
  static const _minSyncInterval = Duration(seconds: 30);

  Future<void>? _activeSync;
  DateTime? _lastSyncStartedAt;

  @override
  LibrarySyncState build() => const LibrarySyncState();

  Future<void> syncOnLaunch() async {
    final settings = await ref.read(settingsRepositoryProvider).load();
    if (!settings.hasDefaultDirectory) return;

    await syncFromDefaultDirectory(
      directoryPath: settings.defaultDirectoryPath!,
      recursive: settings.defaultDirectoryRecursive,
    );
  }

  Future<void> syncFromDefaultDirectory({
    required String directoryPath,
    bool recursive = true,
  }) async {
    if (_activeSync != null) {
      return _activeSync;
    }

    final now = DateTime.now();
    if (_lastSyncStartedAt != null &&
        now.difference(_lastSyncStartedAt!) < _minSyncInterval) {
      return;
    }

    _lastSyncStartedAt = now;
    _activeSync = _runSync(directoryPath: directoryPath, recursive: recursive);
    try {
      await _activeSync;
    } finally {
      _activeSync = null;
    }
  }

  Future<void> _runSync({
    required String directoryPath,
    required bool recursive,
  }) async {
    state = state.copyWith(isSyncing: true, clearError: true);

    try {
      final result = await ref.read(librarySyncServiceProvider).syncFromDirectory(
            directoryPath,
            recursive: recursive,
          );

      state = state.copyWith(
        isSyncing: false,
        lastSyncedAt: DateTime.now(),
        lastImportedCount: result.importedCount,
        lastSkippedCount: result.skippedCount,
        lastError: result.errorMessage,
      );
    } catch (error) {
      state = state.copyWith(
        isSyncing: false,
        lastError: error.toString(),
      );
    }
  }
}
