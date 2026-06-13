import 'package:bookshelf/core/providers/settings_providers.dart';
import 'package:bookshelf/data/models/library_sort_order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LibrarySortMenuButton extends ConsumerWidget {
  const LibrarySortMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortOrder = ref.watch(
      appSettingsProvider.select((settings) => settings.librarySortOrder),
    );

    return PopupMenuButton<LibrarySortOrder>(
      icon: const Icon(Icons.sort),
      tooltip: '並び順',
      onSelected: ref.read(appSettingsProvider.notifier).setLibrarySortOrder,
      itemBuilder: (context) {
        return LibrarySortOrder.values
            .map(
              (order) => PopupMenuItem(
                value: order,
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: order == sortOrder
                          ? Icon(
                              Icons.check,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                    ),
                    Expanded(child: Text(order.label)),
                  ],
                ),
              ),
            )
            .toList();
      },
    );
  }
}
