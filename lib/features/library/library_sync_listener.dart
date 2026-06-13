import 'package:bookshelf/core/providers/library_sync_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Triggers a background library sync when the app starts.
class LibrarySyncListener extends ConsumerStatefulWidget {
  const LibrarySyncListener({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<LibrarySyncListener> createState() => _LibrarySyncListenerState();
}

class _LibrarySyncListenerState extends ConsumerState<LibrarySyncListener>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(librarySyncProvider.notifier).syncOnLaunch();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(librarySyncProvider.notifier).syncOnLaunch();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
