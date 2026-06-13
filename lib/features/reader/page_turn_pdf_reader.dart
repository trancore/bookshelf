import 'package:bookshelf/data/models/reader_settings.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

/// One page per screen; swipe horizontally to turn pages.
class PageTurnPdfReader extends StatefulWidget {
  const PageTurnPdfReader({
    required this.filePath,
    required this.initialPage,
    required this.settings,
    required this.onPageChanged,
    this.onDocumentReady,
    this.immersive = false,
    super.key,
  });

  final String filePath;
  final int initialPage;
  final ReaderSettings settings;
  final ValueChanged<int> onPageChanged;
  final void Function(int pageCount)? onDocumentReady;

  /// When true, content extends under the status bar (chrome hidden).
  final bool immersive;

  @override
  State<PageTurnPdfReader> createState() => PageTurnPdfReaderState();
}

class PageTurnPdfReaderState extends State<PageTurnPdfReader> {
  late final PdfDocumentRef _documentRef;
  late final PageController _pageController;
  bool _documentReadyNotified = false;
  bool _initialPageSynced = false;

  @override
  void initState() {
    super.initState();
    _documentRef = PdfDocumentRefFile(widget.filePath);
    final initialIndex = (widget.initialPage - 1).clamp(0, 1 << 30);
    _pageController = PageController(initialPage: initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _syncInitialPage(int pageCount) {
    if (_initialPageSynced || pageCount <= 0 || !_pageController.hasClients) {
      return;
    }
    _initialPageSynced = true;
    final index = (widget.initialPage - 1).clamp(0, pageCount - 1);
    final current = _pageController.page?.round() ?? _pageController.initialPage;
    if (current != index) {
      _pageController.jumpToPage(index);
    }
  }

  void goToPageClamped(int pageNumber, int pageCount) {
    if (!_pageController.hasClients || pageCount <= 0) return;
    final index = (pageNumber - 1).clamp(0, pageCount - 1);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PdfDocumentViewBuilder(
      documentRef: _documentRef,
      builder: (context, document) {
        if (document == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final pageCount = document.pages.length;
        if (!_documentReadyNotified) {
          _documentReadyNotified = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _syncInitialPage(pageCount);
            widget.onDocumentReady?.call(pageCount);
          });
        }
        final margin = widget.settings.pageMarginPixels;
        final background = widget.settings.backgroundColor;

        return PageView.builder(
          controller: _pageController,
          reverse: widget.settings.pageTurnDirection.pageViewReverse,
          itemCount: pageCount,
          allowImplicitScrolling: true,
          onPageChanged: (index) => widget.onPageChanged(index + 1),
          itemBuilder: (context, index) {
            return ColoredBox(
              color: background,
              child: SafeArea(
                top: !widget.immersive,
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.all(margin),
                  child: PdfPageView(
                    document: document,
                    pageNumber: index + 1,
                    maximumDpi: 180,
                    backgroundColor: background,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
