import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/shared/widgets/clipboard_prompt_workbench.dart';

void main() {
  testWidgets('shows the user-ordered prompt workflow', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: ClipboardPromptWorkbench()),
        ),
      ),
    );

    expect(find.text('Paste the source'), findsOneWidget);
    expect(find.text('Add visual context'), findsOneWidget);
    expect(find.text('Shape the instruction'), findsOneWidget);
    expect(find.text('Preview and copy'), findsOneWidget);
    expect(find.text('Paste text'), findsOneWidget);
    expect(find.text('Copy system prompt'), findsOneWidget);
  });
}
