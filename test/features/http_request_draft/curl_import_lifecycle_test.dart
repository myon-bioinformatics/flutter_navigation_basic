import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/http_request_draft/presentation/http_request_draft_page.dart';
import 'package:flutter_application_1/shared/http/curl_import_result.dart';
import 'package:flutter_application_1/shared/http/request_draft.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/display_test_harness.dart';

void main() {
  final response = CurlImportResult(draft: const RequestDraft(url: 'https://late.example/'));
  Future<void> show(WidgetTester tester, Future<CurlImportResult> Function(String) importer) async {
    await tester.binding.setSurfaceSize(const Size(600, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(await wrapWithDisplayScope(
        MaterialApp(home: HttpRequestDraftPage(curlImporter: importer))));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'curl https://late.example/');
    await tester.tap(find.byKey(const ValueKey('curl-import-button')));
    await tester.pump();
  }

  testWidgets('in-flight import disables duplicate action then applies result', (tester) async {
    final done = Completer<CurlImportResult>();
    var calls = 0;
    await show(tester, (_) { calls++; return done.future; });
    final button = tester.widget<FilledButton>(find.byKey(const ValueKey('curl-import-button')));
    expect(button.onPressed, isNull);
    expect(calls, 1);
    done.complete(response);
    await tester.pumpAndSettle();
    final url = tester.widget<TextField>(find.byType(TextField).at(1));
    expect(url.controller!.text, 'https://late.example/');
    expect(tester.takeException(), isNull);
  });

  testWidgets('edited draft is not overwritten by a late reply', (tester) async {
    final done = Completer<CurlImportResult>();
    await show(tester, (_) => done.future);
    await tester.enterText(find.byType(TextField).at(1), 'https://edited.example/');
    done.complete(response);
    await tester.pumpAndSettle();
    final url = tester.widget<TextField>(find.byType(TextField).at(1));
    expect(url.controller!.text, 'https://edited.example/');
    expect(tester.takeException(), isNull);
  });

  testWidgets('late completion after dispose does not setState', (tester) async {
    final done = Completer<CurlImportResult>();
    await show(tester, (_) => done.future);
    await tester.pumpWidget(const SizedBox.shrink());
    done.complete(response);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
