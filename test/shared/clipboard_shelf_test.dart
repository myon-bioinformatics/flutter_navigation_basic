import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/shared/widgets/clipboard_shelf.dart';

void main() {
  testWidgets('adds and classifies a Markdown shelf item in memory', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: ClipboardShelf()),
        ),
      ),
    );

    expect(find.text('Core Tool #1 · Clipboard Shelf'), findsOneWidget);
    expect(find.text('Shelf is empty for this filter.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '# Heading\n- item');
    await tester.tap(find.widgetWithText(OutlinedButton, 'Add manually'));
    await tester.pump();

    expect(find.text('Markdown'), findsWidgets);
    expect(find.text('# Heading\n- item'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Copy plain'), findsOneWidget);
  });

  testWidgets('plain preview keeps identifiers and inline code content', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: ClipboardShelf()),
        ),
      ),
    );

    await tester.enterText(
      find.byType(TextField).first,
      '# Notes\n- `my_variable_name` uses a*b\n[Docs](https://example.com)',
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'Add manually'));
    await tester.pump();
    await tester.tap(find.text('Plain preview'));
    await tester.pumpAndSettle();

    expect(
      find.text('Notes\nmy_variable_name uses a*b\nDocs (https://example.com)'),
      findsOneWidget,
    );
  });
}
