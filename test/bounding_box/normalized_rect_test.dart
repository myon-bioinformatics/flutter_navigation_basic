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
  });
}
