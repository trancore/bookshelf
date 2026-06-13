import 'package:bookshelf/core/providers/settings_providers.dart';
import 'package:bookshelf/data/models/reader_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showReaderOptionsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => const SafeArea(
      child: _ReaderOptionsSheet(),
    ),
  );
}

class _ReaderOptionsSheet extends ConsumerWidget {
  const _ReaderOptionsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider).readerSettings;
    final notifier = ref.read(appSettingsProvider.notifier);
    final theme = Theme.of(context);

    Future<void> update(ReaderSettings next) async {
      await notifier.setReaderSettings(next);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'リーダーオプション',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '変更はすぐに反映されます。設定画面でも同じ項目を変更できます。',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text('めくり方向', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<ReaderPageTurnDirection>(
            segments: ReaderPageTurnDirection.values
                .map(
                  (direction) => ButtonSegment(
                    value: direction,
                    label: Text(direction.label),
                  ),
                )
                .toList(),
            selected: {settings.pageTurnDirection},
            onSelectionChanged: (selection) {
              update(settings.copyWith(pageTurnDirection: selection.first));
            },
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              settings.pageTurnDirection.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('背景色', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ReaderBackgroundStyle.values.map((style) {
              final selected = settings.backgroundStyle == style;
              return FilterChip(
                label: Text(style.label),
                selected: selected,
                avatar: CircleAvatar(
                  backgroundColor: style.color,
                  radius: 10,
                ),
                onSelected: (_) {
                  update(settings.copyWith(backgroundStyle: style));
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text('ページ余白', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<ReaderPageMargin>(
            segments: ReaderPageMargin.values
                .map(
                  (margin) => ButtonSegment(
                    value: margin,
                    label: Text(margin.label),
                  ),
                )
                .toList(),
            selected: {settings.pageMargin},
            onSelectionChanged: (selection) {
              update(settings.copyWith(pageMargin: selection.first));
            },
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('続きから読む'),
            subtitle: const Text('前回開いていたページから表示'),
            value: settings.resumeFromLastPage,
            onChanged: (value) {
              update(settings.copyWith(resumeFromLastPage: value));
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('ページナビゲーション'),
            subtitle: const Text('画面下部のページ番号と一覧'),
            value: settings.showPageNavigator,
            onChanged: (value) {
              update(settings.copyWith(showPageNavigator: value));
            },
          ),
        ],
      ),
    );
  }
}
