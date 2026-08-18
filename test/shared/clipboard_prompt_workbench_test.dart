import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/shared/display/display_scope.dart';
import 'package:flutter_application_1/shared/widgets/clipboard_prompt_workbench.dart';

import '../support/display_test_harness.dart';

void main() {
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

    await controller.setLocale('fr');
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

    await controller.setLocale('ja');
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, '目的'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, '目的'), 'Ship the release');
    await tester.pump();

    expect(find.textContaining('## Goal'), findsOneWidget);
  });
}
