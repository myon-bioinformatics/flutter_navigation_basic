import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/shared/display/display_scope.dart';
import 'package:flutter_application_1/shared/widgets/clipboard_shelf.dart';

import '../support/display_test_harness.dart';

void main() {
  Future<void> pumpShelf(WidgetTester tester) async {
    await tester.pumpWidget(
      await wrapWithDisplayScope(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: ClipboardShelf()),
          ),
        ),
      ),
    );
  }

  Future<void> addManual(
    WidgetTester tester,
    String value,
  ) async {
    await tester.enterText(find.byType(TextField).first, value);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Add manually'));
    await tester.pump(const Duration(milliseconds: 2));
  }

  testWidgets('adds and classifies a Markdown shelf item in memory', (tester) async {
    await pumpShelf(tester);

    expect(find.text('Core Tool #1 · Clipboard Shelf'), findsOneWidget);
    expect(find.text('Shelf is empty for this filter.'), findsOneWidget);

    await addManual(tester, '# Heading\n- item');

    expect(find.text('Markdown'), findsWidgets);
    expect(find.text('# Heading\n- item'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Copy plain'), findsOneWidget);
  });

  testWidgets('plain preview keeps identifiers and inline code content', (tester) async {
    await pumpShelf(tester);

    await addManual(
      tester,
      '# Notes\n- `my_variable_name` uses a*b\n[Docs](https://example.com)',
    );
    await tester.tap(find.text('Plain preview'));
    await tester.pumpAndSettle();

    expect(
      find.text('Notes\nmy_variable_name uses a*b\nDocs (https://example.com)'),
      findsOneWidget,
    );
  });

  testWidgets('visible bundle follows oldest-first display order', (tester) async {
    String? copiedText;
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copiedText = (call.arguments as Map<Object?, Object?>)['text'] as String?;
      }
      return null;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await pumpShelf(tester);
    await addManual(tester, 'first item');
    await addManual(tester, 'second item');

    await tester.tap(find.byType(DropdownButton<ClipboardShelfSort>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oldest first').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Copy visible bundle'));
    await tester.pump();

    expect(copiedText, isNotNull);
    expect(copiedText!.indexOf('first item'), lessThan(copiedText!.indexOf('second item')));
  });

  testWidgets('manual reorder while filtered swaps visible neighbors', (tester) async {
    await pumpShelf(tester);
    await addManual(tester, 'first text');
    await addManual(tester, 'https://example.com');
    await addManual(tester, 'second text');

    await tester.tap(find.widgetWithText(FilterChip, 'Text'));
    await tester.pumpAndSettle();

    final secondText = find.widgetWithText(SelectableText, 'second text');
    final secondCard = find.ancestor(of: secondText, matching: find.byType(Card)).first;
    final moveDown = find.descendant(of: secondCard, matching: find.byTooltip('Move down'));
    expect(moveDown, findsOneWidget);

    await tester.tap(moveDown);
    await tester.pumpAndSettle();

    final visibleText = tester
        .widgetList<SelectableText>(find.byType(SelectableText))
        .map((widget) => widget.data)
        .whereType<String>()
        .toList();
    expect(visibleText.indexOf('first text'), lessThan(visibleText.indexOf('second text')));
  });

  testWidgets('switching the app-wide locale re-renders shelf chrome and status text', (tester) async {
    final controller = await loadTestDisplayController();
    await tester.pumpWidget(
      DisplayScope(
        controller: controller,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: ClipboardShelf()),
          ),
        ),
      ),
    );

    expect(find.text('Shelf is empty for this filter.'), findsOneWidget);
    expect(find.text('Session-only shelf: items disappear when the app/page is restarted.'), findsOneWidget);

    await controller.setLocale('ja');
    await tester.pumpAndSettle();

    expect(find.text('このフィルターに該当する棚の項目はありません。'), findsOneWidget);
    expect(find.text('セッション限定の棚です。アプリ／ページを再起動すると項目は消えます。'), findsOneWidget);
    expect(find.text('テキスト / URL / Markdown を追加'), findsOneWidget);
  });
}
