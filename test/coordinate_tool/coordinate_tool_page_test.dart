import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/coordinate_tool/domain/coordinate_formatter.dart';
import 'package:flutter_application_1/features/coordinate_tool/presentation/coordinate_tool_page.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/display_test_harness.dart';

void main() {
  testWidgets('shows point, map links, tolerance, area maps, bounds, platform formats and XYZ', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: await wrapWithDisplayScope(const CoordinateToolPage())),
    );
    await tester.pumpAndSettle();

    // "XYZ tile" is used as both the section title and the result-card title
    // (both share the coordinate.xyzTile catalog key), so it renders twice.
    expect(find.text('1. Point'), findsOneWidget);
    expect(find.text('2. Tolerance'), findsOneWidget);
    expect(find.text('3. Bounds'), findsOneWidget);
    expect(find.text('Map links · point'), findsOneWidget);
    expect(find.text('Map links · area'), findsOneWidget);
    expect(find.text('Open in Google Maps'), findsNWidgets(2));
    expect(find.text('Open in Apple Maps'), findsNWidgets(2));
    expect(find.text('4. Platform formats'), findsOneWidget);
    expect(find.text('5. XYZ tile'), findsNWidgets(2));
    expect(find.text('6. Manual box'), findsOneWidget);
    expect(find.text('Generate bounds'), findsOneWidget);
    expect(find.text('From center + radius'), findsOneWidget);
    expect(find.text('From four edges'), findsOneWidget);
    expect(find.text('BBox [west, south, east, north]'), findsWidgets);
    expect(find.text('JSON'), findsWidgets);
    expect(find.text('Google Maps JavaScript · Circle'), findsOneWidget);
    expect(find.text('Apple MapKit · MKCircle (Swift)'), findsOneWidget);
    expect(find.text('Google Maps JavaScript · Rectangle'), findsOneWidget);
    expect(find.text('Apple MapKit · MKCoordinateRegion (Swift)'), findsOneWidget);
    expect(find.text('Tile path'), findsOneWidget);
    expect(find.textContaining('radius_m: 100'), findsOneWidget);
    expect(find.textContaining('new google.maps.Circle'), findsOneWidget);
    expect(find.textContaining('new google.maps.Rectangle'), findsOneWidget);
    expect(find.textContaining('MKCircle('), findsOneWidget);
    expect(find.textContaining('MKCoordinateRegion('), findsOneWidget);
    expect(find.textContaining('16/58211/25806'), findsWidgets);
    expect(find.textContaining('https://www.google.com/maps/@35.681236,139.767125,16z'), findsOneWidget);
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
    expect(find.text('5. XYZ tile'), findsNWidgets(2));
    expect(find.text('6. Manual box'), findsOneWidget);
    expect(find.text('Generate bounds'), findsOneWidget);
    expect(find.text('Center + radius'), findsNothing);
    expect(find.text('Map links · area'), findsNothing);
    expect(find.text('4. Platform formats'), findsNothing);

    await tester.enterText(customRadius, '250');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(
      find.text('Custom radius must be a number greater than zero.'),
      findsNothing,
    );
    expect(find.text('From center + radius'), findsOneWidget);
    expect(find.text('Map links · area'), findsOneWidget);
    expect(find.textContaining('radius_m: 250'), findsOneWidget);
    expect(find.text('4. Platform formats'), findsOneWidget);
    expect(find.textContaining('radius: 250'), findsNWidgets(2));
  });

  testWidgets('applies Google/Apple Maps URL into decimal and DMS', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: await wrapWithDisplayScope(const CoordinateToolPage())),
    );
    await tester.pumpAndSettle();

    final mapsUrl = find.widgetWithText(
      TextField,
      'Paste Google / Apple Maps URL',
    );
    expect(mapsUrl, findsOneWidget);
    await tester.ensureVisible(mapsUrl);
    await tester.pumpAndSettle();

    await tester.enterText(
      mapsUrl,
      'https://maps.apple.com/?ll=-33.868800,-70.669300&q=Coordinates',
    );
    await tester.tap(find.text('Use map link'));
    await tester.pumpAndSettle();

    expect(find.text('-33.868800, -70.669300'), findsOneWidget);
    expect(
      find.textContaining('S'),
      findsWidgets,
    );
    expect(
      find.textContaining('W'),
      findsWidgets,
    );
    expect(
      find.text(CoordinateValue.parse(
        latitude: '-33.8688',
        longitude: '-70.6693',
      ).dms),
      findsOneWidget,
    );
  });

  testWidgets('shows error for Maps URL without coordinates', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: await wrapWithDisplayScope(const CoordinateToolPage())),
    );
    await tester.pumpAndSettle();

    final mapsUrl = find.widgetWithText(
      TextField,
      'Paste Google / Apple Maps URL',
    );
    await tester.enterText(mapsUrl, 'https://maps.apple.com/?q=Tokyo');
    await tester.tap(find.text('Use map link'));
    await tester.pumpAndSettle();

    expect(
      find.text('Could not find latitude/longitude in that Maps URL.'),
      findsOneWidget,
    );
  });

  testWidgets('generates manual box from center and radius', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: await wrapWithDisplayScope(const CoordinateToolPage())),
    );
    await tester.pumpAndSettle();

    final radiusField = find.widgetWithText(TextField, 'Radius (meters)');
    await tester.ensureVisible(radiusField);
    await tester.enterText(radiusField, '500');
    await tester.pump();

    final generate = find.text('Generate bounds');
    await tester.ensureVisible(generate);
    await tester.tap(generate);
    await tester.pump();

    expect(find.textContaining('Center:'), findsWidgets);
    expect(find.textContaining('Span:'), findsWidgets);
    expect(find.text('BBox [west, south, east, north]'), findsWidgets);
  });
}
