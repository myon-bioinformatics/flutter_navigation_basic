import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/shared/widgets/clipboard_prompt_workbench.dart';

void main() {
  testWidgets('shows the user-ordered clipboard and prompt workflow', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: ClipboardPromptWorkbench()),
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
}
