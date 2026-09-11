import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/bounding_box/domain/normalized_rect.dart';
import 'package:flutter_application_1/features/bounding_box/presentation/image_rect_overlay.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('outside drag create keeps origin through panEnd sanitize', (tester) async {
    var rect = NormalizedRect.initial;
    final updates = <NormalizedRect>[];

    await tester.binding.setSurfaceSize(const Size(400, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return ImageRectOverlay(
                rect: rect,
                height: 300,
                onRectChanged: (next) {
                  updates.add(next);
                  setState(() => rect = next);
                },
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();

    final overlay = find.byType(ImageRectOverlay);
    final box = tester.getRect(overlay);
    // Start in the top-left empty area (outside the default 0.2–0.8 rect).
    final start = Offset(box.left + box.width * 0.05, box.top + box.height * 0.05);
    final end = Offset(box.left + box.width * 0.45, box.top + box.height * 0.55);

    final gesture = await tester.startGesture(start);
    await tester.pump();
    await gesture.moveTo(end);
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(updates, isNotEmpty);
    final last = updates.last;
    // Origin stays near the press point; opposite corner follows the drag.
    expect(last.left, closeTo(0.05, 0.03));
    expect(last.top, closeTo(0.05, 0.03));
    expect(last.right, greaterThan(0.35));
    expect(last.bottom, greaterThan(0.45));
    expect(last.width, greaterThanOrEqualTo(NormalizedRect.minSize));
    expect(last.height, greaterThanOrEqualTo(NormalizedRect.minSize));
  });

  testWidgets('outside drag up-left from center expands toward the origin', (tester) async {
    NormalizedRect? last;

    await tester.binding.setSurfaceSize(const Size(400, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return ImageRectOverlay(
                // Put existing rect away so center of canvas is empty.
                rect: last ??
                    const NormalizedRect(
                      left: 0.8,
                      top: 0.8,
                      right: 0.95,
                      bottom: 0.95,
                    ),
                height: 300,
                onRectChanged: (next) {
                  setState(() => last = next);
                },
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();

    final box = tester.getRect(find.byType(ImageRectOverlay));
    final start = Offset(box.left + box.width * 0.5, box.top + box.height * 0.5);
    final end = Offset(box.left + box.width * 0.2, box.top + box.height * 0.2);

    final gesture = await tester.startGesture(start);
    await tester.pump();
    await gesture.moveTo(end);
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(last, isNotNull);
    expect(last!.right, closeTo(0.5, 0.03));
    expect(last!.bottom, closeTo(0.5, 0.03));
    expect(last!.left, lessThan(0.35));
    expect(last!.top, lessThan(0.35));
  });
}
