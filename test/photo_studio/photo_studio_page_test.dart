import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/photo_studio/presentation/photo_rect_canvas.dart';
import 'package:flutter_application_1/features/photo_studio/presentation/photo_studio_page.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/display_test_harness.dart';

final _tinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

Future<void> _pumpPage(
  WidgetTester tester, {
  PhotoStudioPage page = const PhotoStudioPage(),
}) async {
  await tester.binding.setSurfaceSize(const Size(900, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(home: await wrapWithDisplayScope(page)),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows photo studio canvas without geographic bounds sections', (tester) async {
    await _pumpPage(tester);

    expect(find.text('Photo Studio'), findsOneWidget);
    expect(find.text('Studio'), findsOneWidget);
    expect(find.text('Center + radius'), findsNothing);
    expect(find.text('Manual bounds'), findsNothing);
    expect(find.text('6. Manual box'), findsNothing);
    expect(find.byType(PhotoRectCanvas), findsOneWidget);
  });

  testWidgets('loads studio photo while keeping an adjustable rectangle', (tester) async {
    await _pumpPage(
      tester,
      page: PhotoStudioPage(imageBytesPicker: () async => _tinyPng),
    );

    expect(find.byType(PhotoRectCanvas), findsOneWidget);
    expect(find.textContaining('left:'), findsOneWidget);

    await tester.runAsync(() async {
      final choose = find.byIcon(Icons.image_outlined);
      await tester.ensureVisible(choose);
      await tester.tap(choose);
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Photo loaded'), findsOneWidget);
    expect(find.textContaining('left:'), findsOneWidget);

    await tester.ensureVisible(find.text('Clear photo'));
    await tester.tap(find.text('Clear photo'));
    await tester.pump();

    expect(find.textContaining('Photo cleared'), findsOneWidget);
    expect(find.textContaining('left:'), findsOneWidget);
  });
}
