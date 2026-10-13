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
