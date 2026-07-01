import 'package:bookshelf/core/providers/settings_providers.dart';
import 'package:bookshelf/data/models/app_settings.dart';
import 'package:bookshelf/data/models/library_sort_order.dart';
import 'package:bookshelf/data/models/reader_settings.dart';
import 'package:bookshelf/data/services/directory_picker_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: ListView(
        children: [
          _SectionHeader(title: '読み込み'),
          ListTile(
            title: const Text('デフォルトの PDF フォルダ'),
            subtitle: Text(
              settings.hasDefaultDirectory
                  ? settings.defaultDirectoryPath!
                  : '未設定（フォルダ追加時に毎回選択）',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDefaultDirectory(context, ref),
                    icon: const Icon(Icons.folder_open_outlined),
                    label: Text(settings.hasDefaultDirectory ? '変更' : 'フォルダを選択'),
                  ),
                ),
                if (settings.hasDefaultDirectory) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => notifier.setDefaultDirectory(null),
                    icon: const Icon(Icons.clear),
                    tooltip: 'クリア',
                  ),
                ],
              ],
            ),
          ),
          const ListTile(
            title: Text('サブフォルダ'),
            subtitle: Text('フォルダ読み込み時は常にサブフォルダ内の PDF も含めます'),
            leading: Icon(Icons.folder_copy_outlined),
          ),
          const Divider(height: 32),
          _SectionHeader(title: '表示'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'トップページのレイアウト',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<LibraryViewMode>(
              segments: const [
                ButtonSegment(
                  value: LibraryViewMode.bookshelf,
                  label: Text('本棚'),
                  icon: Icon(Icons.grid_view),
                ),
                ButtonSegment(
                  value: LibraryViewMode.list,
                  label: Text('リスト'),
                  icon: Icon(Icons.view_list),
                ),
              ],
              selected: {settings.libraryViewMode},
              onSelectionChanged: (selection) {
                notifier.setLibraryViewMode(selection.first);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              '並び順（フォルダ・PDF）',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          ...LibrarySortOrder.values.map(
            (order) => ListTile(
              title: Text(order.label),
              trailing: settings.librarySortOrder == order
                  ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () => notifier.setLibrarySortOrder(order),
            ),
          ),
          const Divider(height: 32),
          _SectionHeader(title: 'PDFリーダー'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'めくり方向',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<ReaderPageTurnDirection>(
              segments: ReaderPageTurnDirection.values
                  .map(
                    (direction) => ButtonSegment(
                      value: direction,
                      label: Text(direction.label),
                    ),
                  )
                  .toList(),
              selected: {settings.readerSettings.pageTurnDirection},
              onSelectionChanged: (selection) {
                notifier.setReaderSettings(
                  settings.readerSettings.copyWith(
                    pageTurnDirection: selection.first,
                  ),
                );
              },
            ),
          ),
          ListTile(
            title: Text(settings.readerSettings.pageTurnDirection.label),
            subtitle: Text(settings.readerSettings.pageTurnDirection.description),
            leading: const Icon(Icons.auto_stories_outlined),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Text(
              '背景色',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ReaderBackgroundStyle.values.map((style) {
                final selected = settings.readerSettings.backgroundStyle == style;
                return FilterChip(
                  label: Text(style.label),
                  selected: selected,
                  onSelected: (_) {
                    notifier.setReaderSettings(
                      settings.readerSettings.copyWith(backgroundStyle: style),
                    );
                  },
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Text(
              'ページ余白',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<ReaderPageMargin>(
              segments: ReaderPageMargin.values
                  .map(
                    (margin) => ButtonSegment(
                      value: margin,
                      label: Text(margin.label),
                    ),
                  )
                  .toList(),
              selected: {settings.readerSettings.pageMargin},
              onSelectionChanged: (selection) {
                notifier.setReaderSettings(
                  settings.readerSettings.copyWith(pageMargin: selection.first),
                );
              },
            ),
          ),
          SwitchListTile(
            title: const Text('続きから読む'),
            subtitle: const Text('前回開いていたページから表示'),
            value: settings.readerSettings.resumeFromLastPage,
            onChanged: (value) {
              notifier.setReaderSettings(
                settings.readerSettings.copyWith(resumeFromLastPage: value),
              );
            },
          ),
          SwitchListTile(
            title: const Text('ページナビゲーション'),
            subtitle: const Text('リーダー画面下部のページ番号と一覧'),
            value: settings.readerSettings.showPageNavigator,
            onChanged: (value) {
              notifier.setReaderSettings(
                settings.readerSettings.copyWith(showPageNavigator: value),
              );
            },
          ),
          const Divider(height: 32),
          _SectionHeader(title: 'テーマ'),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<AppThemePreference>(
              segments: AppThemePreference.values
                  .map(
                    (pref) => ButtonSegment(
                      value: pref,
                      label: Text(switch (pref) {
                        AppThemePreference.system => '自動',
                        AppThemePreference.light => 'ライト',
                        AppThemePreference.dark => 'ダーク',
                      }),
                    ),
                  )
                  .toList(),
              selected: {settings.themePreference},
              onSelectionChanged: (selection) {
                notifier.setThemePreference(selection.first);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              settings.themePreference.label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDefaultDirectory(BuildContext context, WidgetRef ref) async {
    final picked = await DirectoryPickerService.pickDirectory(
      dialogTitle: 'デフォルトの PDF フォルダ',
    );
    if (picked == null || !context.mounted) return;

    await ref.read(appSettingsProvider.notifier).setDefaultDirectory(
          picked.path,
          treeUri: picked.treeUri,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('デフォルトフォルダを保存しました')),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
