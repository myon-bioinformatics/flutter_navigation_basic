import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/photo_studio/domain/normalized_rect.dart';
import 'package:flutter_application_1/features/photo_studio/domain/studio_frame.dart';
import 'package:flutter_application_1/features/photo_studio/domain/studio_frame_style.dart';
import 'package:flutter_application_1/features/photo_studio/presentation/photo_rect_canvas.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('outside drag create keeps origin through panEnd sanitize',
      (tester) async {
    var frames = <StudioFrame>[];
    final updates = <List<StudioFrame>>[];

    await tester.binding.setSurfaceSize(const Size(400, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return PhotoRectCanvas(
                frames: frames,
                draftShape: StudioFrameShape.rectangle,
                height: 300,
                onFramesChanged: (next) {
                  updates.add(List<StudioFrame>.from(next));
                  setState(() => frames = next);
                },
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();

    final overlay = find.byType(PhotoRectCanvas);
    final box = tester.getRect(overlay);
    final start =
        Offset(box.left + box.width * 0.05, box.top + box.height * 0.05);
    final end =
        Offset(box.left + box.width * 0.45, box.top + box.height * 0.55);

    final gesture = await tester.startGesture(start);
    await tester.pump();
    await gesture.moveTo(end);
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(updates, isNotEmpty);
    expect(frames, hasLength(1));
    final last = frames.single.rect;
    expect(last.left, closeTo(0.05, 0.03));
    expect(last.top, closeTo(0.05, 0.03));
    expect(last.right, greaterThan(0.35));
    expect(last.bottom, greaterThan(0.45));
    expect(last.width, greaterThanOrEqualTo(NormalizedRect.minSize));
    expect(last.height, greaterThanOrEqualTo(NormalizedRect.minSize));
  });

  testWidgets('outside drag up-left from center expands toward the origin',
      (tester) async {
    var frames = <StudioFrame>[
      const StudioFrame(
        studioFrameId: 'away',
        rect: NormalizedRect(
          left: 0.8,
          top: 0.8,
          right: 0.95,
          bottom: 0.95,
        ),
        shape: StudioFrameShape.rectangle,
        strokeArgb: StudioFrameColors.purple,
      ),
    ];

    await tester.binding.setSurfaceSize(const Size(400, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return PhotoRectCanvas(
                frames: frames,
                draftShape: StudioFrameShape.rectangle,
                height: 300,
                onFramesChanged: (next) {
                  setState(() => frames = next);
                },
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();

    final box = tester.getRect(find.byType(PhotoRectCanvas));
    final start =
        Offset(box.left + box.width * 0.5, box.top + box.height * 0.5);
    final end =
        Offset(box.left + box.width * 0.2, box.top + box.height * 0.2);

    final gesture = await tester.startGesture(start);
    await tester.pump();
    await gesture.moveTo(end);
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(frames, hasLength(2));
    final created = frames.last.rect;
    expect(created.right, closeTo(0.5, 0.03));
    expect(created.bottom, closeTo(0.5, 0.03));
    expect(created.left, lessThan(0.35));
    expect(created.top, lessThan(0.35));
  });

  testWidgets('draftShape null does not create on empty drag', (tester) async {
    var frames = <StudioFrame>[];

    await tester.binding.setSurfaceSize(const Size(400, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return PhotoRectCanvas(
                frames: frames,
                draftShape: null,
                height: 300,
                onFramesChanged: (next) {
                  setState(() => frames = next);
                },
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();

    final box = tester.getRect(find.byType(PhotoRectCanvas));
    final start =
        Offset(box.left + box.width * 0.1, box.top + box.height * 0.1);
    final end =
        Offset(box.left + box.width * 0.4, box.top + box.height * 0.4);
    final gesture = await tester.startGesture(start);
    await tester.pump();
    await gesture.moveTo(end);
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(frames, isEmpty);
  });

  testWidgets('can create two frames with draft tool', (tester) async {
    var frames = <StudioFrame>[];
    String? selectedId;

    await tester.binding.setSurfaceSize(const Size(400, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return PhotoRectCanvas(
                frames: frames,
                selectedStudioFrameId: selectedId,
                draftShape: StudioFrameShape.circle,
                height: 300,
                onFramesChanged: (next) {
                  setState(() => frames = next);
                },
                onSelectedStudioFrameIdChanged: (studioFrameId) {
                  setState(() => selectedId = studioFrameId);
                },
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();

    final box = tester.getRect(find.byType(PhotoRectCanvas));

    Future<void> dragCreate(Offset a, Offset b) async {
      final gesture = await tester.startGesture(a);
      await tester.pump();
      await gesture.moveTo(b);
      await tester.pump();
      await gesture.up();
      await tester.pump();
    }

    await dragCreate(
      Offset(box.left + box.width * 0.05, box.top + box.height * 0.05),
      Offset(box.left + box.width * 0.3, box.top + box.height * 0.3),
    );
    expect(frames, hasLength(1));
    expect(frames.single.shape, StudioFrameShape.circle);

    await dragCreate(
      Offset(box.left + box.width * 0.55, box.top + box.height * 0.55),
      Offset(box.left + box.width * 0.9, box.top + box.height * 0.9),
    );
    expect(frames, hasLength(2));
    expect(selectedId, frames.last.studioFrameId);
  });

  testWidgets('move selected frame via center drag', (tester) async {
    var frames = <StudioFrame>[
      const StudioFrame(
        studioFrameId: 'f1',
        rect: NormalizedRect(left: 0.2, top: 0.2, right: 0.8, bottom: 0.8),
        shape: StudioFrameShape.rectangle,
        strokeArgb: StudioFrameColors.purple,
      ),
    ];
    String? selectedId = 'f1';

    await tester.binding.setSurfaceSize(const Size(400, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return PhotoRectCanvas(
                frames: frames,
                selectedStudioFrameId: selectedId,
                draftShape: StudioFrameShape.rectangle,
                height: 300,
                onFramesChanged: (next) {
                  setState(() => frames = next);
                },
                onSelectedStudioFrameIdChanged: (studioFrameId) {
                  setState(() => selectedId = studioFrameId);
                },
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();

    final before = frames.single.rect;
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

    expect(frames, hasLength(1));
    expect(frames.single.rect, isNot(before));
    expect(frames.single.rect.left, greaterThan(before.left));
  });

  test('newStudioObjectId allocates distinct ids rapidly', () {
    final a = newStudioObjectId('frame');
    final b = newStudioObjectId('frame');
    final c = newStudioObjectId('stamp');
    expect(a, isNot(b));
    expect(b, isNot(c));
    expect(a, startsWith('frame-'));
    expect(c, startsWith('stamp-'));
  });

  testWidgets('overlapping frames prefer topmost body over buried handles',
      (tester) async {
    // Bottom frame selected; its top-left handle overlaps the top frame body.
    var frames = <StudioFrame>[
      const StudioFrame(
        studioFrameId: 'bottom',
        rect: NormalizedRect(left: 0.2, top: 0.2, right: 0.8, bottom: 0.8),
        shape: StudioFrameShape.rectangle,
        strokeArgb: StudioFrameColors.purple,
      ),
      const StudioFrame(
        studioFrameId: 'top',
        rect: NormalizedRect(left: 0.15, top: 0.15, right: 0.45, bottom: 0.45),
        shape: StudioFrameShape.rectangle,
        strokeArgb: StudioFrameColors.red,
      ),
    ];
    String? selectedId = 'bottom';

    await tester.binding.setSurfaceSize(const Size(400, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return PhotoRectCanvas(
                frames: frames,
                selectedStudioFrameId: selectedId,
                draftShape: null,
                height: 300,
                onFramesChanged: (next) {
                  setState(() => frames = next);
                },
                onSelectedStudioFrameIdChanged: (studioFrameId) {
                  setState(() => selectedId = studioFrameId);
                },
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();

    final box = tester.getRect(find.byType(PhotoRectCanvas));
    // Point inside top frame body, near bottom frame's top-left corner handle.
    final start = Offset(
      box.left + box.width * 0.22,
      box.top + box.height * 0.22,
    );
    final mid = Offset(start.dx + box.width * 0.06, start.dy + box.height * 0.06);
    final end = Offset(start.dx + box.width * 0.12, start.dy + box.height * 0.12);
    final gesture = await tester.startGesture(start);
    await tester.pump();
    await gesture.moveTo(mid);
    await tester.pump(); // allow selectedStudioFrameId rebuild after panStart
    await gesture.moveTo(end);
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(selectedId, 'top');
    final top = frames.firstWhere((f) => f.studioFrameId == 'top');
    final bottom = frames.firstWhere((f) => f.studioFrameId == 'bottom');
    // Buried selected-frame handle must not steal the gesture.
    expect(
      bottom.rect,
      const NormalizedRect(left: 0.2, top: 0.2, right: 0.8, bottom: 0.8),
    );
    expect(top.rect.left, greaterThan(0.15));
    expect(top.rect.top, greaterThan(0.15));
  });


  testWidgets('circle transparent corner defers to rectangle underneath',
      (tester) async {
    // Top circle bbox covers the corner; transparent corner should hit bottom rect.
    var frames = <StudioFrame>[
      const StudioFrame(
        studioFrameId: 'bottom',
        rect: NormalizedRect(left: 0.1, top: 0.1, right: 0.9, bottom: 0.9),
        shape: StudioFrameShape.rectangle,
        strokeArgb: StudioFrameColors.purple,
      ),
      const StudioFrame(
        studioFrameId: 'topCircle',
        rect: NormalizedRect(left: 0.2, top: 0.2, right: 0.8, bottom: 0.8),
        shape: StudioFrameShape.circle,
        strokeArgb: StudioFrameColors.red,
      ),
    ];
    String? selectedId = 'topCircle';

    await tester.binding.setSurfaceSize(const Size(400, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return PhotoRectCanvas(
                frames: frames,
                selectedStudioFrameId: selectedId,
                draftShape: null,
                height: 300,
                onFramesChanged: (next) {
                  setState(() => frames = next);
                },
                onSelectedStudioFrameIdChanged: (studioFrameId) {
                  setState(() => selectedId = studioFrameId);
                },
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();

    final box = tester.getRect(find.byType(PhotoRectCanvas));
    // Near top-left corner of the circle bbox (outside the inscribed circle).
    final start = Offset(
      box.left + box.width * 0.22,
      box.top + box.height * 0.22,
    );
    final end = Offset(start.dx + box.width * 0.1, start.dy + box.height * 0.1);
    final gesture = await tester.startGesture(start);
    await tester.pump();
    await gesture.moveTo(end);
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(selectedId, 'bottom');
    final bottom = frames.firstWhere((f) => f.studioFrameId == 'bottom');
    expect(bottom.rect.left, greaterThan(0.1));
    expect(bottom.rect.top, greaterThan(0.1));
  });
}
