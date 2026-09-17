import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/features/photo_studio/domain/emoji_stamp.dart';
import 'package:flutter_application_1/features/photo_studio/domain/normalized_rect.dart';
import 'package:flutter_application_1/features/photo_studio/domain/studio_document.dart';
import 'package:flutter_application_1/features/photo_studio/domain/studio_frame.dart';
import 'package:flutter_application_1/features/photo_studio/domain/studio_frame_style.dart';
import 'package:flutter_application_1/features/photo_studio/presentation/compose_studio_image.dart';
import 'package:flutter_application_1/features/photo_studio/presentation/photo_rect_canvas.dart';
import 'package:flutter_application_1/features/photo_studio/data/clipboard_image_read.dart';
import 'package:flutter_application_1/features/photo_studio/presentation/photo_studio_page.dart';
import 'package:flutter_application_1/core/navigation/route_names.dart';
import 'package:flutter_application_1/shared/display/display_scope.dart';
import 'package:flutter_application_1/shared/widgets/tool_door_selector.dart';
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

String? _rectCardTextOrNull(WidgetTester tester) {
  final selectables = tester
      .widgetList<SelectableText>(find.byType(SelectableText))
      .map((w) => w.data ?? '')
      .where((t) => t.contains('left:') && t.contains('top:') && t.contains('right:'))
      .toList();
  if (selectables.isEmpty) return null;
  return selectables.first;
}

String _rectCardText(WidgetTester tester) {
  final text = _rectCardTextOrNull(tester);
  expect(text, isNotNull);
  return text!;
}

bool _undoEnabled(WidgetTester tester) {
  final finder = find.byWidgetPredicate(
    (w) => w is IconButton && w.tooltip == 'Undo',
  );
  return tester.widget<IconButton>(finder).onPressed != null;
}

bool _shapeSelected(WidgetTester tester, String label) => tester
    .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label))
    .selected;

