import 'package:flutter_application_1/features/bounding_box/domain/normalized_rect.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NormalizedRect', () {
    test('keeps initial inset rect sanitized', () {
      final rect = NormalizedRect.initial.sanitized();
      expect(rect.left, 0.2);
      expect(rect.top, 0.2);
      expect(rect.right, 0.8);
      expect(rect.bottom, 0.8);
    });

    test('clamps and enforces minimum size after sanitize', () {
      final rect = const NormalizedRect(
        left: 0.1,
        top: 0.1,
        right: 0.12,
        bottom: 0.11,
      ).sanitized();
      expect(rect.width, greaterThanOrEqualTo(NormalizedRect.minSize));
      expect(rect.height, greaterThanOrEqualTo(NormalizedRect.minSize));
      expect(rect.left, inInclusiveRange(0, 1));
      expect(rect.right, inInclusiveRange(0, 1));
    });

    test('translates without leaving the unit square', () {
      final moved = NormalizedRect.initial.translated(0.9, -0.5);
      expect(moved.left, greaterThanOrEqualTo(0));
      expect(moved.top, greaterThanOrEqualTo(0));
      expect(moved.right, lessThanOrEqualTo(1));
      expect(moved.bottom, lessThanOrEqualTo(1));
    });

    test('corner resize updates the targeted edges', () {
      final resized = NormalizedRect.initial.resized(
        handle: NormalizedRectHandle.bottomRight,
        dx: -0.1,
        dy: -0.1,
      );
      expect(resized.right, closeTo(0.7, 1e-9));
      expect(resized.bottom, closeTo(0.7, 1e-9));
      expect(resized.left, closeTo(0.2, 1e-9));
      expect(resized.top, closeTo(0.2, 1e-9));
    });

    test('fromDiagonal keeps the drag origin for every direction', () {
      const originX = 0.5;
      const originY = 0.5;

      final downRight = NormalizedRect.fromDiagonal(
        x0: originX,
        y0: originY,
        x1: 0.8,
        y1: 0.9,
      );
      expect(downRight.left, originX);
      expect(downRight.top, originY);
      expect(downRight.right, 0.8);
      expect(downRight.bottom, 0.9);

      final upLeft = NormalizedRect.fromDiagonal(
        x0: originX,
        y0: originY,
        x1: 0.2,
        y1: 0.1,
      );
      expect(upLeft.left, 0.2);
      expect(upLeft.top, 0.1);
      expect(upLeft.right, originX);
      expect(upLeft.bottom, originY);

      final upRight = NormalizedRect.fromDiagonal(
        x0: originX,
        y0: originY,
        x1: 0.7,
        y1: 0.2,
      );
      expect(upRight.left, originX);
      expect(upRight.top, 0.2);
      expect(upRight.right, 0.7);
      expect(upRight.bottom, originY);

      final downLeft = NormalizedRect.fromDiagonal(
        x0: originX,
        y0: originY,
        x1: 0.1,
        y1: 0.75,
      );
      expect(downLeft.left, 0.1);
      expect(downLeft.top, originY);
      expect(downLeft.right, originX);
      expect(downLeft.bottom, 0.75);
    });
  });
}
