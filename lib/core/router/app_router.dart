import 'package:bookshelf/data/models/book_directory_group.dart';
import 'package:bookshelf/features/library/directory_detail_screen.dart';
import 'package:bookshelf/features/library/library_screen.dart';
import 'package:bookshelf/features/reader/reader_screen.dart';
import 'package:bookshelf/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'library',
      builder: (context, state) => const LibraryScreen(),
    ),
    GoRoute(
      path: '/folder',
      name: 'folder',
      builder: (context, state) {
        final path = decodeDirectoryPathParam(state.uri.queryParameters['path']);
        return DirectoryDetailScreen(directoryPath: path);
      },
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/reader/:bookId',
      name: 'reader',
      builder: (context, state) {
        final bookId = state.pathParameters['bookId']!;
        final startFromBeginning =
            state.uri.queryParameters['fromStart'] == 'true';
        return ReaderScreen(
          bookId: bookId,
          startFromBeginning: startFromBeginning,
        );
      },
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('エラー')),
    body: Center(child: Text(state.error.toString())),
  ),
);
