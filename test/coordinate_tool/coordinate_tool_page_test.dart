import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/coordinate_tool/presentation/coordinate_tool_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows point, tolerance, bounds and XYZ tile outputs', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CoordinateToolPage()),
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
}