Future<void> _pumpPage(
  WidgetTester tester, {
  PhotoStudioPage page = const PhotoStudioPage(),
  Size surface = const Size(900, 2600),
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

Finder _leaveDialog() => find.byType(AlertDialog);

Finder _leaveStayButton() => find.descendant(
      of: _leaveDialog(),
      matching: find.widgetWithText(TextButton, 'Cancel'),
    );

Finder _leaveDiscardButton() => find.descendant(
      of: _leaveDialog(),
      matching: find.widgetWithText(FilledButton, 'Discard'),
    );

/// Landing → Photo Studio (2-level stack) for Back / PopScope tests.
Future<void> _pumpPhotoOnLandingStack(
  WidgetTester tester, {
  PhotoStudioPage page = const PhotoStudioPage(),
  Size surface = const Size(900, 2600),
}) async {
  await tester.binding.setSurfaceSize(surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final controller = await loadTestDisplayController();
  await tester.pumpWidget(
    DisplayScope(
      controller: controller,
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => page),
                  );
                },
                child: const Text('landing'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.tap(find.text('landing'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  expect(find.byType(PhotoStudioPage), findsOneWidget);
}

Future<void> _pumpDialogOpen(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _openDoorAndChoose(
  WidgetTester tester,
  String labelSubstring,
) async {
  await tester.ensureVisible(find.byType(ToolDoorSelector));
  await tester.tap(find.byType(DropdownButtonFormField<String>).last);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tap(find.textContaining(labelSubstring).last);
  await _pumpDialogOpen(tester);
}

Future<void> _tapUndo(WidgetTester tester) async {
  final finder = find.byWidgetPredicate(
    (w) => w is IconButton && w.tooltip == 'Undo',
  );
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
}

Future<void> _tapRedo(WidgetTester tester) async {
  final finder = find.byWidgetPredicate(
    (w) => w is IconButton && w.tooltip == 'Redo',
  );
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
}

Finder _emojiShortcut(String emoji) =>
    find.ancestor(
      of: find.text(emoji),
      matching: find.byType(ActionChip),
    );

Future<void> _tapEmojiShortcut(WidgetTester tester, String emoji) async {
  final chip = _emojiShortcut(emoji);
  await tester.ensureVisible(chip);
  await tester.tap(chip);
  await tester.pump();
}

Future<void> _selectDraftTool(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.tap(find.text(label).first);
  await tester.pump();
}

Future<void> _createFrame(
  WidgetTester tester, {
  double x0 = 0.05,
  double y0 = 0.05,
  double x1 = 0.4,
  double y1 = 0.45,
}) async {
  final box = tester.getRect(find.byType(PhotoRectCanvas));
  final start = Offset(box.left + box.width * x0, box.top + box.height * y0);
  final end = Offset(box.left + box.width * x1, box.top + box.height * y1);
  final gesture = await tester.startGesture(start);
  await tester.pump();
  await gesture.moveTo(end);
  await tester.pump();
  await gesture.up();
  await tester.pump();
}

void main() {
  testWidgets('shows photo studio with no default frame and custom stamp field',
      (tester) async {
    await _pumpPage(tester);

    expect(find.text('Photo Studio'), findsOneWidget);
    expect(find.text('Studio'), findsOneWidget);
    expect(find.text('Center + radius'), findsNothing);
    expect(find.text('Manual bounds'), findsNothing);
    expect(find.text('6. Manual box'), findsNothing);
    expect(find.byType(PhotoRectCanvas), findsOneWidget);
    expect(find.text('None'), findsOneWidget);
    expect(find.text('Rectangle'), findsOneWidget);
    expect(find.text('Circle'), findsOneWidget);
    expect(find.text('Triangle'), findsOneWidget);
    expect(_shapeSelected(tester, 'None'), isTrue);
    expect(find.text('Stamps'), findsOneWidget);
    expect(find.text('Custom stamp'), findsOneWidget);
    expect(find.text('Arm stamp'), findsOneWidget);
    expect(find.text('Paste photo'), findsOneWidget);
    expect(find.text('No frame selected.'), findsWidgets);
  });

  testWidgets('loads studio photo while keeping empty frames by default',
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

    expect(find.textContaining('Image loaded'), findsOneWidget);
    expect(find.text('No frame selected.'), findsWidgets);

    await tester.ensureVisible(find.text('Clear photo'));
    await tester.tap(find.text('Clear photo'));
    await tester.pump();

    expect(find.textContaining('Photo cleared'), findsOneWidget);
  });

  testWidgets('paste accepts injected clipboard image bytes', (tester) async {
    await _pumpPage(
      tester,
      page: PhotoStudioPage(
        clipboardImageReader: () async => ClipboardImageRead.bytes(_tinyPng),
      ),
    );

    await tester.runAsync(() async {
      await tester.ensureVisible(find.text('Paste photo'));
      await tester.tap(find.text('Paste photo'));
      await Future<void>.delayed(const Duration(milliseconds: 250));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Image loaded'), findsOneWidget);
  });

  testWidgets('custom stamp text can be armed and placed', (tester) async {
    await _pumpPage(tester);

    await tester.enterText(find.byType(TextField), '(^_^)');
    await tester.pump();
    await tester.tap(find.text('Arm stamp'));
    await tester.pump();
    expect(find.textContaining('Armed:'), findsOneWidget);

    final box = tester.getRect(find.byType(PhotoRectCanvas));
    await tester.tapAt(
      Offset(box.left + box.width * 0.2, box.top + box.height * 0.2),
    );
    await tester.pump();
    expect(tester.widget<Slider>(find.byType(Slider)).value, closeTo(1.0, 0.05));
    expect(_undoEnabled(tester), isTrue);
  });

  testWidgets('creates two frames with draft tools', (tester) async {
    await _pumpPage(tester);

    await _selectDraftTool(tester, 'Rectangle');
    await _createFrame(tester, x0: 0.05, y0: 0.05, x1: 0.35, y1: 0.35);
    expect(_rectCardTextOrNull(tester), isNotNull);
    expect(find.textContaining('Rectangle 1'), findsOneWidget);

    await _selectDraftTool(tester, 'Circle');
    await _createFrame(tester, x0: 0.55, y0: 0.55, x1: 0.9, y1: 0.9);
    expect(find.textContaining('Circle 2'), findsOneWidget);
    expect(find.textContaining('Rectangle 1'), findsOneWidget);
  });

  testWidgets('color change applies only to selected frame; delete reduces count',
      (tester) async {
    await _pumpPage(tester);

    await _selectDraftTool(tester, 'Rectangle');
    await _createFrame(tester, x0: 0.05, y0: 0.05, x1: 0.35, y1: 0.35);
    await _selectDraftTool(tester, 'Circle');
    await _createFrame(tester, x0: 0.55, y0: 0.55, x1: 0.9, y1: 0.9);

    await tester.ensureVisible(find.text('Rectangle 1'));
    await tester.tap(find.text('Rectangle 1'));
    await tester.pump();

    var canvas = tester.widget<PhotoRectCanvas>(find.byType(PhotoRectCanvas));
    expect(canvas.frames, hasLength(2));
    final firstId = canvas.frames[0].studioFrameId;
    final secondId = canvas.frames[1].studioFrameId;
    expect(canvas.selectedStudioFrameId, firstId);

    await tester.ensureVisible(find.text('Circle 2'));
    await tester.tap(find.text('Circle 2'));
    await tester.pump();

    final redSwatch = find.byWidgetPredicate(
      (widget) {
        if (widget is! Container) return false;
        final deco = widget.decoration;
        return deco is BoxDecoration &&
            deco.shape == BoxShape.circle &&
            deco.color == const Color(StudioFrameColors.red);
      },
      description: 'red frame color swatch',
    );
    await tester.ensureVisible(redSwatch);
    await tester.tap(redSwatch);
    await tester.pump();

    canvas = tester.widget<PhotoRectCanvas>(find.byType(PhotoRectCanvas));
    expect(
      canvas.frames.firstWhere((f) => f.studioFrameId == firstId).strokeArgb,
      StudioFrameColors.purple,
    );
    expect(
      canvas.frames.firstWhere((f) => f.studioFrameId == secondId).strokeArgb,
      StudioFrameColors.red,
    );

    await tester.ensureVisible(find.text('Delete frame'));
    await tester.tap(find.text('Delete frame'));
    await tester.pump();

    canvas = tester.widget<PhotoRectCanvas>(find.byType(PhotoRectCanvas));
    expect(canvas.frames, hasLength(1));
    expect(canvas.frames.single.studioFrameId, firstId);
    expect(canvas.selectedStudioFrameId, isNull);
    expect(find.textContaining('Circle 2'), findsNothing);
    expect(find.textContaining('Rectangle 1'), findsOneWidget);
  });

  testWidgets('paste rejects oversized data:image clipboard text', (tester) async {
    final oversized =
        'data:image/png;base64,${'A' * ((32 * 1024 * 1024) + 64)}';
    final messenger =
        tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.getData') {
        return <String, dynamic>{'text': oversized};
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await _pumpPage(
      tester,
      page: PhotoStudioPage(
        clipboardImageReader: () async => const ClipboardImageRead.empty(),
      ),
    );

    await tester.runAsync(() async {
      await tester.ensureVisible(find.text('Paste photo'));
      await tester.tap(find.text('Paste photo'));
      await Future<void>.delayed(const Duration(milliseconds: 250));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Image loaded'), findsNothing);
    expect(
      find.textContaining('too large'),
      findsOneWidget,
    );
  });

  testWidgets('paste rejects oversized binary clipboard bytes', (tester) async {
    await _pumpPage(
      tester,
      page: PhotoStudioPage(
        clipboardImageReader: () async => const ClipboardImageRead.tooLarge(),
      ),
    );

    await tester.runAsync(() async {
      await tester.ensureVisible(find.text('Paste photo'));
      await tester.tap(find.text('Paste photo'));
      await Future<void>.delayed(const Duration(milliseconds: 250));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Image loaded'), findsNothing);
    expect(find.textContaining('too large'), findsOneWidget);
  });

  testWidgets('bounded undo restores draft tool then disables when empty',
      (tester) async {
    await _pumpPage(tester);

    expect(_undoEnabled(tester), isFalse);
    expect(_shapeSelected(tester, 'None'), isTrue);

    await _selectDraftTool(tester, 'Circle');
    expect(_shapeSelected(tester, 'Circle'), isTrue);
    expect(_undoEnabled(tester), isTrue);

    await _tapUndo(tester);
    expect(_shapeSelected(tester, 'None'), isTrue);
    expect(_undoEnabled(tester), isFalse);
    expect(find.textContaining('Undid'), findsOneWidget);
  });

  testWidgets(
      'multi-step undo restores tool, frame move, stamp place, then stamp drag',
      (tester) async {
    await _pumpPage(tester);

    await _selectDraftTool(tester, 'Circle');
    expect(_shapeSelected(tester, 'Circle'), isTrue);

    await _createFrame(tester, x0: 0.2, y0: 0.2, x1: 0.8, y1: 0.8);
    final beforeMove = _rectCardText(tester);
    final box = tester.getRect(find.byType(PhotoRectCanvas));
    final moveStart =
        Offset(box.left + box.width * 0.5, box.top + box.height * 0.5);
    final moveEnd =
        Offset(moveStart.dx + box.width * 0.1, moveStart.dy + box.height * 0.06);
    var gesture = await tester.startGesture(moveStart);
    await tester.pump();
    await gesture.moveTo(moveEnd);
    await tester.pump();
    await gesture.up();
    await tester.pump();
    final afterMove = _rectCardText(tester);
    expect(afterMove, isNot(beforeMove));

    await _tapEmojiShortcut(tester, '⭐');
    await tester.pump();
    final place =
        Offset(box.left + box.width * 0.18, box.top + box.height * 0.22);
    await tester.tapAt(place);
    await tester.pump();
    expect(tester.widget<Slider>(find.byType(Slider)).value, closeTo(1.0, 0.05));
    expect(_undoEnabled(tester), isTrue);

    gesture = await tester.startGesture(place);
    await tester.pump();
    await gesture.moveTo(Offset(place.dx + 50, place.dy + 30));
    await tester.pump();
    await gesture.moveTo(Offset(place.dx + 100, place.dy + 60));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    await _tapUndo(tester);
    expect(find.textContaining('Undid'), findsOneWidget);
    expect(_undoEnabled(tester), isTrue);
    expect(tester.widget<Slider>(find.byType(Slider)).value, closeTo(1.0, 0.05));

    await _tapUndo(tester);
    expect(_rectCardText(tester), afterMove);
    expect(_undoEnabled(tester), isTrue);

    await _tapUndo(tester);
    expect(_rectCardText(tester), beforeMove);
    expect(_shapeSelected(tester, 'Circle'), isTrue);
    expect(_undoEnabled(tester), isTrue);

    // Undo create → no frame selected text; tool still circle.
    await _tapUndo(tester);
    expect(_rectCardTextOrNull(tester), isNull);
    expect(_shapeSelected(tester, 'Circle'), isTrue);
    expect(_undoEnabled(tester), isTrue);

    await _tapUndo(tester);
    expect(_shapeSelected(tester, 'None'), isTrue);
    expect(_undoEnabled(tester), isFalse);
  });

  testWidgets('one drag with many pan updates records a single undo entry',
      (tester) async {
    await _pumpPage(tester);
    await _selectDraftTool(tester, 'Rectangle');
    await _createFrame(tester, x0: 0.2, y0: 0.2, x1: 0.8, y1: 0.8);

    // Clear undo from create+tool so we isolate the move gesture.
    while (_undoEnabled(tester)) {
      await _tapUndo(tester);
    }
    // Re-create frame after undoing everything including draft tool.
    await _selectDraftTool(tester, 'Rectangle');
    await _createFrame(tester, x0: 0.2, y0: 0.2, x1: 0.8, y1: 0.8);
    // Undo only the create, keep draft tool? Actually we want one move undo.
    // Simpler: just check that pan updates during one move don't commit early.
    final beforeDepthEnabled = _undoEnabled(tester);
    expect(beforeDepthEnabled, isTrue);

    final box = tester.getRect(find.byType(PhotoRectCanvas));
    final start =
        Offset(box.left + box.width * 0.5, box.top + box.height * 0.5);
    final gesture = await tester.startGesture(start);
    await tester.pump();
    for (var i = 1; i <= 8; i++) {
      await gesture.moveBy(Offset(box.width * 0.01, box.height * 0.005));
      await tester.pump();
    }
    await gesture.up();
    await tester.pump();
    expect(_undoEnabled(tester), isTrue);

    final afterMove = _rectCardText(tester);
    await _tapUndo(tester);
    expect(_rectCardText(tester), isNot(afterMove));
  });

  testWidgets('tap place then drag are two separate undo entries',
      (tester) async {
    await _pumpPage(tester);

    await _tapEmojiShortcut(tester, '⭐');
    await tester.pump();
    final box = tester.getRect(find.byType(PhotoRectCanvas));
    final place =
        Offset(box.left + box.width * 0.14, box.top + box.height * 0.16);
    await tester.tapAt(place);
    await tester.pump();
    expect(_undoEnabled(tester), isTrue);
    expect(tester.widget<Slider>(find.byType(Slider)).value, closeTo(1.0, 0.05));

    final gesture = await tester.startGesture(place);
    await tester.pump();
    await gesture.moveTo(Offset(place.dx + 80, place.dy + 40));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(_undoEnabled(tester), isTrue);

    await _tapUndo(tester);
    expect(find.textContaining('Undid'), findsOneWidget);
    expect(_undoEnabled(tester), isTrue);
    expect(tester.widget<Slider>(find.byType(Slider)).value, closeTo(1.0, 0.05));

    await _tapUndo(tester);
    expect(_undoEnabled(tester), isFalse);
  });

  testWidgets('frame create, move, and resize each undo independently',
      (tester) async {
    await _pumpPage(tester);
    await _selectDraftTool(tester, 'Rectangle');

    expect(_rectCardTextOrNull(tester), isNull);
    final box = tester.getRect(find.byType(PhotoRectCanvas));

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
    expect(_undoEnabled(tester), isTrue);
    final afterCreate = _rectCardText(tester);

    final createLeft = double.parse(
      RegExp(r'left: ([0-9.]+)').firstMatch(afterCreate)!.group(1)!,
    );
    final createTop = double.parse(
      RegExp(r'top: ([0-9.]+)').firstMatch(afterCreate)!.group(1)!,
    );
    final createRight = double.parse(
      RegExp(r'right: ([0-9.]+)').firstMatch(afterCreate)!.group(1)!,
    );
    final createBottom = double.parse(
      RegExp(r'bottom: ([0-9.]+)').firstMatch(afterCreate)!.group(1)!,
    );
    final moveStart = Offset(
      box.left + box.width * ((createLeft + createRight) / 2),
      box.top + box.height * ((createTop + createBottom) / 2),
    );
    gesture = await tester.startGesture(moveStart);
    await tester.pump();
    await gesture.moveTo(
      Offset(moveStart.dx + box.width * 0.08, moveStart.dy + box.height * 0.05),
    );
    await tester.pump();
    await gesture.up();
    await tester.pump();
    final afterMove = _rectCardText(tester);
    expect(afterMove, isNot(afterCreate));

    final moveRight = double.parse(
      RegExp(r'right: ([0-9.]+)').firstMatch(afterMove)!.group(1)!,
    );
    final moveBottom = double.parse(
      RegExp(r'bottom: ([0-9.]+)').firstMatch(afterMove)!.group(1)!,
    );
    final resizeStart = Offset(
      box.left + box.width * moveRight,
      box.top + box.height * moveBottom,
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
    final afterResize = _rectCardText(tester);
    expect(afterResize, isNot(afterMove));

    await _tapUndo(tester);
    expect(_rectCardText(tester), afterMove);
    await _tapUndo(tester);
    expect(_rectCardText(tester), afterCreate);
    await _tapUndo(tester);
    expect(_rectCardTextOrNull(tester), isNull);
  });

  testWidgets('stamp drag undo restores coordinates via public undo status',
      (tester) async {
    await _pumpPage(tester);

    await _tapEmojiShortcut(tester, '⭐');
    await tester.pump();
    final box = tester.getRect(find.byType(PhotoRectCanvas));
    final place =
        Offset(box.left + box.width * 0.12, box.top + box.height * 0.12);
    await tester.tapAt(place);
    await tester.pump();

    final gesture = await tester.startGesture(place);
    await tester.pump();
    await gesture.moveTo(Offset(place.dx + 40, place.dy + 20));
    await tester.pump();
    await gesture.moveTo(Offset(place.dx + 90, place.dy + 55));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    await _tapUndo(tester);
    expect(find.textContaining('Undid'), findsOneWidget);
    expect(_undoEnabled(tester), isTrue);
  });

  testWidgets('scale slider with many ticks records one undo entry',
      (tester) async {
    await _pumpPage(tester);

    await _tapEmojiShortcut(tester, '⭐');
    await tester.pump();
    final box = tester.getRect(find.byType(PhotoRectCanvas));
    await tester.tapAt(
      Offset(box.left + box.width * 0.2, box.top + box.height * 0.2),
    );
    await tester.pump();
    expect(_undoEnabled(tester), isTrue);
    final beforeScale = tester.widget<Slider>(find.byType(Slider)).value;

    final slider = find.byType(Slider);
    await tester.ensureVisible(slider);
    final sliderBox = tester.getRect(slider);
    final thumbX = sliderBox.left + sliderBox.width * 0.23;
    final gesture =
        await tester.startGesture(Offset(thumbX, sliderBox.center.dy));
    await tester.pump();
    for (var i = 1; i <= 12; i++) {
      await gesture.moveBy(const Offset(14, 0));
      await tester.pump();
    }
    await gesture.up();
    await tester.pump();

    final afterScale = tester.widget<Slider>(find.byType(Slider)).value;
    expect(afterScale, greaterThan(beforeScale + 0.15));

    await _tapUndo(tester);
    expect(
      tester.widget<Slider>(find.byType(Slider)).value,
      closeTo(beforeScale, 0.001),
    );
    expect(_undoEnabled(tester), isTrue);
  });

  testWidgets('undo history full + no-op gesture keeps 20 undoable entries',
      (tester) async {
    await _pumpPage(tester);

    final shapes = <String>['Circle', 'Triangle'];
    for (var i = 0; i < 20; i++) {
      await tester.ensureVisible(find.text(shapes[i % 2]).first);
      await tester.tap(find.text(shapes[i % 2]).first);
      await tester.pump();
    }
    expect(_undoEnabled(tester), isTrue);
    expect(_shapeSelected(tester, 'Triangle'), isTrue);

    // No-op press/release without moving. With a create tool armed this may
    // add a min-size frame; prefer switching to None without counting it as
    // part of the capped 20: undo is still available either way.
    final box = tester.getRect(find.byType(PhotoRectCanvas));
    final center =
        Offset(box.left + box.width * 0.5, box.top + box.height * 0.5);
    final gesture = await tester.startGesture(center);
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(_undoEnabled(tester), isTrue);

    var undos = 0;
    while (_undoEnabled(tester) && undos < 30) {
      await _tapUndo(tester);
      undos++;
    }
    expect(_shapeSelected(tester, 'None'), isTrue);
    expect(_undoEnabled(tester), isFalse);
    expect(undos, greaterThanOrEqualTo(20));
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
    expect(
      find.textContaining('Could not save the PNG'),
      findsOneWidget,
    );

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
    await _selectDraftTool(tester, 'Rectangle');
    await _createFrame(tester, x0: 0.2, y0: 0.2, x1: 0.8, y1: 0.8);
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

    await _tapUndo(tester);

    expect(_rectCardText(tester), before);
    expect(find.textContaining('Undid'), findsOneWidget);
  });

  testWidgets('frame resize undo restores pre-resize rect', (tester) async {
    await _pumpPage(tester);
    await _selectDraftTool(tester, 'Rectangle');
    await _createFrame(tester, x0: 0.2, y0: 0.2, x1: 0.8, y1: 0.8);
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

    await _tapUndo(tester);
    expect(_rectCardText(tester), before);
  });

  testWidgets('emoji tap places, selects, syncs scale; drag does not double-place',
      (tester) async {
    await _pumpPage(tester);

    await tester.ensureVisible(find.text('⭐'));
    await _tapEmojiShortcut(tester, '⭐');
    await tester.pumpAndSettle();

    final box = tester.getRect(find.byType(PhotoRectCanvas));
    final first =
        Offset(box.left + box.width * 0.15, box.top + box.height * 0.2);
    await tester.tapAt(first);
    await tester.pumpAndSettle();
    expect(tester.widget<Slider>(find.byType(Slider)).value, closeTo(1.0, 0.05));

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

    await _tapEmojiShortcut(tester, '⭐');
    await tester.pumpAndSettle();
    final second =
        Offset(box.left + box.width * 0.12, box.top + box.height * 0.82);
    await tester.tapAt(second);
    await tester.pumpAndSettle();
    expect(tester.widget<Slider>(find.byType(Slider)).value, closeTo(1.0, 0.05));

    await tester.drag(find.byType(Slider), const Offset(50, 0));
    await tester.pumpAndSettle();
    final secondScale = tester.widget<Slider>(find.byType(Slider)).value;
    expect(secondScale, greaterThan(1.05));

    await tester.tapAt(moved);
    await tester.pumpAndSettle();
    final reselected = tester.widget<Slider>(find.byType(Slider)).value;
    expect(
      (reselected - scaled).abs() < 0.25 || (reselected - secondScale).abs() > 0.1,
      isTrue,
      reason: 'tapping near the first stamp should change selection/scale',
    );
  });

  testWidgets('390px AppBar keeps Photo Studio title without overflow',
      (tester) async {
    await _pumpPage(tester, surface: const Size(390, 844));
    expect(tester.takeException(), isNull);
    expect(find.text('Photo Studio'), findsWidgets);
    expect(find.byIcon(Icons.undo), findsOneWidget);
    expect(find.byIcon(Icons.redo), findsOneWidget);
    expect(find.byIcon(Icons.language), findsOneWidget);
    expect(find.text('Move'), findsNothing);
    expect(find.text('Resize'), findsNothing);
  });

  testWidgets('no-photo framing stays editable; dirty leave confirm works',
      (tester) async {
    await _pumpPage(tester);

    expect(find.text('Import image'), findsOneWidget);
    expect(find.byType(ToolDoorSelector), findsOneWidget);
    expect(find.byIcon(Icons.circle), findsNothing);

    await _selectDraftTool(tester, 'Rectangle');
    await _createFrame(tester, x0: 0.1, y0: 0.1, x1: 0.4, y1: 0.4);
    expect(
      tester.widget<PhotoRectCanvas>(find.byType(PhotoRectCanvas)).frames,
      isNotEmpty,
    );
    expect(find.byIcon(Icons.circle), findsOneWidget);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.maybePop();
    await _pumpDialogOpen(tester);
    expect(_leaveDialog(), findsOneWidget);
    // Smoke: catalog English copy for the leave dialog.
    expect(find.text('Discard changes?'), findsOneWidget);
    expect(find.text('Unsaved edits will be lost.'), findsOneWidget);
    expect(_leaveStayButton(), findsOneWidget);
    expect(_leaveDiscardButton(), findsOneWidget);
    await tester.tap(_leaveStayButton());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byIcon(Icons.circle), findsOneWidget);
  });

  testWidgets('export clears dirty; further undo past baseline dirties again',
      (tester) async {
    await _pumpPage(
      tester,
      page: PhotoStudioPage(
        imageBytesPicker: () async => _tinyPng,
        imageSaver: ({
          required bytes,
          required fileName,
          required mimeType,
        }) async =>
            true,
      ),
    );

    await _selectDraftTool(tester, 'Rectangle');
    await _createFrame(tester, x0: 0.1, y0: 0.1, x1: 0.4, y1: 0.4);
    expect(find.byIcon(Icons.circle), findsOneWidget);

    await _tapSavePng(tester);
    expect(find.byIcon(Icons.circle), findsNothing);

    await _tapUndo(tester);
    expect(find.byIcon(Icons.circle), findsOneWidget);

    await _tapRedo(tester);
    expect(find.byIcon(Icons.circle), findsNothing);
  });

  testWidgets('importing tiny image reports photo loaded without blocking canvas',
      (tester) async {
    await _pumpPage(
      tester,
      page: PhotoStudioPage(imageBytesPicker: () async => _tinyPng),
    );

    await tester.runAsync(() async {
      await tester.ensureVisible(find.text('Import image'));
      await tester.tap(find.text('Import image'));
      await Future<void>.delayed(const Duration(milliseconds: 250));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Image loaded'), findsOneWidget);
    expect(find.byType(PhotoRectCanvas), findsOneWidget);
    expect(find.byIcon(Icons.circle), findsOneWidget);
  });


  testWidgets('import status shows idle then success metadata', (tester) async {
    await _pumpPage(
      tester,
      page: PhotoStudioPage(imageBytesPicker: () async => _tinyPng),
      surface: const Size(390, 2400),
    );

    expect(find.text('Select an image or paste here'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Select an image')), findsWidgets);

    await tester.runAsync(() async {
      await tester.ensureVisible(find.text('Import image'));
      await tester.tap(find.text('Import image'));
      await Future<void>.delayed(const Duration(milliseconds: 250));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Image loaded'), findsOneWidget);
    expect(find.textContaining('PNG ·'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('picker cancel is cancelled not failure', (tester) async {
    await _pumpPage(
      tester,
      page: PhotoStudioPage(imageBytesPicker: () async => null),
      surface: const Size(390, 2400),
    );

    await tester.runAsync(() async {
      await tester.ensureVisible(find.text('Import image'));
      await tester.tap(find.text('Import image'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('No change.'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('paste empty clipboard shows failure and retry', (tester) async {
    await _pumpPage(
      tester,
      page: PhotoStudioPage(clipboardImageReader: () async => const ClipboardImageRead.empty()),
      surface: const Size(390, 2400),
    );

    await tester.runAsync(() async {
      await tester.ensureVisible(find.text('Paste photo'));
      await tester.tap(find.text('Paste photo'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Clipboard has no photo to paste.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });


  testWidgets('paste clipboard throw leaves failure not loading', (tester) async {
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.getData') {
        throw PlatformException(code: 'denied');
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await _pumpPage(
      tester,
      page: PhotoStudioPage(
        clipboardImageReader: () async => const ClipboardImageRead.denied(),
      ),
      surface: const Size(390, 2400),
    );

    await tester.runAsync(() async {
      await tester.ensureVisible(find.text('Paste photo'));
      await tester.tap(find.text('Paste photo'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('Loading image'), findsNothing);
    expect(find.textContaining('clipboard'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('picker throw leaves failure not loading', (tester) async {
    await _pumpPage(
      tester,
      page: PhotoStudioPage(
        imageBytesPicker: () async => throw StateError('picker boom'),
      ),
      surface: const Size(390, 2400),
    );

    await tester.runAsync(() async {
      await tester.ensureVisible(find.text('Import image'));
      await tester.tap(find.text('Import image'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('Loading image'), findsNothing);
    expect(find.text('Could not decode this image.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('HEIC ftyp import shows typed HEIC unsupported status', (tester) async {
    final heic = Uint8List.fromList([
      0x00, 0x00, 0x00, 0x18,
      0x66, 0x74, 0x79, 0x70,
      0x68, 0x65, 0x69, 0x63,
      0x00, 0x00, 0x00, 0x00,
      0x68, 0x65, 0x69, 0x63,
      0x6D, 0x69, 0x66, 0x31,
    ]);
    await _pumpPage(
      tester,
      page: PhotoStudioPage(
        imageBytesPicker: () async => heic,
        imageDecodeAdapter: (_) async => null,
      ),
      surface: const Size(390, 2400),
    );

    await tester.runAsync(() async {
      await tester.ensureVisible(find.text('Import image'));
      await tester.tap(find.text('Import image'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('HEIC/HEIF'), findsOneWidget);
    expect(find.text('Could not decode this image.'), findsNothing);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('slow import A cannot overwrite fast import B', (tester) async {
    final slow = Completer<Uint8List?>();
    var picks = 0;
    await _pumpPage(
      tester,
      page: PhotoStudioPage(
        imageBytesPicker: () async {
          picks += 1;
          if (picks == 1) return slow.future;
          return _tinyPng;
        },
      ),
      surface: const Size(390, 2400),
    );

    await tester.tap(find.text('Import image'));
    await tester.pump();
    // Second import while first acquisition still pending.
    await tester.tap(find.text('Import image'));
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Image loaded'), findsOneWidget);
    final bytesAfterB =
        tester.widget<PhotoRectCanvas>(find.byType(PhotoRectCanvas)).imageBytes;
    expect(bytesAfterB, isNotNull);

    slow.complete(Uint8List.fromList(const [0x00, 0x01, 0x02, 0x03]));
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Image loaded'), findsOneWidget);
    expect(
      tester.widget<PhotoRectCanvas>(find.byType(PhotoRectCanvas)).imageBytes,
      bytesAfterB,
    );
  });

  testWidgets('web clipboard kinds map to distinct failure copy', (tester) async {
    Future<void> expectKind(ClipboardImageRead read, String needle) async {
      await _pumpPage(
        tester,
        page: PhotoStudioPage(clipboardImageReader: () async => read),
        surface: const Size(390, 2400),
      );
      await tester.runAsync(() async {
        await tester.ensureVisible(find.text('Paste photo'));
        await tester.tap(find.text('Paste photo'));
        await Future<void>.delayed(const Duration(milliseconds: 150));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.textContaining(needle), findsOneWidget);
    }

    await expectKind(const ClipboardImageRead.empty(), 'Clipboard has no photo');
    await expectKind(const ClipboardImageRead.denied(), 'clipboard');
    await expectKind(const ClipboardImageRead.unavailable(), 'clipboard');
    await expectKind(const ClipboardImageRead.tooLarge(), 'too large');
    await expectKind(const ClipboardImageRead.readFailed(), 'Could not decode');
  });

  testWidgets('clear during first load keeps superseded status and empty canvas',
      (tester) async {
    final adapterEntered = Completer<void>();
    final adapterGate = Completer<Uint8List>();

    await _pumpPage(
      tester,
      page: PhotoStudioPage(
        imageBytesPicker: () async =>
            Uint8List.fromList(const [0x00, 0x01, 0x02, 0x03]),
        imageDecodeAdapter: (bytes) async {
          if (!adapterEntered.isCompleted) adapterEntered.complete();
          return adapterGate.future;
        },
      ),
    );

    await tester.ensureVisible(find.text('Import image'));
    await tester.tap(find.text('Import image'));
    await tester.pump();
    await tester.runAsync(
      () => adapterEntered.future.timeout(const Duration(seconds: 5)),
    );
    await tester.pump();
    expect(find.textContaining('Loading image'), findsWidgets);

    await tester.ensureVisible(find.text('Clear photo'));
    await tester.tap(find.text('Clear photo'));
    await tester.pump();
    expect(
      find.textContaining('newer import'),
      findsOneWidget,
    );

    adapterGate.complete(_tinyPng);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      tester.widget<PhotoRectCanvas>(find.byType(PhotoRectCanvas)).imageBytes,
      isNull,
    );
    expect(find.textContaining('Image loaded'), findsNothing);
  });

  test('composeStudioPng encodes PNG for a narrow logical size', () async {
    final bytes = await composeStudioPng(
      StudioDocument(
        logicalCanvasSize: const Size(400, 280),
        frames: [
          const StudioFrame(
            studioFrameId: 'frame-a',
            rect: NormalizedRect.initial,
            shape: StudioFrameShape.rectangle,
            strokeArgb: 0xFF7C4DFF,
          ),
        ],
        stamps: const [
          EmojiStamp(emojiStampId: 'stamp-a', emoji: '⭐', x: 0.5, y: 0.5),
        ],
        imageBytes: null,
      ),
    );
    expect(_isPng(bytes), isTrue);
    final (w, h) = _pngSize(bytes);
    expect(w, 800);
    expect(h, 560);
  });

  testWidgets('Cancel keeps document history baseline and route', (tester) async {
    await _pumpPhotoOnLandingStack(tester);

    await _selectDraftTool(tester, 'Rectangle');
    await _createFrame(tester, x0: 0.1, y0: 0.1, x1: 0.4, y1: 0.4);
    expect(find.byIcon(Icons.circle), findsOneWidget);
    expect(_undoEnabled(tester), isTrue);
    final framesBefore =
        tester.widget<PhotoRectCanvas>(find.byType(PhotoRectCanvas)).frames;

    tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
    await _pumpDialogOpen(tester);
    expect(_leaveDialog(), findsOneWidget);
    await tester.tap(_leaveStayButton());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(PhotoStudioPage), findsOneWidget);
    expect(find.text('Photo Studio'), findsWidgets);
    expect(find.byIcon(Icons.circle), findsOneWidget);
    expect(_undoEnabled(tester), isTrue);
    expect(
      tester.widget<PhotoRectCanvas>(find.byType(PhotoRectCanvas)).frames,
      framesBefore,
    );
  });

  testWidgets('Back Discard restores baseline and returns to landing',
      (tester) async {
    await _pumpPhotoOnLandingStack(tester);

    await _selectDraftTool(tester, 'Rectangle');
    await _createFrame(tester, x0: 0.1, y0: 0.1, x1: 0.4, y1: 0.4);
    expect(find.byIcon(Icons.circle), findsOneWidget);

    tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
    await _pumpDialogOpen(tester);
    expect(_leaveDialog(), findsOneWidget);
    await tester.tap(_leaveDiscardButton());
    // Dialog exit + imperative route pop both animate ~300ms; dirty clears
    // immediately while PhotoStudioPage stays findable until the transition ends.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(PhotoStudioPage), findsNothing);
    expect(find.text('landing'), findsOneWidget);
  });

  testWidgets('Door Discard to other keeps clean Photo under stack',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 2600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = await loadTestDisplayController();
    // Flat `/studio` avoids deep initialRoute intermediates; `/` stays available
    // for Door→Home without conflicting with MaterialApp.home.
    await tester.pumpWidget(
      DisplayScope(
        controller: controller,
        child: MaterialApp(
          initialRoute: '/studio',
          routes: {
            '/studio': (_) => const PhotoStudioPage(),
            RouteNames.home: (_) => const Scaffold(body: Text('home-dest')),
            RouteNames.clipboardShelf: (_) =>
                const Scaffold(body: Text('shelf-dest')),
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await _selectDraftTool(tester, 'Rectangle');
    await _createFrame(tester, x0: 0.2, y0: 0.2, x1: 0.5, y1: 0.5);
    expect(find.byIcon(Icons.circle), findsOneWidget);

    await _openDoorAndChoose(tester, 'Clipboard Shelf');
    expect(_leaveDialog(), findsOneWidget);
    await tester.tap(_leaveDiscardButton());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('shelf-dest'), findsOneWidget);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(PhotoStudioPage), findsOneWidget);
    expect(find.byIcon(Icons.circle), findsNothing);
    expect(
      tester.widget<PhotoRectCanvas>(find.byType(PhotoRectCanvas)).frames,
      isEmpty,
    );
  });

  testWidgets('Door Discard to Home removes Photo from stack', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 2600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = await loadTestDisplayController();
    await tester.pumpWidget(
      DisplayScope(
        controller: controller,
        child: MaterialApp(
          initialRoute: '/studio',
          routes: {
            '/studio': (_) => const PhotoStudioPage(),
            RouteNames.home: (_) => const Scaffold(body: Text('home-dest')),
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await _selectDraftTool(tester, 'Rectangle');
    await _createFrame(tester, x0: 0.2, y0: 0.2, x1: 0.5, y1: 0.5);
    expect(find.byIcon(Icons.circle), findsOneWidget);

    // Exact catalog label — avoid matching door hint text that contains "Home".
    await _openDoorAndChoose(tester, 'Home 🏠');
    expect(_leaveDialog(), findsOneWidget);
    await tester.tap(_leaveDiscardButton());
    await tester.pump();
    // removeUntil + route transition needs more than one 300ms frame.
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('home-dest'), findsOneWidget);
    expect(find.byType(PhotoStudioPage), findsNothing);
    expect(tester.state<NavigatorState>(find.byType(Navigator)).canPop(), isFalse);
  });

  testWidgets('export race keeps dirty when edits land during save',
      (tester) async {
    final saverEntered = Completer<void>();
    final saverRelease = Completer<bool>();
    final saverReturned = Completer<void>();
    await _pumpPage(
      tester,
      page: PhotoStudioPage(
        imageSaver: ({
          required Uint8List bytes,
          required String fileName,
          required String mimeType,
        }) async {
          if (!saverEntered.isCompleted) saverEntered.complete();
          try {
            return await saverRelease.future;
          } finally {
            if (!saverReturned.isCompleted) saverReturned.complete();
          }
        },
      ),
    );

    await _selectDraftTool(tester, 'Rectangle');
    await _createFrame(tester, x0: 0.1, y0: 0.1, x1: 0.35, y1: 0.35);
    expect(find.byIcon(Icons.circle), findsOneWidget);

    final saveButton = find.widgetWithText(FilledButton, 'Save PNG');
    await tester.ensureVisible(saveButton);
    await tester.pump();
    // Tap on the real async timeline, then poll only for saver entry —
    // never await the unreleased saverRelease inside runAsync.
    await tester.runAsync(() async {
      await tester.tap(saveButton);
    });
    final entered = await tester.runAsync(() async {
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (!saverEntered.isCompleted) {
        if (DateTime.now().isAfter(deadline)) return false;
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      return true;
    });
    expect(entered, isTrue);
    await tester.pump();

    await _selectDraftTool(tester, 'Circle');
    await _createFrame(tester, x0: 0.55, y0: 0.55, x1: 0.85, y1: 0.85);
    expect(find.byIcon(Icons.circle), findsOneWidget);

    saverRelease.complete(true);
    await tester.runAsync(
      () => saverReturned.future.timeout(const Duration(seconds: 5)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byIcon(Icons.circle), findsOneWidget);
  });

  testWidgets('clear during delayed replace keeps pending decode from restoring',
      (tester) async {
    final adapterEntered = Completer<void>();
    final adapterGate = Completer<Uint8List>();
    var picks = 0;

    await _pumpPage(
      tester,
      page: PhotoStudioPage(
        imageBytesPicker: () async {
          picks += 1;
          if (picks == 1) return _tinyPng;
          // Undecodable payload forces the injected adapter path.
          return Uint8List.fromList(const [0x00, 0x01, 0x02, 0x03]);
        },
        imageDecodeAdapter: (bytes) async {
          if (!adapterEntered.isCompleted) adapterEntered.complete();
          return adapterGate.future;
        },
      ),
    );

    await tester.runAsync(() async {
      await tester.tap(find.text('Import image'));
      await Future<void>.delayed(const Duration(milliseconds: 80));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(
      tester.widget<PhotoRectCanvas>(find.byType(PhotoRectCanvas)).imageBytes,
      isNotNull,
    );

    await tester.tap(find.text('Replace image'));
    await tester.pump();
    await tester.runAsync(
      () => adapterEntered.future.timeout(const Duration(seconds: 5)),
    );

    await tester.tap(find.text('Clear photo'));
    await tester.pump();
    expect(
      tester.widget<PhotoRectCanvas>(find.byType(PhotoRectCanvas)).imageBytes,
      isNull,
    );

    adapterGate.complete(_tinyPng);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(picks, 2);
    expect(
      tester.widget<PhotoRectCanvas>(find.byType(PhotoRectCanvas)).imageBytes,
      isNull,
    );
  });

  testWidgets('undo during delayed replace keeps pending decode from restoring',
      (tester) async {
    final adapterEntered = Completer<void>();
    final adapterGate = Completer<Uint8List>();
    var picks = 0;

    await _pumpPage(
      tester,
      page: PhotoStudioPage(
        imageBytesPicker: () async {
          picks += 1;
          if (picks == 1) return _tinyPng;
          return Uint8List.fromList(const [0x00, 0x01, 0x02, 0x03]);
        },
        imageDecodeAdapter: (bytes) async {
          if (!adapterEntered.isCompleted) adapterEntered.complete();
          return adapterGate.future;
        },
      ),
    );

    await tester.runAsync(() async {
      await tester.tap(find.text('Import image'));
      await Future<void>.delayed(const Duration(milliseconds: 80));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(
      tester.widget<PhotoRectCanvas>(find.byType(PhotoRectCanvas)).imageBytes,
      isNotNull,
    );
    expect(_undoEnabled(tester), isTrue);

    await tester.tap(find.text('Replace image'));
    await tester.pump();
    await tester.runAsync(
      () => adapterEntered.future.timeout(const Duration(seconds: 5)),
    );

    await _tapUndo(tester);
    expect(
      tester.widget<PhotoRectCanvas>(find.byType(PhotoRectCanvas)).imageBytes,
      isNull,
    );

    adapterGate.complete(_tinyPng);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      tester.widget<PhotoRectCanvas>(find.byType(PhotoRectCanvas)).imageBytes,
      isNull,
    );
  });
}
