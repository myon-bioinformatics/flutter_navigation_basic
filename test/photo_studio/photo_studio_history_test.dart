import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/photo_studio/domain/emoji_stamp.dart';
import 'package:flutter_application_1/features/photo_studio/domain/normalized_rect.dart';
import 'package:flutter_application_1/features/photo_studio/domain/photo_studio_history.dart';
import 'package:flutter_application_1/features/photo_studio/domain/photo_studio_state.dart';
import 'package:flutter_application_1/features/photo_studio/domain/studio_frame.dart';
import 'package:flutter_application_1/features/photo_studio/domain/studio_frame_style.dart';
import 'package:flutter_application_1/features/photo_studio/presentation/photo_rect_canvas.dart';
import 'package:flutter_application_1/features/photo_studio/presentation/photo_studio_page.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/display_test_harness.dart';

PhotoStudioState _state({
  Uint8List? imageBytes,
  List<StudioFrame> frames = const [],
  String? selectedStudioFrameId,
  int draftStrokeArgb = StudioFrameColors.purple,
  StudioFrameShape? draftShape,
  List<EmojiStamp> stamps = const [],
  String? selectedEmojiStampId,
  double stampScale = 1,
}) =>
    PhotoStudioState(
      imageBytes: imageBytes,
      frames: frames,
      selectedStudioFrameId: selectedStudioFrameId,
      draftStrokeArgb: draftStrokeArgb,
      draftShape: draftShape,
      stamps: stamps,
      selectedEmojiStampId: selectedEmojiStampId,
      stampScale: stampScale,
    );

StudioFrame _frame({
  String id = 'frame-a',
  NormalizedRect rect = NormalizedRect.initial,
  StudioFrameShape shape = StudioFrameShape.rectangle,
  int strokeArgb = StudioFrameColors.purple,
}) =>
    StudioFrame(
      studioFrameId: id,
      rect: rect,
      shape: shape,
      strokeArgb: strokeArgb,
    );

