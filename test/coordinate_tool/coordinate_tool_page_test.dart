import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/coordinate_tool/domain/coordinate_formatter.dart';
import 'package:flutter_application_1/features/coordinate_tool/presentation/coordinate_tool_page.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/display_test_harness.dart';

void main() {
  testWidgets('shows point, tolerance, bounds and XYZ tile outputs', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: await wrapWithDisplayScope(const CoordinateToolPage())),
    );
    await tester.pumpAndSettle();

    expect(find.text('1. Point'), findsOneWidget);
    expect(find.text('2. Tolerance'), findsOneWidget);
    expect(find.text('3. Bounds'), findsOneWidget);
    expect(find.text('4. XYZ tile'), findsOneWidget);
    expect(find.text('Center + radius'), findsOneWidget);
    expect(find.text('Loose bounding box'), findsOneWidget);
    expect(find.text('BBox [west, south, east, north]'), findsOneWidget);
    expect(find.text('JSON'), findsOneWidget);
    expect(find.text('XYZ tile'), findsOneWidget);
    expect(find.text('Tile path'), findsOneWidget);
    expect(find.textContaining('radius_m: 100'), findsOneWidget);
    expect(find.textContaining('16/58211/25806'), findsWidgets);
  });

  testWidgets('invalid custom radius keeps point and controls recoverable', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: await wrapWithDisplayScope(const CoordinateToolPage())),
    );
    await tester.pumpAndSettle();

    final presetDropdown = find.byWidgetPredicate(
      (widget) => widget is DropdownButtonFormField<CoordinateTolerancePreset>,
      description: 'coordinate tolerance preset dropdown',
    );
    expect(presetDropdown, findsOneWidget);
    await tester.ensureVisible(presetDropdown);
    await tester.pumpAndSettle();
    await tester.tap(presetDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom').last);
    await tester.pumpAndSettle();

    final customRadius = find.widgetWithText(TextField, 'Custom radius (m)');
    expect(customRadius, findsOneWidget);
    await tester.ensureVisible(customRadius);
    await tester.pumpAndSettle();

    await tester.enterText(customRadius, '0');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(
      find.text('Custom radius must be a number greater than zero.'),
      findsOneWidget,
    );
    expect(find.text('Decimal degrees'), findsOneWidget);
    expect(find.text('2. Tolerance'), findsOneWidget);
    expect(customRadius, findsOneWidget);
    expect(find.text('4. XYZ tile'), findsOneWidget);
    expect(find.text('XYZ tile'), findsOneWidget);
    expect(find.text('Center + radius'), findsNothing);

    await tester.enterText(customRadius, '250');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(
      find.text('Custom radius must be a number greater than zero.'),
      findsNothing,
    );
    expect(find.text('Center + radius'), findsOneWidget);
    expect(find.textContaining('radius_m: 250'), findsOneWidget);
  });
}
