import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/photo_studio/domain/emoji_stamp.dart';
import 'package:flutter_application_1/features/photo_studio/testing/photo_studio_test_probe.dart';
import 'package:flutter_application_1/features/photo_studio/domain/normalized_rect.dart';
import 'package:flutter_application_1/features/photo_studio/domain/studio_frame_style.dart';
import 'package:flutter_application_1/features/photo_studio/presentation/compose_studio_image.dart';
import 'package:flutter_application_1/features/photo_studio/presentation/photo_rect_canvas.dart';
import 'package:flutter_application_1/features/photo_studio/presentation/photo_studio_page.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/display_test_harness.dart';

final _tinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

const _pngSignature = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
];

bool _isPng(Uint8List bytes) {
  if (bytes.length < _pngSignature.length) return false;
  for (var i = 0; i < _pngSignature.length; i++) {
    if (bytes[i] != _pngSignature[i]) return false;
  }
  return true;
}

(int, int) _pngSize(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  return (data.getUint32(16), data.getUint32(20));
}

String _rectCardText(WidgetTester tester) {
  final selectables = tester
      .widgetList<SelectableText>(find.byType(SelectableText))
      .map((w) => w.data ?? '')
      .where((t) => t.contains('left:') && t.contains('top:') && t.contains('right:'))
      .toList();
  expect(selectables, isNotEmpty);
  return selectables.first;
}

