import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/http_request_draft/presentation/http_request_draft_page.dart';
import 'package:flutter_application_1/shared/http/request_draft.dart';
import 'package:flutter_application_1/shared/http/request_draft_codec.dart';
import 'package:flutter_application_1/shared/http/request_field.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/display_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('add and delete header rows update the editor', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      await wrapWithDisplayScope(
        const MaterialApp(home: HttpRequestDraftPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('HTTP Request Draft'), findsOneWidget);

    final addButtons = find.text('Add row');
    expect(addButtons, findsWidgets);
    await tester.ensureVisible(addButtons.at(1));
    await tester.tap(addButtons.at(1));
    await tester.pumpAndSettle();

    final deleteIcons = find.byIcon(Icons.delete_outline);
    expect(deleteIcons, findsWidgets);
    await tester.tap(deleteIcons.at(1));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('fullwidth URL paste appears as ASCII in preview', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      await wrapWithDisplayScope(
        const MaterialApp(home: HttpRequestDraftPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField).first,
      'ｈｔｔｐｓ：／／ｅｘａｍｐｌｅ．ｃｏｍ／ａｐｉ',
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('https://example.com/api'), findsWidgets);
    expect(find.textContaining('ｈｔｔｐｓ'), findsNothing);
  });

  testWidgets('redacted curl from draft never includes bearer secret',
      (tester) async {
    // Codec path used by the page preview (UI asserts via SelectableText hard).
    final draft = RequestDraft(
      url: 'https://example.com',
      headers: const [
        RequestField(
          id: '1',
          name: 'Authorization',
          value: 'Bearer top-secret',
        ),
      ],
    );
    final curl = RequestDraftCodec.toCurl(draft);
    expect(curl, contains('***'));
    expect(curl, isNot(contains('top-secret')));
  });

  testWidgets('page dispose completes without controller exceptions',
      (tester) async {
    await tester.pumpWidget(
      await wrapWithDisplayScope(
        const MaterialApp(home: HttpRequestDraftPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
