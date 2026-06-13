import 'dart:async';
import 'dart:io';

import 'package:bookshelf/core/providers/app_providers.dart';
import 'package:bookshelf/core/providers/settings_providers.dart';
import 'package:bookshelf/data/db/database.dart';
import 'package:bookshelf/data/repositories/library_repository.dart';
import 'package:bookshelf/features/reader/page_turn_pdf_reader.dart';
import 'package:bookshelf/features/reader/reader_options_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({
    required this.bookId,
    this.startFromBeginning = false,
    super.key,
  });

  final String bookId;
  final bool startFromBeginning;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  final _pageTurnReaderKey = GlobalKey<PageTurnPdfReaderState>();
  late final LibraryRepository _library;
  Book? _book;
  bool _loading = true;
  String? _error;
  int _currentPage = 1;
  int _initialPage = 1;
  int _pageCount = 0;
  final _currentPageNotifier = ValueNotifier<int>(1);
  Timer? _saveDebounce;
  bool _chromeVisible = true;
  bool _suppressProgressSave = true;

  @override
  void initState() {
    super.initState();
    _library = ref.read(libraryRepositoryProvider);
    _loadBook();
  }

  Future<void> _loadBook() async {
    final book = await _library.getBook(widget.bookId);
    if (!mounted) return;
    if (book == null) {
      setState(() {
        _loading = false;
        _error = '本が見つかりません';
      });
      return;
    }
    if (!File(book.localPath).existsSync()) {
      setState(() {
        _loading = false;
        _error = 'PDFファイルが見つかりません';
      });
      return;
    }

    final readerSettings = ref.read(appSettingsProvider).readerSettings;
    final resume = readerSettings.resumeFromLastPage && !widget.startFromBeginning;
    final initialPage = _resolveInitialPage(book, resume);

    _currentPageNotifier.value = initialPage;
    setState(() {
      _book = book;
      _currentPage = initialPage;
      _initialPage = initialPage;
      _pageCount = book.pageCount;
      _loading = false;
      _suppressProgressSave = true;
    });
  }

  int _resolveInitialPage(Book book, bool resume) {
    if (!resume) return 1;
    final saved = book.lastReadPage;
    if (saved <= 1) return 1;
    if (book.pageCount > 0) return saved.clamp(1, book.pageCount);
    return saved;
  }

  void _onDocumentReady(int pageCount) {
    if (pageCount <= 0 || _book == null) return;

    final book = _book!;
    final readerSettings = ref.read(appSettingsProvider).readerSettings;

    if (book.pageCount != pageCount) {
      unawaited(_library.updatePageCount(widget.bookId, pageCount));
    }

    if (pageCount != _pageCount) {
      setState(() => _pageCount = pageCount);
    }

    final resume =
        readerSettings.resumeFromLastPage && !widget.startFromBeginning;
    if (!resume) {
      _enableProgressSave();
      return;
    }

    final targetPage = book.lastReadPage.clamp(1, pageCount);
    if (targetPage != _currentPage) {
      _goToPage(targetPage);
      _currentPage = targetPage;
      _currentPageNotifier.value = targetPage;
    }
    _enableProgressSave();
  }

  void _enableProgressSave() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _suppressProgressSave = false;
    });
  }

  void _onPageChanged(int pageNumber) {
    if (_book == null) return;
    _currentPage = pageNumber;
    _currentPageNotifier.value = pageNumber;
    if (!_suppressProgressSave) {
      _scheduleSave(pageNumber);
    }
  }

  void _scheduleSave(int pageNumber) {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 500), () {
      _library.updateReadingProgress(widget.bookId, pageNumber);
    });
  }

  void _goToPage(int pageNumber) {
    final count = _pageCount > 0 ? _pageCount : (_book?.pageCount ?? 0);
    if (count > 0) {
      final clamped = pageNumber.clamp(1, count);
      _currentPage = clamped;
      _currentPageNotifier.value = clamped;
    }
    _pageTurnReaderKey.currentState?.goToPageClamped(pageNumber, count);
  }

  void _toggleChrome() {
    setState(() => _chromeVisible = !_chromeVisible);
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _currentPageNotifier.dispose();
    if (_book != null && _currentPage > 0) {
      _library.updateReadingProgress(widget.bookId, _currentPage);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.pop(),
                  child: const Text('戻る'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final book = _book!;
    final pageCount = _pageCount > 0 ? _pageCount : book.pageCount;
    final readerSettings = ref.watch(appSettingsProvider).readerSettings;

    return Scaffold(
      appBar: _chromeVisible
          ? AppBar(
              title: Text(book.displayTitle, overflow: TextOverflow.ellipsis),
              actions: [
                IconButton(
                  onPressed: () => showReaderOptionsSheet(context),
                  icon: const Icon(Icons.tune),
                  tooltip: 'リーダーオプション',
                ),
              ],
            )
          : null,
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _toggleChrome,
              behavior: HitTestBehavior.translucent,
              child: PageTurnPdfReader(
                key: _pageTurnReaderKey,
                filePath: book.localPath,
                initialPage: _initialPage,
                settings: readerSettings,
                immersive: !_chromeVisible,
                onPageChanged: _onPageChanged,
                onDocumentReady: _onDocumentReady,
              ),
            ),
          ),
          if (readerSettings.showPageNavigator)
            ClipRect(
              child: AnimatedAlign(
                alignment: Alignment.topCenter,
                heightFactor: _chromeVisible ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: ValueListenableBuilder<int>(
                  valueListenable: _currentPageNotifier,
                  builder: (context, currentPage, _) {
                    return _ReaderControls(
                      currentPage: currentPage,
                      pageCount: pageCount,
                      onPrevious: currentPage > 1
                          ? () => _goToPage(currentPage - 1)
                          : null,
                      onNext: pageCount > 0 && currentPage < pageCount
                          ? () => _goToPage(currentPage + 1)
                          : null,
                      onPageSelected: _goToPage,
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReaderControls extends StatefulWidget {
  const _ReaderControls({
    required this.currentPage,
    required this.pageCount,
    required this.onPrevious,
    required this.onNext,
    required this.onPageSelected,
  });

  final int currentPage;
  final int pageCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final ValueChanged<int> onPageSelected;

  @override
  State<_ReaderControls> createState() => _ReaderControlsState();
}

class _ReaderControlsState extends State<_ReaderControls> {
  static const _pageChipExtent = 54.0;

  late final ScrollController _pageListController;

  @override
  void initState() {
    super.initState();
    _pageListController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentPage());
  }

  @override
  void didUpdateWidget(_ReaderControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPage != widget.currentPage ||
        oldWidget.pageCount != widget.pageCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentPage());
    }
  }

  @override
  void dispose() {
    _pageListController.dispose();
    super.dispose();
  }

  void _scrollToCurrentPage() {
    if (!_pageListController.hasClients || widget.pageCount <= 1) return;

    final index = (widget.currentPage - 1).clamp(0, widget.pageCount - 1);
    final viewport = _pageListController.position.viewportDimension;
    final target = (index * _pageChipExtent) - (viewport / 2) + (_pageChipExtent / 2);
    final maxExtent = _pageListController.position.maxScrollExtent;

    _pageListController.animateTo(
      target.clamp(0.0, maxExtent),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onPrevious,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          child: _PageNumberDisplay(
                            currentPage: widget.currentPage,
                            pageCount: widget.pageCount,
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onNext,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
            if (widget.pageCount > 1)
              SizedBox(
                height: 56,
                child: ListView.builder(
                  controller: _pageListController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  itemExtent: _pageChipExtent,
                  itemCount: widget.pageCount,
                  itemBuilder: (context, index) {
                    final page = index + 1;
                    final selected = page == widget.currentPage;
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: ChoiceChip(
                        label: Text(
                          '$page',
                          style: TextStyle(
                            fontWeight:
                                selected ? FontWeight.bold : FontWeight.w500,
                            fontSize: selected ? 15 : 13,
                          ),
                        ),
                        selected: selected,
                        showCheckmark: false,
                        selectedColor: theme.colorScheme.primaryContainer,
                        labelStyle: TextStyle(
                          color: selected
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        side: selected
                            ? BorderSide(color: theme.colorScheme.primary)
                            : null,
                        onSelected: (_) => widget.onPageSelected(page),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PageNumberDisplay extends StatelessWidget {
  const _PageNumberDisplay({
    required this.currentPage,
    required this.pageCount,
  });

  final int currentPage;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numberStyle = theme.textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.bold,
      height: 1,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final mutedStyle = theme.textTheme.titleMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
      height: 1,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    if (pageCount <= 0) {
      return Text(
        '$currentPage',
        style: numberStyle?.copyWith(color: theme.colorScheme.primary),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '$currentPage',
          style: numberStyle?.copyWith(color: theme.colorScheme.primary),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text('/', style: mutedStyle),
        ),
        Text('$pageCount', style: mutedStyle),
      ],
    );
  }
}
