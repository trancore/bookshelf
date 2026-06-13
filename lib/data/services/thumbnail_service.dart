import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';

class ThumbnailService {
  Future<Directory> thumbnailsDir() async {
    final base = await getApplicationCacheDirectory();
    final dir = Directory(p.join(base.path, 'thumbnails'));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String thumbnailPathFor(String bookId) {
    return p.join('thumbnails', '$bookId.png');
  }

  Future<File> thumbnailFile(String bookId) async {
    final dir = await thumbnailsDir();
    return File(p.join(dir.path, '$bookId.png'));
  }

  Future<File?> generateThumbnail({
    required String bookId,
    required String pdfPath,
  }) async {
    try {
      final doc = await PdfDocument.openFile(pdfPath);
      try {
        if (doc.pages.isEmpty) return null;
        final page = doc.pages.first;
        const targetWidth = 240.0;
        final scale = targetWidth / page.width;
        final pageImage = await page.render(
          fullWidth: page.width * scale,
          fullHeight: page.height * scale,
        );
        if (pageImage == null) return null;
        try {
          final image = pageImage.createImageNF();
          final pngBytes = img.encodePng(image);
          final file = await thumbnailFile(bookId);
          await file.writeAsBytes(pngBytes, flush: true);
          return file;
        } finally {
          pageImage.dispose();
        }
      } finally {
        doc.dispose();
      }
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteThumbnail(String bookId) async {
    final file = await thumbnailFile(bookId);
    if (file.existsSync()) {
      await file.delete();
    }
  }
}