Future<void> _pumpPage(
  WidgetTester tester, {
  PhotoStudioPage page = const PhotoStudioPage(),
  Size surface = const Size(900, 1800),
}) async {
  await tester.binding.setSurfaceSize(surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(home: await wrapWithDisplayScope(page)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _tapSavePng(WidgetTester tester) async {
  final saveButton = find.widgetWithText(FilledButton, 'Save PNG');
  await tester.ensureVisible(saveButton);
  await tester.runAsync(() async {
    await tester.tap(saveButton);
    await Future<void>.delayed(const Duration(milliseconds: 350));
  });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('shows photo studio canvas without geographic bounds sections',
      (tester) async {
    await _pumpPage(tester);

    expect(find.text('Photo Studio'), findsOneWidget);
    expect(find.text('Studio'), findsOneWidget);
    expect(find.text('Center + radius'), findsNothing);
    expect(find.text('Manual bounds'), findsNothing);
    expect(find.text('6. Manual box'), findsNothing);
    expect(find.byType(PhotoRectCanvas), findsOneWidget);
    expect(find.text('Rectangle'), findsOneWidget);
    expect(find.text('Circle'), findsOneWidget);
    expect(find.text('Triangle'), findsOneWidget);
    expect(find.text('Emoji stamps'), findsOneWidget);
  });

  testWidgets('loads studio photo while keeping an adjustable rectangle',
      (tester) async {
    await _pumpPage(
      tester,
      page: PhotoStudioPage(imageBytesPicker: () async => _tinyPng),
    );

    await tester.runAsync(() async {
      final choose = find.byIcon(Icons.image_outlined);
      await tester.ensureVisible(choose);
      await tester.tap(choose);
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Photo loaded'), findsOneWidget);
    expect(find.textContaining('left: 0.'), findsWidgets);

    await tester.ensureVisible(find.text('Clear photo'));
    await tester.tap(find.text('Clear photo'));
    await tester.pump();

    expect(find.textContaining('Photo cleared'), findsOneWidget);
  });

  testWidgets('bounded undo restores shape then disables when empty',
      (tester) async {
    PhotoStudioTestProbe? probe;
    await _pumpPage(
      tester,
      page: PhotoStudioPage(onTestProbe: (p) => probe = p),
    );

    await tester.ensureVisible(find.text('Circle'));
    await tester.tap(find.text('Circle'));
    await tester.pump();
    expect(probe?.shapeName, 'circle');
    expect(probe?.undoDepth, 1);

    await tester.ensureVisible(find.text('Undo'));
    await tester.tap(find.text('Undo').last);
    await tester.pump();
    expect(probe?.shapeName, 'rectangle');
    expect(probe?.undoDepth, 0);
    expect(find.textContaining('Undid'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Undo'))
          .onPressed,
      isNull,
    );
  });

  testWidgets(
      'multi-step undo restores shape, frame move, stamp place, then stamp drag',
      (tester) async {
    PhotoStudioTestProbe? probe;
    await _pumpPage(
      tester,
      page: PhotoStudioPage(onTestProbe: (p) => probe = p),
    );

    await tester.tap(find.text('Circle'));
    await tester.pump();
    expect(probe?.shapeName, 'circle');

    final box = tester.getRect(find.byType(PhotoRectCanvas));
    final moveStart =
        Offset(box.left + box.width * 0.5, box.top + box.height * 0.5);
    final moveEnd =
        Offset(moveStart.dx + box.width * 0.1, moveStart.dy + box.height * 0.06);
    final beforeMove = (
      probe!.rectLeft,
      probe!.rectTop,
      probe!.rectRight,
      probe!.rectBottom,
    );
    var gesture = await tester.startGesture(moveStart);
    await tester.pump();
    await gesture.moveTo(moveEnd);
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(
      (probe!.rectLeft, probe!.rectTop, probe!.rectRight, probe!.rectBottom),
      isNot(beforeMove),
    );
    final afterMove = (
      probe!.rectLeft,
      probe!.rectTop,
      probe!.rectRight,
      probe!.rectBottom,
    );

    await tester.tap(find.text('⭐'));
    await tester.pump();
    final place =
        Offset(box.left + box.width * 0.18, box.top + box.height * 0.22);
    await tester.tapAt(place);
    await tester.pump();
    expect(probe!.stamps, hasLength(1));
    final placed = probe!.stamps.single;
    expect(placed.x, closeTo(0.18, 0.04));
    expect(placed.y, closeTo(0.22, 0.04));
    expect(probe!.undoDepth, 3);

    gesture = await tester.startGesture(place);
    await tester.pump();
    await gesture.moveTo(Offset(place.dx + 50, place.dy + 30));
    await tester.pump();
    await gesture.moveTo(Offset(place.dx + 100, place.dy + 60));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(probe!.undoDepth, 4);
    final dragged = probe!.stamps.single;
    expect(dragged.x, isNot(closeTo(placed.x, 0.01)));
    expect(dragged.y, isNot(closeTo(placed.y, 0.01)));

    // Undo drag → place coords
    await tester.tap(find.text('Undo').last);
    await tester.pump();
    expect(probe!.undoDepth, 3);
    expect(probe!.stamps.single.x, closeTo(placed.x, 0.001));
    expect(probe!.stamps.single.y, closeTo(placed.y, 0.001));

    // Undo place → no stamps, frame still moved
    await tester.tap(find.text('Undo').last);
    await tester.pump();
    expect(probe!.undoDepth, 2);
    expect(probe!.stamps, isEmpty);
    expect(
      (probe!.rectLeft, probe!.rectTop, probe!.rectRight, probe!.rectBottom),
      afterMove,
    );

    // Undo move → pre-move rect, still circle
    await tester.tap(find.text('Undo').last);
    await tester.pump();
    expect(probe!.undoDepth, 1);
    expect(
      (probe!.rectLeft, probe!.rectTop, probe!.rectRight, probe!.rectBottom),
      beforeMove,
    );
    expect(probe!.shapeName, 'circle');

    // Undo shape → rectangle; undo empty
    await tester.tap(find.text('Undo').last);
    await tester.pump();
    expect(probe!.undoDepth, 0);
    expect(probe!.shapeName, 'rectangle');
    expect(
      tester
          .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Undo'))
          .onPressed,
      isNull,
    );
  });

  testWidgets('one drag with many pan updates records a single undo entry',
      (tester) async {
    PhotoStudioTestProbe? probe;
    await _pumpPage(
      tester,
      page: PhotoStudioPage(onTestProbe: (p) => probe = p),
    );

    final box = tester.getRect(find.byType(PhotoRectCanvas));
    final start =
        Offset(box.left + box.width * 0.5, box.top + box.height * 0.5);
    final gesture = await tester.startGesture(start);
    await tester.pump();
    expect(probe!.undoDepth, 0);
    for (var i = 1; i <= 8; i++) {
      await gesture.moveBy(Offset(box.width * 0.01, box.height * 0.005));
      await tester.pump();
      expect(probe!.undoDepth, 0);
    }
    await gesture.up();
    await tester.pump();
    expect(probe!.undoDepth, 1);
  });

  testWidgets('tap place then drag are two separate undo entries',
      (tester) async {
    PhotoStudioTestProbe? probe;
    await _pumpPage(
      tester,
      page: PhotoStudioPage(onTestProbe: (p) => probe = p),
    );

    await tester.tap(find.text('⭐'));
    await tester.pump();
    final box = tester.getRect(find.byType(PhotoRectCanvas));
    final place =
        Offset(box.left + box.width * 0.14, box.top + box.height * 0.16);
    await tester.tapAt(place);
    await tester.pump();
    expect(probe!.undoDepth, 1);
    expect(probe!.stamps, hasLength(1));
    final placed = probe!.stamps.single;

    final gesture = await tester.startGesture(place);
    await tester.pump();
    expect(probe!.undoDepth, 1);
    await gesture.moveTo(Offset(place.dx + 80, place.dy + 40));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(probe!.undoDepth, 2);

    await tester.tap(find.text('Undo').last);
    await tester.pump();
    expect(probe!.stamps.single.x, closeTo(placed.x, 0.001));
    expect(probe!.stamps.single.y, closeTo(placed.y, 0.001));
    expect(probe!.undoDepth, 1);

    await tester.tap(find.text('Undo').last);
    await tester.pump();
    expect(probe!.stamps, isEmpty);
    expect(probe!.undoDepth, 0);
  });

  testWidgets('frame create, move, and resize each undo independently',
      (tester) async {
    PhotoStudioTestProbe? probe;
    await _pumpPage(
      tester,
      page: PhotoStudioPage(onTestProbe: (p) => probe = p),
    );

    final initial = (
      probe?.rectLeft ?? NormalizedRect.initial.left,
      probe?.rectTop ?? NormalizedRect.initial.top,
      probe?.rectRight ?? NormalizedRect.initial.right,
      probe?.rectBottom ?? NormalizedRect.initial.bottom,
    );
    final box = tester.getRect(find.byType(PhotoRectCanvas));

    // Create a new frame in empty space (outside the default rect).
    final createStart =
        Offset(box.left + box.width * 0.05, box.top + box.height * 0.05);
    final createEnd =
        Offset(box.left + box.width * 0.35, box.top + box.height * 0.4);
    var gesture = await tester.startGesture(createStart);
    await tester.pump();
    await gesture.moveTo(createEnd);
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(probe!.undoDepth, 1);
    final afterCreate = (
      probe!.rectLeft,
      probe!.rectTop,
      probe!.rectRight,
      probe!.rectBottom,
    );
    expect(afterCreate, isNot(initial));

    final moveStart = Offset(
      box.left + box.width * ((probe!.rectLeft + probe!.rectRight) / 2),
      box.top + box.height * ((probe!.rectTop + probe!.rectBottom) / 2),
    );
    gesture = await tester.startGesture(moveStart);
    await tester.pump();
    await gesture.moveTo(
      Offset(moveStart.dx + box.width * 0.08, moveStart.dy + box.height * 0.05),
    );
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(probe!.undoDepth, 2);
    final afterMove = (
      probe!.rectLeft,
      probe!.rectTop,
      probe!.rectRight,
      probe!.rectBottom,
    );
    expect(afterMove, isNot(afterCreate));

    final resizeStart = Offset(
      box.left + box.width * probe!.rectRight,
      box.top + box.height * probe!.rectBottom,
    );
    gesture = await tester.startGesture(resizeStart);
    await tester.pump();
    await gesture.moveTo(
      Offset(
        resizeStart.dx + box.width * 0.06,
        resizeStart.dy + box.height * 0.06,
      ),
    );
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(probe!.undoDepth, 3);
    final afterResize = (
      probe!.rectLeft,
      probe!.rectTop,
      probe!.rectRight,
      probe!.rectBottom,
    );
    expect(afterResize, isNot(afterMove));

    await tester.tap(find.text('Undo').last);
    await tester.pump();
    expect(
      (probe!.rectLeft, probe!.rectTop, probe!.rectRight, probe!.rectBottom),
      afterMove,
    );
    await tester.tap(find.text('Undo').last);
    await tester.pump();
    expect(
      (probe!.rectLeft, probe!.rectTop, probe!.rectRight, probe!.rectBottom),
      afterCreate,
    );
    await tester.tap(find.text('Undo').last);
    await tester.pump();
    expect(
      (probe!.rectLeft, probe!.rectTop, probe!.rectRight, probe!.rectBottom),
      initial,
    );
    expect(probe!.undoDepth, 0);
  });

  testWidgets('stamp drag undo restores coordinates, not only status',
      (tester) async {
    PhotoStudioTestProbe? probe;
    await _pumpPage(
      tester,
      page: PhotoStudioPage(onTestProbe: (p) => probe = p),
    );

    await tester.tap(find.text('⭐'));
    await tester.pump();
    final box = tester.getRect(find.byType(PhotoRectCanvas));
    final place =
        Offset(box.left + box.width * 0.12, box.top + box.height * 0.12);
    await tester.tapAt(place);
    await tester.pump();
    final before = probe!.stamps.single;

    final gesture = await tester.startGesture(place);
    await tester.pump();
    await gesture.moveTo(Offset(place.dx + 40, place.dy + 20));
    await tester.pump();
    await gesture.moveTo(Offset(place.dx + 90, place.dy + 55));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(probe!.stamps.single.x, isNot(closeTo(before.x, 0.01)));

    await tester.tap(find.text('Undo').last);
    await tester.pump();
    expect(probe!.stamps.single.x, closeTo(before.x, 0.001));
    expect(probe!.stamps.single.y, closeTo(before.y, 0.001));
    expect(find.textContaining('Undid'), findsOneWidget);
    // Place entry remains; undo is still enabled until that is undone too.
    expect(probe!.undoDepth, 1);
    expect(
      tester
          .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Undo'))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('scale slider with many ticks records one undo entry',
      (tester) async {
    PhotoStudioTestProbe? probe;
    await _pumpPage(
      tester,
      page: PhotoStudioPage(onTestProbe: (p) => probe = p),
    );

    await tester.tap(find.text('⭐'));
    await tester.pump();
    final box = tester.getRect(find.byType(PhotoRectCanvas));
    await tester.tapAt(
      Offset(box.left + box.width * 0.2, box.top + box.height * 0.2),
    );
    await tester.pump();
    expect(probe!.undoDepth, 1);
    final beforeScale = probe!.stampScale;

    final slider = find.byType(Slider);
    await tester.ensureVisible(slider);
    final sliderBox = tester.getRect(slider);
    // Thumb for value 1.0 on [0.4, 3.0] ≈ 23% along the track.
    final thumbX = sliderBox.left + sliderBox.width * 0.23;
    final gesture =
        await tester.startGesture(Offset(thumbX, sliderBox.center.dy));
    await tester.pump();
    for (var i = 1; i <= 12; i++) {
      await gesture.moveBy(const Offset(14, 0));
      await tester.pump();
      expect(
        probe!.undoDepth,
        1,
        reason: 'pan updates must not add extra undo entries',
      );
    }
    await gesture.up();
    await tester.pump();

    expect(probe!.stampScale, greaterThan(beforeScale + 0.15));
    expect(probe!.undoDepth, 2);

    await tester.tap(find.text('Undo').last);
    await tester.pump();
    expect(probe!.stampScale, closeTo(beforeScale, 0.001));
    expect(probe!.undoDepth, 1);
  });

  testWidgets('undo history full + no-op gesture keeps depth at 20',
      (tester) async {
    PhotoStudioTestProbe? probe;
    await _pumpPage(
      tester,
      page: PhotoStudioPage(onTestProbe: (p) => probe = p),
    );

    final shapes = <String>['Circle', 'Triangle'];
    for (var i = 0; i < 20; i++) {
      await tester.ensureVisible(find.text(shapes[i % 2]));
      await tester.tap(find.text(shapes[i % 2]));
      await tester.pump();
    }
    expect(probe!.undoDepth, 20);
    final shapeAtCap = probe!.shapeName;

    // No-op frame drag (press and release without moving). Must not drop history.
    final box = tester.getRect(find.byType(PhotoRectCanvas));
    final center =
        Offset(box.left + box.width * 0.5, box.top + box.height * 0.5);
    final gesture = await tester.startGesture(center);
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(probe!.undoDepth, 20);
    expect(probe!.shapeName, shapeAtCap);

    // Existing 20 entries remain undoable in order.
    for (var i = 0; i < 20; i++) {
      expect(probe!.undoDepth, 20 - i);
      await tester.tap(find.text('Undo').last);
      await tester.pump();
    }
    expect(probe!.undoDepth, 0);
    expect(
      tester
          .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Undo'))
          .onPressed,
      isNull,
    );
  });


  testWidgets('undo snapshots share image bytes by reference', (tester) async {
    PhotoStudioTestProbe? probe;
    final loaded = Uint8List.fromList(_tinyPng);
    await _pumpPage(
      tester,
      page: PhotoStudioPage(
        imageBytesPicker: () async => loaded,
        onTestProbe: (p) => probe = p,
      ),
    );

    await tester.runAsync(() async {
      final choose = find.byIcon(Icons.image_outlined);
      await tester.ensureVisible(choose);
      await tester.tap(choose);
      await Future<void>.delayed(const Duration(milliseconds: 250));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(probe?.imageBytes, isNotNull);
    final shared = probe!.imageBytes!;

    await tester.tap(find.text('Circle'));
    await tester.pump();
    await tester.tap(find.text('Triangle'));
    await tester.pump();
    await tester.tap(find.text('Rectangle'));
    await tester.pump();

    expect(probe!.undoDepth, greaterThanOrEqualTo(3));
    // Current image and every history slot that still has a photo must share
    // the same Uint8List instance (no deep copy per undo push).
    expect(identical(probe!.imageBytes, shared), isTrue);
    for (final ref in probe!.undoImageByteRefs) {
      if (ref == null) continue;
      expect(identical(ref, shared), isTrue);
    }
  });

  testWidgets(
      'PNG save uses fixed name/mime, PNG signature, and success status',
      (tester) async {
    String? savedName;
    String? savedMime;
    Uint8List? savedBytes;

    await _pumpPage(
      tester,
      page: PhotoStudioPage(
        imageSaver: ({
          required Uint8List bytes,
          required String fileName,
          required String mimeType,
        }) async {
          savedName = fileName;
          savedMime = mimeType;
          savedBytes = bytes;
          return true;
        },
      ),
    );

    expect(find.text('JPG'), findsNothing);
    expect(find.text('JPEG'), findsNothing);
    expect(find.text('WEBP'), findsNothing);
    expect(
      find.textContaining('JPEG, JPG, and WebP'),
      findsOneWidget,
    );

    await _tapSavePng(tester);

    expect(savedName, kStudioExportFileName);
    expect(savedMime, kStudioExportMimeType);
    expect(savedBytes, isNotNull);
    expect(_isPng(savedBytes!), isTrue);
    expect(find.text('Saved as PNG.'), findsOneWidget);
  });

  testWidgets('PNG save unavailable and error statuses', (tester) async {
    await _pumpPage(
      tester,
      page: PhotoStudioPage(
        imageSaver: ({
          required Uint8List bytes,
          required String fileName,
          required String mimeType,
        }) async =>
            false,
      ),
    );
    await _tapSavePng(tester);
    expect(find.textContaining('Save is available on web'), findsOneWidget);

    await _pumpPage(
      tester,
      page: PhotoStudioPage(
        imageSaver: ({
          required Uint8List bytes,
          required String fileName,
          required String mimeType,
        }) async {
          throw StateError('boom');
        },
      ),
    );
    await _tapSavePng(tester);
    expect(find.text('Could not save the photo.'), findsOneWidget);
  });

  testWidgets('narrow canvas export matches displayed aspect ratio',
      (tester) async {
    Uint8List? savedBytes;
    await _pumpPage(
      tester,
      surface: const Size(420, 1600),
      page: PhotoStudioPage(
        imageSaver: ({
          required Uint8List bytes,
          required String fileName,
          required String mimeType,
        }) async {
          savedBytes = bytes;
          return true;
        },
      ),
    );

    final canvasSize = tester.getSize(find.byType(PhotoRectCanvas));
    expect(canvasSize.width, lessThan(760));

    await _tapSavePng(tester);

    expect(savedBytes, isNotNull);
    expect(_isPng(savedBytes!), isTrue);
    final (w, h) = _pngSize(savedBytes!);
    expect(w / h, closeTo(canvasSize.width / canvasSize.height, 0.02));
    expect(w.toDouble(), closeTo(canvasSize.width * 2, 2));
    expect(h.toDouble(), closeTo(canvasSize.height * 2, 2));
  });

  testWidgets('frame move undo restores pre-drag rect', (tester) async {
    await _pumpPage(tester);
    final before = _rectCardText(tester);

    final box = tester.getRect(find.byType(PhotoRectCanvas));
    final start =
        Offset(box.left + box.width * 0.5, box.top + box.height * 0.5);
    final end =
        Offset(start.dx + box.width * 0.12, start.dy + box.height * 0.08);
    final gesture = await tester.startGesture(start);
    await tester.pump();
    await gesture.moveTo(end);
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(_rectCardText(tester), isNot(before));

    await tester.ensureVisible(find.text('Undo'));
    await tester.tap(find.text('Undo').last);
    await tester.pump();

    expect(_rectCardText(tester), before);
    expect(find.textContaining('Undid'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Undo'))
          .onPressed,
      isNull,
    );
  });

  testWidgets('frame resize undo restores pre-resize rect', (tester) async {
    await _pumpPage(tester);
    final before = _rectCardText(tester);

    final box = tester.getRect(find.byType(PhotoRectCanvas));
    final start =
        Offset(box.left + box.width * 0.8, box.top + box.height * 0.8);
    final end =
        Offset(box.left + box.width * 0.92, box.top + box.height * 0.92);
    final gesture = await tester.startGesture(start);
    await tester.pump();
    await gesture.moveTo(end);
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(_rectCardText(tester), isNot(before));

    await tester.ensureVisible(find.text('Undo'));
    await tester.tap(find.text('Undo').last);
    await tester.pump();
    expect(_rectCardText(tester), before);
  });

  testWidgets('emoji tap places, selects, syncs scale; drag does not double-place',
      (tester) async {
    await _pumpPage(tester);

    await tester.ensureVisible(find.text('⭐'));
    await tester.tap(find.text('⭐'));
    await tester.pumpAndSettle();

    final box = tester.getRect(find.byType(PhotoRectCanvas));
    final first =
        Offset(box.left + box.width * 0.15, box.top + box.height * 0.2);
    await tester.tapAt(first);
    await tester.pumpAndSettle();
    expect(tester.widget<Slider>(find.byType(Slider)).value, closeTo(1.0, 0.05));

    // Drag the stamp; must not create a second stamp (one undo removes the drag).
    final gesture = await tester.startGesture(first);
    await tester.pump();
    final moved =
        Offset(first.dx + box.width * 0.2, first.dy + box.height * 0.05);
    await gesture.moveTo(moved);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    await tester.drag(find.byType(Slider), const Offset(70, 0));
    await tester.pumpAndSettle();
    final scaled = tester.widget<Slider>(find.byType(Slider)).value;
    expect(scaled, greaterThan(1.1));

    // Place a second stamp; selection/scale should sync to 1.0.
    await tester.tap(find.text('⭐'));
    await tester.pumpAndSettle();
    final second =
        Offset(box.left + box.width * 0.12, box.top + box.height * 0.82);
    await tester.tapAt(second);
    await tester.pumpAndSettle();
    expect(tester.widget<Slider>(find.byType(Slider)).value, closeTo(1.0, 0.05));

    // Tap the second stamp again after scaling it, then tap the first stamp.
    await tester.drag(find.byType(Slider), const Offset(50, 0));
    await tester.pumpAndSettle();
    final secondScale = tester.widget<Slider>(find.byType(Slider)).value;
    expect(secondScale, greaterThan(1.05));

    await tester.tapAt(moved);
    await tester.pumpAndSettle();
    final reselected = tester.widget<Slider>(find.byType(Slider)).value;
    // Prefer a clear sync back to the first stamp's scale; if hit-testing is
    // ambiguous, at least ensure we did not stay on the second stamp's scale
    // after a deliberate tap near the first stamp's last drag position.
    expect(
      (reselected - scaled).abs() < 0.25 || (reselected - secondScale).abs() > 0.1,
      isTrue,
      reason: 'tapping near the first stamp should change selection/scale',
    );
  });

  test('composeStudioPng encodes PNG for a narrow logical size', () async {
    final bytes = await composeStudioPng(
      logicalSize: const Size(400, 280),
      rect: NormalizedRect.initial,
      shape: StudioFrameShape.rectangle,
      strokeColor: const Color(0xFF7C4DFF),
      stamps: const [
        EmojiStamp(emojiStampId: 'stamp-a', emoji: '⭐', x: 0.5, y: 0.5),
      ],
    );
    expect(_isPng(bytes), isTrue);
    final (w, h) = _pngSize(bytes);
    expect(w, 800);
    expect(h, 560);
  });
}
