import 'package:bookshelf/data/services/saf_storage_helper.dart';
import 'package:flutter/services.dart';

/// Result of picking a directory through Android SAF.
class PickedSafDirectory {
  const PickedSafDirectory({
    required this.path,
    required this.treeUri,
  });

  /// SAF-relative path, e.g. `Book/Favorite`.
  final String path;

  /// Persisted tree URI granted by the system picker.
  final String treeUri;
}

/// Android SAF helpers that always use persisted tree URIs.
abstract final class SafDirectoryAccess {
  static const _bookshelfChannel =
      MethodChannel('com.bookshelf.bookshelf/saf_io');
  static const _documentFileChannel =
      MethodChannel('com.ivehement.plugins/saf/documentfile');
  static const _documentsContractChannel =
      MethodChannel('com.ivehement.plugins/saf/documentscontract');

  static Future<PickedSafDirectory?> pickDirectory() async {
    final treeUri = await _bookshelfChannel.invokeMethod<String?>('pickDirectoryTree');
    if (treeUri == null || treeUri.isEmpty) return null;

    return PickedSafDirectory(
      path: _makeDirectoryPath(treeUri),
      treeUri: treeUri,
    );
  }

  static Future<String?> resolveTreeUri({
    required String directoryPath,
    String? storedTreeUri,
  }) async {
    if (storedTreeUri != null && storedTreeUri.isNotEmpty) {
      if (await _hasReadablePersistedPermission(storedTreeUri)) {
        return storedTreeUri;
      }
    }
    return _findPersistedTreeUriForPath(directoryPath);
  }

  static Future<List<String>?> listFilePaths({
    required String directoryPath,
    String? treeUri,
    String fileType = 'any',
  }) async {
    final resolvedUri = treeUri ??
        await resolveTreeUri(
          directoryPath: directoryPath,
          storedTreeUri: null,
        );
    if (resolvedUri == null) return null;

    try {
      final paths = await _documentsContractChannel.invokeMethod<List<dynamic>?>(
        'buildChildDocumentsPathUsingTree',
        <String, dynamic>{
          'fileType': fileType,
          'sourceTreeUriString': resolvedUri,
        },
      );
      if (paths == null) return null;
      return paths.cast<String>();
    } on PlatformException {
      return null;
    }
  }

  static Future<bool> _hasReadablePersistedPermission(String treeUri) async {
    final permissions = await _persistedUriPermissions();
    if (permissions == null) return false;

    for (final permission in permissions) {
      final uri = permission['uri'] as String?;
      final canRead = permission['isReadPermission'] as bool? ?? false;
      if (uri == treeUri && canRead) return true;
    }
    return false;
  }

  static Future<String?> _findPersistedTreeUriForPath(String directoryPath) async {
    final target = SafStorageHelper.toSafStoragePath(directoryPath);
    final permissions = await _persistedUriPermissions();
    if (permissions == null) return null;

    for (final permission in permissions) {
      final canRead = permission['isReadPermission'] as bool? ?? false;
      if (!canRead) continue;

      final uri = permission['uri'] as String?;
      if (uri == null || uri.isEmpty) continue;
      final path = SafStorageHelper.toSafStoragePath(_makeDirectoryPath(uri));
      if (path == target) return uri;
    }
    return null;
  }

  static Future<List<Map<dynamic, dynamic>>?> _persistedUriPermissions() async {
    try {
      final permissions = await _documentFileChannel.invokeListMethod<dynamic>(
        'persistedUriPermissions',
      );
      if (permissions == null) return null;
      return permissions.map((item) => Map<dynamic, dynamic>.from(item as Map)).toList();
    } on PlatformException {
      return null;
    }
  }

  static String _makeDirectoryPath(String uriString) {
    final directoryPathUriString = uriString.split('primary%3A')[1];
    return directoryPathUriString.replaceAll('%2F', '/').replaceAll('%20', ' ');
  }
}
