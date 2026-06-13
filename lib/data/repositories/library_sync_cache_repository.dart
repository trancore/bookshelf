import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LibrarySyncCache {
  const LibrarySyncCache({
    required this.directoryPath,
    required this.syncedAt,
    required this.filePaths,
  });

  final String directoryPath;
  final DateTime syncedAt;
  final Set<String> filePaths;

  bool matchesDirectory(String path) => directoryPath == path;

  bool hasSameFiles(Set<String> paths) {
    if (filePaths.length != paths.length) return false;
    return filePaths.containsAll(paths);
  }
}

class LibrarySyncCacheRepository {
  static const _keyDirectory = 'library_sync_directory';
  static const _keySyncedAt = 'library_sync_synced_at';
  static const _keyFilePaths = 'library_sync_file_paths';

  Future<LibrarySyncCache?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final directory = prefs.getString(_keyDirectory);
    final syncedAtRaw = prefs.getString(_keySyncedAt);
    final pathsRaw = prefs.getString(_keyFilePaths);
    if (directory == null || syncedAtRaw == null || pathsRaw == null) {
      return null;
    }

    final decoded = jsonDecode(pathsRaw);
    if (decoded is! List) return null;

    return LibrarySyncCache(
      directoryPath: directory,
      syncedAt: DateTime.parse(syncedAtRaw),
      filePaths: decoded.cast<String>().toSet(),
    );
  }

  Future<void> save({
    required String directoryPath,
    required Set<String> filePaths,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDirectory, directoryPath);
    await prefs.setString(_keySyncedAt, DateTime.now().toIso8601String());
    await prefs.setString(_keyFilePaths, jsonEncode(filePaths.toList()..sort()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDirectory);
    await prefs.remove(_keySyncedAt);
    await prefs.remove(_keyFilePaths);
  }

  Future<void> removeFilePath(String filePath) async {
    final cache = await load();
    if (cache == null || !cache.filePaths.contains(filePath)) return;

    final nextPaths = Set<String>.from(cache.filePaths)..remove(filePath);
    await save(directoryPath: cache.directoryPath, filePaths: nextPaths);
  }
}
