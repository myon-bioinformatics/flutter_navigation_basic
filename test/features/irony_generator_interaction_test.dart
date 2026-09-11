import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/irony_generator/domain/irony_generator_controller.dart';
import 'package:flutter_application_1/features/irony_generator/presentation/irony_generator_page.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/display_test_harness.dart';

Future<void> _pan(WidgetTester tester, Finder handle, Offset delta) async {
  final gesture = await tester.startGesture(tester.getCenter(handle));
  await gesture.moveBy(delta);
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

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
    final initialIrony = controller.irony;
    expect(find.byType(SelectableText), findsOneWidget);
    expect(find.text(initialIrony), findsOneWidget);

    await _pan(tester, find.byIcon(Icons.drag_indicator), const Offset(48, 32));

    final movedCenter = tester.getCenter(card);
    expect(controller.irony, initialIrony);
    expect(find.text(initialIrony), findsOneWidget);
    expect(find.byType(SelectableText), findsOneWidget);
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
    await _pan(tester, find.byIcon(Icons.drag_indicator), const Offset(1600, 0));

    expect(controller.irony, isNot(firstIrony));
    expect(find.text(controller.irony), findsOneWidget);
    final scaffoldCenter = tester.getCenter(find.byType(Scaffold));
    expect(
      tester.getCenter(find.byKey(const ValueKey('irony-message-card'))).dx,
      closeTo(scaffoldCenter.dx, 2),
    );
  });

  testWidgets(
      'partial exit snaps the handle back without changing the irony',
      (tester) async {
    final controller = IronyGeneratorController(random: Random(13));
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
    final card = find.byKey(const ValueKey('irony-message-card'));
    final arena = find.byKey(const ValueKey('irony-drag-arena'));

    final handleRect = tester.getRect(handle);
    final cardRect = tester.getRect(card);
    final arenaRect = tester.getRect(arena);

    // Push the handle fully above the arena while leaving the card overlapping.
    final deltaY = arenaRect.top - handleRect.bottom - 12;
    expect(
      cardRect.bottom + deltaY,
      greaterThan(arenaRect.top),
      reason: 'precondition: card body must remain partially visible',
    );

    await _pan(tester, handle, Offset(0, deltaY));

    expect(controller.irony, firstIrony);
    expect(find.text(firstIrony), findsOneWidget);

    final handleAfter = tester.getRect(handle);
    final arenaAfter = tester.getRect(arena);
    expect(
      handleAfter.overlaps(arenaAfter),
      isTrue,
      reason: 'unreachable handle should snap back into the arena',
    );
  });
}
