import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../lib/config/routes.dart';

/// AppBar title that each numbered route must show. The shared widget renders
/// the same `順序: A, B, C` for all seven, so the title is what proves that
/// /screenN was wired to patternId N and not to a neighbouring one.
const _titles = <int, String>{
  171: 'Pattern 171: SortableList',
  172: 'Pattern 172: ReorderList',
  173: 'Pattern 173: DndGrid',
  174: 'Pattern 174: InsertItem',
  175: 'Pattern 175: RemoveItem',
  183: 'Pattern 183: MultiSelect',
  184: 'Pattern 184: DragReorder',
};

void main() {
  testWidgets('seven numbered catalogue routes expose real native interactions',
      (tester) async {
    for (final entry in _titles.entries) {
      final route = AppRoutes.routes[AppRoutes.screenRoute(entry.key)];
      expect(route, isNotNull, reason: 'missing /screen${entry.key}');
      await tester.pumpWidget(MaterialApp(home: Builder(builder: route!)));
      expect(find.text(entry.value), findsOneWidget,
          reason: '/screen${entry.key} should open ${entry.value}');
      expect(find.textContaining('順序: A, B, C'), findsOneWidget,
          reason: '/screen${entry.key} should expose the real interaction state');
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