void main() {
  group('PhotoStudioHistory', () {
    test('initial state has empty frames and null draft tool', () {
      final initial = PhotoStudioState.initial();
      expect(initial.frames, isEmpty);
      expect(initial.draftShape, isNull);
      expect(initial.draftStrokeArgb, StudioFrameColors.purple);
      expect(initial.selectedStudioFrameId, isNull);
    });

    test('gesture commit stores before-state and undo restores it', () {
      final history = PhotoStudioHistory();
      final before = _state(frames: [_frame()]);
      final after = _state(
        frames: [
          _frame(
            rect: const NormalizedRect(
              left: 0.1,
              top: 0.1,
              right: 0.9,
              bottom: 0.9,
            ),
          ),
        ],
        selectedStudioFrameId: 'frame-a',
      );

      history.beginGesture(before);
      expect(history.endGesture(after), isTrue);
      expect(history.depth, 1);
      expect(history.canUndo, isTrue);

      final undone = history.undo(after);
      expect(undone, before);
      expect(history.depth, 0);
      expect(history.canRedo, isTrue);
    });

    test('gesture no-op is discarded', () {
      final history = PhotoStudioHistory();
      final state = _state(draftStrokeArgb: StudioFrameColors.red);

      history.beginGesture(state);
      expect(history.endGesture(state), isFalse);
      expect(history.depth, 0);
      expect(history.canUndo, isFalse);
    });

    test('recordChange no-op is discarded', () {
      final history = PhotoStudioHistory();
      final state = PhotoStudioState.initial();
      expect(history.recordChange(state, state), isFalse);
      expect(history.depth, 0);
    });

    test('caps at 20 entries via removeAt(0)', () {
      final history = PhotoStudioHistory();
      final base = PhotoStudioState.initial();

      var current = base;
      for (var i = 0; i < 25; i++) {
        final before = base.copyWith(stampScale: 1.0 + i * 0.01);
        final after = base.copyWith(stampScale: 1.0 + (i + 1) * 0.01);
        expect(history.recordChange(before, after), isTrue);
        current = after;
      }

      expect(history.depth, 20);
      final first = history.undo(current);
      expect(first!.stampScale, closeTo(1.24, 1e-9));

      PhotoStudioState? oldest;
      var cursor = first;
      while (history.canUndo) {
        oldest = history.undo(cursor);
        cursor = oldest!;
      }
      expect(oldest!.stampScale, closeTo(1.05, 1e-9));
      expect(history.depth, 0);
    });

    test('no-op at cap keeps depth at 20', () {
      final history = PhotoStudioHistory();
      final base = PhotoStudioState.initial();

      for (var i = 0; i < 20; i++) {
        history.recordChange(
          base.copyWith(stampScale: 1.0 + i * 0.01),
          base.copyWith(stampScale: 1.0 + (i + 1) * 0.01),
        );
      }
      expect(history.depth, 20);

      final same = base.copyWith(stampScale: 9);
      expect(history.recordChange(same, same), isFalse);
      expect(history.depth, 20);

      history.beginGesture(same);
      expect(history.endGesture(same), isFalse);
      expect(history.depth, 20);
    });

    test('mutating source stamp list does not change stored state/history', () {
      final history = PhotoStudioHistory();
      final mutable = <EmojiStamp>[
        const EmojiStamp(
          emojiStampId: 'a',
          emoji: '⭐',
          x: 0.2,
          y: 0.3,
        ),
      ];
      final before = _state(stamps: mutable);
      final after = before.copyWith(
        stamps: [
          const EmojiStamp(
            emojiStampId: 'a',
            emoji: '⭐',
            x: 0.8,
            y: 0.7,
          ),
        ],
      );

      expect(history.recordChange(before, after), isTrue);
      mutable.clear();
      mutable.add(
        const EmojiStamp(
          emojiStampId: 'mutated',
          emoji: '🔥',
          x: 0.1,
          y: 0.1,
        ),
      );

      expect(before.stamps, hasLength(1));
      expect(before.stamps.single.emojiStampId, 'a');
      expect(
          () => before.stamps.add(
                const EmojiStamp(
                  emojiStampId: 'x',
                  emoji: 'x',
                  x: 0,
                  y: 0,
                ),
              ),
          throwsUnsupportedError);

      final restored = history.undo(after);
      expect(restored!.stamps, hasLength(1));
      expect(restored.stamps.single.emojiStampId, 'a');
      expect(restored.stamps.single.x, 0.2);
    });

    test('mutating source frame list does not change stored state', () {
      final mutable = <StudioFrame>[_frame()];
      final state = _state(frames: mutable);
      mutable.clear();
      expect(state.frames, hasLength(1));
      expect(
        () => state.frames.add(_frame(id: 'x')),
        throwsUnsupportedError,
      );
    });

    test('shared imageBytes identical across history entries', () {
      final history = PhotoStudioHistory();
      final bytes = Uint8List.fromList(List<int>.generate(64, (i) => i));
      final withImage = _state(imageBytes: bytes);
      final blue = withImage.copyWith(draftStrokeArgb: StudioFrameColors.blue);
      final green = withImage.copyWith(draftStrokeArgb: StudioFrameColors.green);

      history.recordChange(withImage, blue);
      history.recordChange(blue, green);

      final second = history.undo(green);
      final first = history.undo(second!);
      expect(identical(second.imageBytes, bytes), isTrue);
      expect(identical(first!.imageBytes, bytes), isTrue);
      expect(identical(first.imageBytes, second.imageBytes), isTrue);
    });

    test('multi undo restores draft shape in reverse commit order', () {
      final history = PhotoStudioHistory();
      final a = _state(draftShape: null);
      final b = _state(draftShape: StudioFrameShape.circle);
      final c = _state(draftShape: StudioFrameShape.triangle);

      expect(history.recordChange(a, b), isTrue);
      expect(history.recordChange(b, c), isTrue);
      expect(history.depth, 2);

      expect(history.undo(c)!.draftShape, StudioFrameShape.circle);
      expect(history.undo(b)!.draftShape, isNull);
      expect(history.undo(a), isNull);
    });

    test('redo restores undone state and new edit clears redo', () {
      final history = PhotoStudioHistory();
      final a = _state(draftShape: null);
      final b = _state(draftShape: StudioFrameShape.circle);
      final c = _state(draftShape: StudioFrameShape.triangle);

      history.recordChange(a, b);
      history.recordChange(b, c);

      final undone = history.undo(c);
      expect(undone, b);
      expect(history.canRedo, isTrue);

      final redone = history.redo(b);
      expect(redone, c);
      expect(history.canRedo, isFalse);

      final undoneAgain = history.undo(c);
      expect(undoneAgain, b);
      // New edit after undo clears redo stack.
      final d = _state(draftShape: StudioFrameShape.rectangle);
      expect(history.recordChange(b, d), isTrue);
      expect(history.canRedo, isFalse);
      expect(history.redo(d), isNull);
    });
  });

  group('Photo Studio gesture history', () {
    for (final cancel in const [false, true]) {
      final ending = cancel ? 'pointer cancel' : 'pointer up';
      testWidgets('spray $ending closes one undo/redo transaction',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(900, 2600));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          MaterialApp(
            home: await wrapWithDisplayScope(const PhotoStudioPage()),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        final canvasFinder = find.byType(PhotoRectCanvas);
        PhotoRectCanvas canvas() =>
            tester.widget<PhotoRectCanvas>(canvasFinder);
        Finder historyButton(String tooltip) => find.byWidgetPredicate(
              (widget) => widget is IconButton && widget.tooltip == tooltip,
            );
        bool enabled(String tooltip) =>
            tester.widget<IconButton>(historyButton(tooltip)).onPressed != null;
        Future<void> tapHistory(String tooltip) async {
          final button = historyButton(tooltip);
          expect(button, findsOneWidget);
          expect(enabled(tooltip), isTrue);
          await tester.ensureVisible(button);
          await tester.tap(button);
          await tester.pump();
        }

        expect(canvas().stamps, isEmpty);
        expect(enabled('Undo'), isFalse);
        expect(enabled('Redo'), isFalse);
        final shortcut = find.widgetWithText(ActionChip, '⭐');
        await tester.ensureVisible(shortcut);
        await tester.tap(shortcut);
        await tester.pump();
        expect(canvas().pendingEmoji, '⭐');
        expect(enabled('Undo'), isFalse);

        await tester.ensureVisible(canvasFinder);
        await tester.pump();
        final box = tester.getRect(canvasFinder);
        final gesture = await tester.startGesture(
          Offset(box.left + box.width * 0.1, box.top + box.height * 0.2),
        );
        await gesture.moveTo(
          Offset(box.left + box.width * 0.35, box.top + box.height * 0.3),
        );
        // Deliberately send another move before a parent rebuild.
        await gesture.moveTo(
          Offset(box.left + box.width * 0.6, box.top + box.height * 0.5),
        );
        await tester.pump();
        final sprayed = List<EmojiStamp>.of(canvas().stamps);
        expect(sprayed, hasLength(3));
        expect(sprayed.map((stamp) => stamp.emojiStampId).toSet(), hasLength(3));
        expect(enabled('Undo'), isFalse);

        if (cancel) {
          await gesture.cancel();
        } else {
          await gesture.up();
        }
        await tester.pump();
        // Cancel commits the placements made so far, just like pointer-up.
        // A missing onEditEnd must fail here, before another gesture can hide it.
        expect(enabled('Undo'), isTrue);
        expect(canvas().stamps, orderedEquals(sprayed));
        await tester.pump(const Duration(seconds: 1));
        expect(canvas().stamps, orderedEquals(sprayed));

        await tapHistory('Undo');
        expect(canvas().stamps, isEmpty);
        expect(enabled('Undo'), isFalse);
        expect(enabled('Redo'), isTrue);
        await tapHistory('Redo');
        // EmojiStamp value equality checks IDs, emoji, coordinates and scale.
        expect(canvas().stamps, orderedEquals(sprayed));
        expect(canvas().selectedEmojiStampId, sprayed.last.emojiStampId);
        expect(enabled('Redo'), isFalse);
        expect(canvas().pendingEmoji, '⭐');

        // The next independent tap must not join or reuse the closed spray.
        await tester.ensureVisible(canvasFinder);
        await tester.pump();
        final nextBox = tester.getRect(canvasFinder);
        await tester.tapAt(
          Offset(
            nextBox.left + nextBox.width * 0.85,
            nextBox.top + nextBox.height * 0.85,
          ),
        );
        await tester.pump();
        final withTap = List<EmojiStamp>.of(canvas().stamps);
        expect(withTap, hasLength(4));
        expect(withTap.take(3), orderedEquals(sprayed));
        expect(withTap.map((stamp) => stamp.emojiStampId).toSet(), hasLength(4));

        await tapHistory('Undo');
        expect(canvas().stamps, orderedEquals(sprayed));
        await tapHistory('Undo');
        expect(canvas().stamps, isEmpty);
        expect(enabled('Undo'), isFalse);
        await tapHistory('Redo');
        expect(canvas().stamps, orderedEquals(sprayed));
        await tapHistory('Redo');
        expect(canvas().stamps, orderedEquals(withTap));
        expect(enabled('Redo'), isFalse);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
