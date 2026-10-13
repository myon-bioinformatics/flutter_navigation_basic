import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/photo_studio/data/photo_media_ports.dart';
import 'package:flutter_application_1/features/photo_studio/presentation/studio_image_preview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/shared/display/display_scope.dart';
import 'package:flutter_application_1/shared/widgets/clipboard_prompt_workbench.dart';

import '../support/display_test_harness.dart';

final _tinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

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

  testWidgets('Choose photo displays the Photo Studio image surface and scrolls it into view',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(await wrapWithDisplayScope(MaterialApp(
      home: Scaffold(body: SingleChildScrollView(
        child: ClipboardPromptWorkbench(
          imagePicker: () async => PhotoPickOutcome.success(
            _tinyPng,
            declaredMimeType: 'image/png',
          ),
        ),
      )),
    )));
    expect(find.byType(StudioImagePreview), findsNothing);

    await tester.runAsync(() async {
      final choose = find.byKey(const Key('clipboard-import-image'));
      await tester.ensureVisible(choose);
      await tester.tap(choose);
      await Future<void>.delayed(const Duration(milliseconds: 250));
    });
    await tester.pump();
    await tester.pumpAndSettle();

    final previewFinder = find.byType(StudioImagePreview);
    expect(previewFinder, findsOneWidget);
    final preview = tester.widget<StudioImagePreview>(previewFinder);
    expect(preview.bytes, isNotEmpty);
    final image = tester.widget<Image>(
      find.descendant(of: previewFinder, matching: find.byType(Image)),
    );
    expect(image.image, isA<MemoryImage>());
    expect(image.fit, BoxFit.contain);
    expect((image.image as MemoryImage).bytes, orderedEquals(preview.bytes));
    expect(tester.getRect(previewFinder).height, 280);
    // The preview is above Choose photo; it must be revealed after import.
    expect(
      tester.getRect(previewFinder).overlaps(tester.getRect(find.byType(Scaffold))),
      isTrue,
    );
    expect(find.textContaining('image/png'), findsWidgets);
  });

  testWidgets('decoded Base64 uses the same image preview as photo imports',
      (tester) async {
    await tester.pumpWidget(await wrapWithDisplayScope(MaterialApp(
      home: const Scaffold(body: SingleChildScrollView(
        child: ClipboardPromptWorkbench(),
      )),
    )));
    await tester.enterText(
      find.byType(TextField).at(1),
      'data:image/png;base64,${base64Encode(_tinyPng)}',
    );
    final decodeButton = find.text('Decode / preview');
    await tester.ensureVisible(decodeButton);
    await tester.tap(decodeButton);
    await tester.pumpAndSettle();

    expect(find.byType(StudioImagePreview), findsOneWidget);
    expect(
      tester.widget<StudioImagePreview>(find.byType(StudioImagePreview)).bytes,
      orderedEquals(_tinyPng),
    );
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
