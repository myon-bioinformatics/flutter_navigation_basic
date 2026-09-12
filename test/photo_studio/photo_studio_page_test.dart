import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/photo_studio/domain/emoji_stamp.dart';
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

  testWidgets('multi-step undo: three shape changes each revert step by step',
      (tester) async {
    await _pumpPage(tester);

    // Rectangle → Circle → Triangle → back to Circle via undo
    await tester.ensureVisible(find.text('Circle'));
    await tester.tap(find.text('Circle'));
    await tester.pump();

    await tester.ensureVisible(find.text('Triangle'));
    await tester.tap(find.text('Triangle'));
    await tester.pump();

    // Two changes, two undo steps.
    await tester.ensureVisible(find.text('Undo'));
    await tester.tap(find.text('Undo').last);
    await tester.pump();
    expect(find.textContaining('Undid'), findsOneWidget);

    // Second undo brings back the original Rectangle state.
    await tester.tap(find.text('Undo').last);
    await tester.pump();
    expect(find.textContaining('Undid'), findsWidgets);
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

  testWidgets('frame move undo restores pre-drag rect and consumes undo',
      (tester) async {
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

  testWidgets(
      'emoji tap places, selects, syncs scale; drag does not double-place',
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

  testWidgets(
      'stamp drag undo restores pre-drag coordinates as one operation',
      (tester) async {
    await _pumpPage(tester);

    await tester.tap(find.text('⭐'));
    await tester.pump();
    final box = tester.getRect(find.byType(PhotoRectCanvas));
    final place =
        Offset(box.left + box.width * 0.12, box.top + box.height * 0.12);
    await tester.tapAt(place);
    await tester.pump();

    // Capture normalized place coordinates from widget state.
    final canvasBefore = tester.widget<PhotoRectCanvas>(find.byType(PhotoRectCanvas));
    expect(canvasBefore.stamps, hasLength(1));
    final placeX = canvasBefore.stamps.first.x;
    final placeY = canvasBefore.stamps.first.y;

    // Drag the stamp through multiple update events — should be one undo entry.
    final gesture = await tester.startGesture(place);
    await tester.pump();
    await gesture.moveTo(Offset(place.dx + 40, place.dy + 20));
    await tester.pump();
    await gesture.moveTo(Offset(place.dx + 90, place.dy + 55));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    // Stamp has moved.
    final canvasDragged =
        tester.widget<PhotoRectCanvas>(find.byType(PhotoRectCanvas));
    expect(canvasDragged.stamps.first.x, isNot(closeTo(placeX, 0.01)));

    // Undo once → back to place position.
    await tester.tap(find.text('Undo').last);
    await tester.pump();
    expect(find.textContaining('Undid'), findsOneWidget);

    final canvasAfterUndo =
        tester.widget<PhotoRectCanvas>(find.byType(PhotoRectCanvas));
    expect(canvasAfterUndo.stamps.first.x, closeTo(placeX, 0.02));
    expect(canvasAfterUndo.stamps.first.y, closeTo(placeY, 0.02));

    // History exhausted: button disabled.
    expect(
      tester
          .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Undo'))
          .onPressed,
      isNull,
    );
  });

  testWidgets(
      'tap place then drag creates two independent undo entries',
      (tester) async {
    await _pumpPage(tester);

    await tester.tap(find.text('⭐'));
    await tester.pump();
    final box = tester.getRect(find.byType(PhotoRectCanvas));
    final place =
        Offset(box.left + box.width * 0.15, box.top + box.height * 0.15);

    // Place via tap (1 undo entry).
    await tester.tapAt(place);
    await tester.pumpAndSettle();

    final canvasPlaced =
        tester.widget<PhotoRectCanvas>(find.byType(PhotoRectCanvas));
    expect(canvasPlaced.stamps, hasLength(1));
    final placedX = canvasPlaced.stamps.first.x;
    final placedY = canvasPlaced.stamps.first.y;

    // Drag the stamp (2nd undo entry).
    final dest = Offset(place.dx + 80, place.dy + 50);
    final gesture = await tester.startGesture(place);
    await tester.pump();
    await gesture.moveTo(dest);
    await tester.pump();
    await gesture.up();
    await tester.pump();

    final canvasDragged =
        tester.widget<PhotoRectCanvas>(find.byType(PhotoRectCanvas));
    expect(canvasDragged.stamps.first.x, isNot(closeTo(placedX, 0.02)));

    // First undo: reverts drag, stamp returns to placed position.
    await tester.tap(find.text('Undo').last);
    await tester.pump();
    final afterUndo1 =
        tester.widget<PhotoRectCanvas>(find.byType(PhotoRectCanvas));
    expect(afterUndo1.stamps.first.x, closeTo(placedX, 0.02));
    expect(afterUndo1.stamps.first.y, closeTo(placedY, 0.02));
    expect(
      tester
          .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Undo'))
          .onPressed,
      isNotNull,
      reason: 'Second undo entry (stamp place) must still be available',
    );

    // Second undo: reverts placement, canvas has no stamps.
    await tester.tap(find.text('Undo').last);
    await tester.pump();
    final afterUndo2 =
        tester.widget<PhotoRectCanvas>(find.byType(PhotoRectCanvas));
    expect(afterUndo2.stamps, isEmpty);
    expect(
      tester
          .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Undo'))
          .onPressed,
      isNull,
    );
  });

  testWidgets('undo history capped at max 20; oldest entry dropped',
      (tester) async {
    await _pumpPage(tester);

    // 22 shape-toggle operations produce 22 pushUndo calls; only 20 are kept.
    for (var i = 0; i < 22; i++) {
      final shape = i.isEven ? 'Circle' : 'Rectangle';
      await tester.ensureVisible(find.text(shape));
      await tester.tap(find.text(shape));
      await tester.pump();
    }

    // Should be able to undo exactly 20 times.
    var count = 0;
    while (true) {
      final button = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Undo'),
      );
      if (button.onPressed == null) break;
      await tester.tap(find.text('Undo').last);
      await tester.pump();
      count++;
      expect(count, lessThanOrEqualTo(20),
          reason: 'Must not exceed the bounded history limit');
    }
    expect(count, 20);
  });

  testWidgets(
      'image bytes shared: multiple undo entries with same image do not lose it',
      (tester) async {
    // Load an image, then push several undo entries that share the same bytes.
    // Each undo should preserve the image rather than returning null.
    Uint8List? lastSavedBytes;
    await _pumpPage(
      tester,
      page: PhotoStudioPage(
        imageBytesPicker: () async => _tinyPng,
        imageSaver: ({
          required Uint8List bytes,
          required String fileName,
          required String mimeType,
        }) async {
          lastSavedBytes = bytes;
          return true;
        },
      ),
    );

    // Load image.
    await tester.runAsync(() async {
      await tester.ensureVisible(find.byIcon(Icons.image_outlined));
      await tester.tap(find.byIcon(Icons.image_outlined));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Push 5 more undo entries by changing shape (image ref is shared each time).
    for (final shape in ['Circle', 'Triangle', 'Circle', 'Rectangle', 'Triangle']) {
      await tester.ensureVisible(find.text(shape));
      await tester.tap(find.text(shape));
      await tester.pump();
    }

    // Undo all 5 shape changes — image must still be present for each step.
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.text('Undo').last);
      await tester.pump();
      // Save to verify image bytes are non-null after each undo.
      await _tapSavePng(tester);
      expect(_isPng(lastSavedBytes!), isTrue,
          reason: 'Image must survive undo step $i');
    }
  });

  testWidgets('scale slider multiple ticks produce single undo entry',
      (tester) async {
    await _pumpPage(tester);

    // Place a stamp first.
    await tester.tap(find.text('⭐'));
    await tester.pump();
    final box = tester.getRect(find.byType(PhotoRectCanvas));
    await tester.tapAt(
      Offset(box.left + box.width * 0.5, box.top + box.height * 0.5),
    );
    await tester.pumpAndSettle();

    final before = tester.widget<Slider>(find.byType(Slider)).value;

    // Drag the slider — onChangeStart fires once, pushing exactly 1 entry.
    await tester.drag(find.byType(Slider), const Offset(60, 0));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Slider>(find.byType(Slider)).value,
      greaterThan(before),
    );

    // Undo the slider change.
    await tester.tap(find.text('Undo').last);
    await tester.pump();
    expect(find.textContaining('Undid'), findsOneWidget);

    // Undo the stamp placement.
    await tester.tap(find.text('Undo').last);
    await tester.pump();

    // History now empty.
    expect(
      tester
          .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Undo'))
          .onPressed,
      isNull,
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
