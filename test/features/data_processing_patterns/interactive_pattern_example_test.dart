import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/data_processing/interactive_pattern_example.dart';

void main() {
  testWidgets('171 reorders with a real pointer gesture', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: InteractivePatternExample(patternId: 171)));
    expect(find.text('順序: A, B, C'), findsOneWidget);
    await tester.drag(find.text('A'), const Offset(0, 160));
    await tester.pumpAndSettle();
    expect(find.text('順序: A, B, C'), findsNothing);
  });
  testWidgets('172 implements reorderable list', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: InteractivePatternExample(patternId: 172)));
    expect(find.byType(ReorderableListView), findsOneWidget);
    await tester.drag(find.text('A'), const Offset(0, 160));
    await tester.pumpAndSettle();
    expect(find.text('順序: A, B, C'), findsNothing);
  });
  testWidgets('173 renders native drag targets', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: InteractivePatternExample(patternId: 173)));
    expect(find.byType(DragTarget<String>), findsNWidgets(3));
    expect(find.byType(LongPressDraggable<String>), findsNWidgets(3));
    expect(find.text('順序: A, B, C'), findsOneWidget);
  });

  testWidgets('173 keeps A/B/C semantics identity across consecutive swaps', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(home: InteractivePatternExample(patternId: 173)),
    );

    Finder item(String label) => find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          widget.properties.identifier == 'interaction-item-$label',
    );

    void verify(List<String> order) {
      expect(find.text('順序: ${order.join(", ")}'), findsOneWidget);
      expect(find.byType(DragTarget<String>), findsNWidgets(3));
      expect(
        tester.widgetList<DragTarget<String>>(find.byType(DragTarget<String>))
            .map((target) => target.key)
            .toList(),
        [for (final label in order) ValueKey('grid-target-$label')],
      );
      for (final label in ['A', 'B', 'C']) {
        final target = item(label);
        expect(target, findsOneWidget);
        expect(find.descendant(of: target, matching: find.text(label)),
            findsOneWidget);
        expect(tester.getSemantics(target).getSemanticsData().identifier,
            'interaction-item-$label');
      }
    }

    Future<void> swap(String source, String destination) async {
      final gesture = await tester.startGesture(tester.getCenter(item(source)));
      await tester.pump(const Duration(milliseconds: 750));
      await gesture.moveTo(tester.getCenter(item(destination)));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
    }

    verify(['A', 'B', 'C']);
    await swap('A', 'B');
    verify(['B', 'A', 'C']);
    // A changed index: the second drag must follow the item, not old slot.
    await swap('A', 'C');
    verify(['B', 'C', 'A']);
    // Flutter verifies semantics handle disposal before addTearDown callbacks.
    handle.dispose();
  });
  testWidgets('174 inserts animated list item', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: InteractivePatternExample(patternId: 174)));
    await tester.tap(find.text('挿入'));
    await tester.pumpAndSettle();
    expect(find.text('順序: N1, A, B, C'), findsOneWidget);
    expect(find.text('N1'), findsOneWidget);
  });
  testWidgets('175 removes animated list item', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: InteractivePatternExample(patternId: 175)));
    await tester.tap(find.text('削除'));
    await tester.pumpAndSettle();
    expect(find.text('順序: B, C'), findsOneWidget);
    expect(find.text('A'), findsNothing);
  });
  testWidgets('183 multi selection and batch deletion', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: InteractivePatternExample(patternId: 183)));
    await tester.tap(find.text('A'));
    await tester.pump();
    expect(find.text('選択数: 1'), findsOneWidget);
    await tester.tap(find.text('選択項目を削除'));
    await tester.pump();
    expect(find.text('順序: B, C'), findsOneWidget);
  });
  testWidgets('184 keeps long press reorder gesture', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: InteractivePatternExample(patternId: 184)));
    expect(find.byType(ReorderableDelayedDragStartListener), findsNWidgets(3));
  });
}
