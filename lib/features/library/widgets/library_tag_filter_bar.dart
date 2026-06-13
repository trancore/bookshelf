import 'package:bookshelf/core/providers/library_providers.dart';
import 'package:bookshelf/data/db/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LibraryTagFilterBar extends ConsumerWidget {
  const LibraryTagFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(tagsStreamProvider);

    return tagsAsync.when(
      data: (tags) => _TagChips(tags: tags),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _TagChips extends ConsumerWidget {
  const _TagChips({required this.tags});

  final List<Tag> tags;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tags.isEmpty) return const SizedBox.shrink();

    final selectedTagId = ref.watch(libraryTagFilterProvider);

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('すべて'),
              selected: selectedTagId == null,
              onSelected: (_) {
                ref.read(libraryTagFilterProvider.notifier).setTagId(null);
              },
            ),
          ),
          for (final tag in tags)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(tag.name),
                selected: selectedTagId == tag.id,
                onSelected: (_) {
                  ref.read(libraryTagFilterProvider.notifier).setTagId(
                        selectedTagId == tag.id ? null : tag.id,
                      );
                },
              ),
            ),
        ],
      ),
    );
  }
}
