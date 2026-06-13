import 'package:bookshelf/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Bookshelf app smoke test', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: BookshelfApp()),
    );
    expect(find.text('Bookshelf'), findsOneWidget);
  });
}
