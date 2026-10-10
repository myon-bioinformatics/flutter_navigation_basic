import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../lib/config/routes.dart';
import '../../../lib/features/data_processing_patterns/pattern_100_to_198/pattern_171/view.dart';
import '../../../lib/features/data_processing_patterns/pattern_100_to_198/pattern_172/view.dart';
import '../../../lib/features/data_processing_patterns/pattern_100_to_198/pattern_173/view.dart';
import '../../../lib/features/data_processing_patterns/pattern_100_to_198/pattern_174/view.dart';
import '../../../lib/features/data_processing_patterns/pattern_100_to_198/pattern_175/view.dart';
import '../../../lib/features/data_processing_patterns/pattern_100_to_198/pattern_183/view.dart';
import '../../../lib/features/data_processing_patterns/pattern_100_to_198/pattern_184/view.dart';

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

  // The numbered Views are the catalogue's thin entry points. routes.dart cannot
  // import them (public code must not depend on *_patterns), so this test is the
  // only reference that keeps them from silently drifting from the routes.
  testWidgets('numbered Views open the same interaction as their routes',
      (tester) async {
    const views = <int, Widget>{
      171: Pattern171View(),
      172: Pattern172View(),
      173: Pattern173View(),
      174: Pattern174View(),
      175: Pattern175View(),
      183: Pattern183View(),
      184: Pattern184View(),
    };
    expect(views.keys, _titles.keys);
    for (final entry in views.entries) {
      await tester.pumpWidget(MaterialApp(home: entry.value));
      expect(find.text(_titles[entry.key]!), findsOneWidget,
          reason: 'Pattern${entry.key}View should open ${_titles[entry.key]}');
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
