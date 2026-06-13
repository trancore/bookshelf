import 'dart:io';

import 'package:bookshelf/data/services/thumbnail_service.dart';
import 'package:flutter/material.dart';

/// PDF 1ページ目のサムネイル。なければ [pdfPath] から生成する。
class BookCoverImage extends StatefulWidget {
  const BookCoverImage({
    required this.bookId,
    this.pdfPath,
    this.fit = BoxFit.cover,
    super.key,
  });

  final String bookId;
  final String? pdfPath;
  final BoxFit fit;

  @override
  State<BookCoverImage> createState() => _BookCoverImageState();
}

class _BookCoverImageState extends State<BookCoverImage> {
  File? _thumbFile;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadThumb();
  }

  @override
  void didUpdateWidget(covariant BookCoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookId != widget.bookId || oldWidget.pdfPath != widget.pdfPath) {
      _thumbFile = null;
      _loadThumb();
    }
  }

  Future<void> _loadThumb() async {
    if (_loading) return;
    _loading = true;
    final service = ThumbnailService();

    try {
      var file = await service.thumbnailFile(widget.bookId);
      if (file.existsSync()) {
        if (mounted) setState(() => _thumbFile = file);
        return;
      }

      final pdfPath = widget.pdfPath;
      if (pdfPath != null && File(pdfPath).existsSync()) {
        file = await service.generateThumbnail(
              bookId: widget.bookId,
              pdfPath: pdfPath,
            ) ??
            file;
        if (file.existsSync() && mounted) {
          setState(() => _thumbFile = file);
        }
      }
    } finally {
      _loading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_thumbFile != null) {
      return Image.file(_thumbFile!, fit: widget.fit);
    }
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: _loading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            : Icon(
                Icons.picture_as_pdf,
                size: 28,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
      ),
    );
  }
}
