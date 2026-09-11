import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/bounding_box/presentation/bounding_box_page.dart';
import 'package:flutter_application_1/features/bounding_box/presentation/image_rect_overlay.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/display_test_harness.dart';

final _tinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

Future<void> _pumpPage(
  WidgetTester tester, {
  BoundingBoxPage page = const BoundingBoxPage(),
}) async {
  await tester.binding.setSurfaceSize(const Size(900, 2200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(home: await wrapWithDisplayScope(page)),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows separate bounding box workflow and copy formats', (tester) async {
    await _pumpPage(tester);

    expect(find.text('Bounding Box'), findsOneWidget);
    expect(find.text('Image overlay'), findsOneWidget);
    expect(find.text('Center + radius'), findsOneWidget);
    expect(find.text('Manual bounds'), findsOneWidget);
    expect(find.text('Generate bounds'), findsOneWidget);
    expect(find.text('Validate bounds'), findsOneWidget);
    expect(find.text('South / West / North / East'), findsOneWidget);
    expect(find.text('BBox [west, south, east, north]'), findsOneWidget);
    expect(find.text('JSON'), findsOneWidget);
    expect(find.byType(ImageRectOverlay), findsOneWidget);
  });

  testWidgets('generates bounds from center and radius', (tester) async {
    await _pumpPage(tester);

    final radiusField = find.widgetWithText(TextField, 'Radius (meters)');
    await tester.ensureVisible(radiusField);
    await tester.enterText(radiusField, '500');
    await tester.pump();

    final generate = find.text('Generate bounds');
    await tester.ensureVisible(generate);
    await tester.tap(generate);
    await tester.pump();

    expect(find.textContaining('Center: 35.681236, 139.767125'), findsOneWidget);
    expect(find.textContaining('Span: '), findsOneWidget);
    expect(find.textContaining('wraps_antimeridian: false'), findsWidgets);
  });

  testWidgets('loads overlay image while keeping an adjustable rectangle', (tester) async {
    await _pumpPage(
      tester,
      page: BoundingBoxPage(imageBytesPicker: () async => _tinyPng),
    );

    expect(find.byType(ImageRectOverlay), findsOneWidget);
    expect(find.textContaining('left:'), findsOneWidget);

    await tester.runAsync(() async {
      final choose = find.byIcon(Icons.image_outlined);
      await tester.ensureVisible(choose);
      await tester.tap(choose);
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Image loaded'), findsOneWidget);
    expect(find.textContaining('left:'), findsOneWidget);

    await tester.ensureVisible(find.text('Clear image'));
    await tester.tap(find.text('Clear image'));
    await tester.pump();

    expect(find.textContaining('Image cleared'), findsOneWidget);
    expect(find.textContaining('left:'), findsOneWidget);
  });
}
