import 'package:bookshelf/core/providers/settings_providers.dart';
import 'package:bookshelf/core/router/app_router.dart';
import 'package:bookshelf/core/theme/app_theme.dart';
import 'package:bookshelf/features/import/share_import_listener.dart';
import 'package:bookshelf/features/library/library_sync_listener.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BookshelfApp extends ConsumerWidget {
  const BookshelfApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);

    return LibrarySyncListener(
      child: ShareImportListener(
        child: MaterialApp.router(
        title: 'Bookshelf',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: settings.themePreference.toThemeMode(),
        routerConfig: appRouter,
        ),
      ),
    );
  }
}
