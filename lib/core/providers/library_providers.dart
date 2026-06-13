import 'package:bookshelf/core/providers/app_providers.dart';
import 'package:bookshelf/data/models/book_with_tags.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final librarySearchQueryProvider = NotifierProvider<LibrarySearchQueryNotifier, String>(
  LibrarySearchQueryNotifier.new,
);

class LibrarySearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String value) => state = value;
}

final libraryTagFilterProvider = NotifierProvider<LibraryTagFilterNotifier, int?>(
  LibraryTagFilterNotifier.new,
);

class LibraryTagFilterNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void setTagId(int? tagId) => state = tagId;
}

final booksStreamProvider = StreamProvider<List<BookWithTags>>((ref) {
  final repo = ref.watch(libraryRepositoryProvider);
  final query = ref.watch(librarySearchQueryProvider);
  final tagId = ref.watch(libraryTagFilterProvider);
  return repo.watchBooks(query: query, tagId: tagId);
});

final tagsStreamProvider = StreamProvider((ref) {
  return ref.watch(libraryRepositoryProvider).watchTagsStream();
});

class LibrarySelectionState {
  const LibrarySelectionState({
    this.isActive = false,
    this.selectedIds = const {},
  });

  final bool isActive;
  final Set<String> selectedIds;

  LibrarySelectionState copyWith({
    bool? isActive,
    Set<String>? selectedIds,
  }) {
    return LibrarySelectionState(
      isActive: isActive ?? this.isActive,
      selectedIds: selectedIds ?? this.selectedIds,
    );
  }
}

final librarySelectionProvider =
    NotifierProvider<LibrarySelectionNotifier, LibrarySelectionState>(
  LibrarySelectionNotifier.new,
);

class LibrarySelectionNotifier extends Notifier<LibrarySelectionState> {
  @override
  LibrarySelectionState build() => const LibrarySelectionState();

  void enter() => state = const LibrarySelectionState(isActive: true);

  void exit() => state = const LibrarySelectionState();

  void toggle(String bookId) {
    if (!state.isActive) return;
    final next = Set<String>.from(state.selectedIds);
    if (next.contains(bookId)) {
      next.remove(bookId);
    } else {
      next.add(bookId);
    }
    state = state.copyWith(selectedIds: next);
  }

  void selectAll(Iterable<String> bookIds) {
    if (!state.isActive) return;
    state = state.copyWith(selectedIds: bookIds.toSet());
  }

  void clear() {
    if (!state.isActive) return;
    state = state.copyWith(selectedIds: {});
  }
}
