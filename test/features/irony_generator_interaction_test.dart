import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/irony_generator/domain/irony_generator_controller.dart';
import 'package:flutter_application_1/features/irony_generator/presentation/irony_generator_page.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/display_test_harness.dart';

void main() {
  testWidgets('message stays selectable and keeps its dragged position',
      (tester) async {
    final controller = IronyGeneratorController(random: Random(7));
    await tester.pumpWidget(
      MaterialApp(
        home: await wrapWithDisplayScope(
          IronyGeneratorPage(controller: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final card = find.byKey(const ValueKey('irony-message-card'));
    final initialCenter = tester.getCenter(card);
    expect(find.byType(SelectableText), findsOneWidget);

    await tester.drag(find.byIcon(Icons.drag_indicator), const Offset(48, 32));
    await tester.pumpAndSettle();

    final movedCenter = tester.getCenter(card);
    expect(movedCenter.dx, closeTo(initialCenter.dx + 48, 1));
    expect(movedCenter.dy, closeTo(initialCenter.dy + 32, 1));
  });

  testWidgets('moving the card fully outside spawns a different irony',
      (tester) async {
    final controller = IronyGeneratorController(random: Random(11));
    await tester.pumpWidget(
      MaterialApp(
        home: await wrapWithDisplayScope(
          IronyGeneratorPage(controller: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final firstIrony = controller.irony;
    final handle = find.byIcon(Icons.drag_indicator);
    await tester.drag(handle, const Offset(1600, 0));
    await tester.pumpAndSettle();

    expect(controller.irony, isNot(firstIrony));
    expect(find.text(controller.irony), findsOneWidget);
    expect(
      tester.getCenter(find.byKey(const ValueKey('irony-message-card'))).dx,
      closeTo(400, 2),
    );
  });
}
