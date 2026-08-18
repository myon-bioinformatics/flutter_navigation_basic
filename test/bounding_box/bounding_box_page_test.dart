import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/bounding_box/presentation/bounding_box_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows separate bounding box workflow and copy formats', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: BoundingBoxPage()),
    );
    await tester.pump();

    expect(find.text('Bounding Box'), findsOneWidget);
    expect(find.text('Center + radius'), findsOneWidget);
    expect(find.text('Manual bounds'), findsOneWidget);
    expect(find.text('Generate bounds'), findsOneWidget);
    expect(find.text('Validate bounds'), findsOneWidget);
    expect(find.text('South / West / North / East'), findsOneWidget);
    expect(find.text('BBox [west, south, east, north]'), findsOneWidget);
    expect(find.text('JSON'), findsOneWidget);
  });

  testWidgets('generates bounds from center and radius', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: BoundingBoxPage()),
    );
    await tester.pump();

    await tester.tap(find.text('Generate bounds'));
    await tester.pump();

    expect(find.textContaining('Center: 35.681236, 139.767125'), findsOneWidget);
    expect(find.textContaining('wraps_antimeridian: false'), findsWidgets);
  });
}
