import 'dart:typed_data';

import 'package:flutter_application_1/features/photo_studio/domain/emoji_stamp.dart';
import 'package:flutter_application_1/features/photo_studio/domain/normalized_rect.dart';
import 'package:flutter_application_1/features/photo_studio/domain/photo_studio_history.dart';
import 'package:flutter_application_1/features/photo_studio/domain/photo_studio_state.dart';
import 'package:flutter_application_1/features/photo_studio/domain/studio_frame_style.dart';
import 'package:flutter_test/flutter_test.dart';

PhotoStudioState _state({
  Uint8List? imageBytes,
  NormalizedRect rect = NormalizedRect.initial,
  StudioFrameShape shape = StudioFrameShape.rectangle,
  int strokeArgb = StudioFrameColors.purple,
  List<EmojiStamp> stamps = const [],
  String? selectedEmojiStampId,
  double stampScale = 1,
}) =>
    PhotoStudioState(
      imageBytes: imageBytes,
      rect: rect,
      shape: shape,
      strokeArgb: strokeArgb,
      stamps: stamps,
      selectedEmojiStampId: selectedEmojiStampId,
      stampScale: stampScale,
    );

void main() {
  group('PhotoStudioHistory', () {
    test('gesture commit stores before-state and undo restores it', () {
      final history = PhotoStudioHistory();
      final before = _state(rect: NormalizedRect.initial);
      final after = _state(
        rect: const NormalizedRect(left: 0.1, top: 0.1, right: 0.9, bottom: 0.9),
      );

      history.beginGesture(before);
      expect(history.endGesture(after), isTrue);
      expect(history.depth, 1);
      expect(history.canUndo, isTrue);

      final undone = history.undo();
      expect(undone, before);
      expect(history.depth, 0);
    });

    test('gesture no-op is discarded', () {
      final history = PhotoStudioHistory();
      final state = _state(strokeArgb: StudioFrameColors.red);

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

      for (var i = 0; i < 25; i++) {
        final before = base.copyWith(stampScale: 1.0 + i * 0.01);
        final after = base.copyWith(stampScale: 1.0 + (i + 1) * 0.01);
        expect(history.recordChange(before, after), isTrue);
      }

      expect(history.depth, 20);
      // Oldest five dropped; first remaining is i=5 (stampScale 1.05).
      final first = history.undo();
      // After 5 undos of the newest... actually undo pops last.
      // Last recorded before was i=24 with stampScale 1.24.
      expect(first!.stampScale, closeTo(1.24, 1e-9));

      // Drain until oldest remaining (i=5 → stampScale 1.05).
      PhotoStudioState? oldest;
      while (history.canUndo) {
        oldest = history.undo();
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
      expect(() => before.stamps.add(
            const EmojiStamp(
              emojiStampId: 'x',
              emoji: 'x',
              x: 0,
              y: 0,
            ),
          ), throwsUnsupportedError);

      final restored = history.undo();
      expect(restored!.stamps, hasLength(1));
      expect(restored.stamps.single.emojiStampId, 'a');
      expect(restored.stamps.single.x, 0.2);
    });

test('shared imageBytes identical across history entries', () {
      final history = PhotoStudioHistory();
      final bytes = Uint8List.fromList(List<int>.generate(64, (i) => i));
      final withImage = _state(imageBytes: bytes);

      history.recordChange(
        withImage,
        withImage.copyWith(strokeArgb: StudioFrameColors.blue),
      );
      history.recordChange(
        withImage.copyWith(strokeArgb: StudioFrameColors.blue),
        withImage.copyWith(strokeArgb: StudioFrameColors.green),
      );

      final second = history.undo();
      final first = history.undo();
      expect(identical(second!.imageBytes, bytes), isTrue);
      expect(identical(first!.imageBytes, bytes), isTrue);
      expect(identical(first.imageBytes, second.imageBytes), isTrue);
    });

    test('multi undo restores in reverse commit order', () {
      final history = PhotoStudioHistory();
      final a = _state(shape: StudioFrameShape.rectangle);
      final b = _state(shape: StudioFrameShape.circle);
      final c = _state(shape: StudioFrameShape.triangle);

      expect(history.recordChange(a, b), isTrue);
      expect(history.recordChange(b, c), isTrue);
      expect(history.depth, 2);

      expect(history.undo()!.shape, StudioFrameShape.circle);
      expect(history.undo()!.shape, StudioFrameShape.rectangle);
      expect(history.undo(), isNull);
    });
  });
}
