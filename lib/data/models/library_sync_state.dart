class LibrarySyncState {
  const LibrarySyncState({
    this.isSyncing = false,
    this.lastSyncedAt,
    this.lastImportedCount = 0,
    this.lastSkippedCount = 0,
    this.lastError,
  });

  final bool isSyncing;
  final DateTime? lastSyncedAt;
  final int lastImportedCount;
  final int lastSkippedCount;
  final String? lastError;

  LibrarySyncState copyWith({
    bool? isSyncing,
    DateTime? lastSyncedAt,
    int? lastImportedCount,
    int? lastSkippedCount,
    String? lastError,
    bool clearError = false,
  }) {
    return LibrarySyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastImportedCount: lastImportedCount ?? this.lastImportedCount,
      lastSkippedCount: lastSkippedCount ?? this.lastSkippedCount,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

class LibrarySyncResult {
  const LibrarySyncResult({
    required this.importedCount,
    required this.skippedCount,
    required this.failedCount,
    this.errorMessage,
  });

  final int importedCount;
  final int skippedCount;
  final int failedCount;
  final String? errorMessage;

  bool get isSuccess => errorMessage == null || importedCount > 0;
}
