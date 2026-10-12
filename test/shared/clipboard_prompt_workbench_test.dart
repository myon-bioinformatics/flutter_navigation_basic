import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/photo_studio/data/photo_media_ports.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/shared/display/display_scope.dart';
import 'package:flutter_application_1/shared/widgets/clipboard_prompt_workbench.dart';

import '../support/display_test_harness.dart';

void main() {
  testWidgets('image import button uses Photo Studio picker and handles cancellation',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(await wrapWithDisplayScope(MaterialApp(
      home: Scaffold(body: SingleChildScrollView(
        child: ClipboardPromptWorkbench(
          imagePicker: () async {
            calls++;
            return const PhotoPickOutcome.cancelled();
          },
        ),
      )),
    )));
    final button = find.byKey(const Key('clipboard-import-image'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.byKey(const Key('clipboard-import-image')), findsOneWidget);
  });

  testWidgets('rejects nonimage picker MIME without attaching bytes', (tester) async {
    await tester.pumpWidget(await wrapWithDisplayScope(MaterialApp(
      home: Scaffold(body: SingleChildScrollView(
        child: ClipboardPromptWorkbench(
          imagePicker: () async => PhotoPickOutcome.success(
            Uint8List.fromList([1, 2, 3]),
            declaredMimeType: 'text/plain',
          ),
        ),
      )),
    )));
    final button = find.byKey(const Key('clipboard-import-image'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.textContaining('image import rejected'), findsWidgets);
  });

  testWidgets('shows the user-ordered clipboard and prompt workflow', (tester) async {
    await tester.pumpWidget(
      await wrapWithDisplayScope(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: ClipboardPromptWorkbench()),
          ),
        ),
      ),
    );

    expect(find.text('Copy / paste the source'), findsOneWidget);
    expect(find.text('Base64 Image Bridge'), findsOneWidget);
    expect(find.text('Shape the instruction'), findsOneWidget);
    expect(find.text('Preview and copy'), findsOneWidget);
    expect(find.text('Paste text'), findsOneWidget);
    expect(find.text('Paste Base64 image'), findsOneWidget);
    expect(find.text('Decode / preview'), findsOneWidget);
    expect(find.text('Copy system prompt'), findsOneWidget);
  });

  testWidgets('switching the app-wide locale re-renders workbench chrome and status text', (tester) async {
    final controller = await loadTestDisplayController();
    await tester.pumpWidget(
      DisplayScope(
        controller: controller,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: ClipboardPromptWorkbench()),
          ),
        ),
      ),
    );

    expect(find.text('Shape the instruction'), findsOneWidget);
    expect(find.text('Select/copy/paste text freely, then shape it into a reusable system prompt.'), findsOneWidget);

    await controller.setLocale('fra');
    await tester.pumpAndSettle();

    expect(find.text('Structurer l\'instruction'), findsOneWidget);
    expect(find.text('Copier le prompt système'), findsOneWidget);
    expect(
      find.text('Sélectionnez/copiez/collez du texte librement, puis façonnez-le en un prompt système réutilisable.'),
      findsOneWidget,
    );
  });

  testWidgets('goal field label reflects locale while composed prompt headers stay literal English', (tester) async {
    final controller = await loadTestDisplayController();
    await tester.pumpWidget(
      DisplayScope(
        controller: controller,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: ClipboardPromptWorkbench()),
          ),
        ),
      ),
    );

    await controller.setLocale('jpn');
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, '目的'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, '目的'), 'Ship the release');
    await tester.pump();

    expect(find.textContaining('## Goal'), findsOneWidget);
  });
}
