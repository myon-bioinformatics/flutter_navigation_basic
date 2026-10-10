import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_157/view.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_160/view.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_161/view.dart';

void main() {
  final examples = <(String, Widget)>[
    ('ProviderBasic', const Pattern157View()),
    ('InheritedWidget', const Pattern160View()),
    ('InheritedModel', const Pattern161View()),
  ];
  for (final (name, view) in examples) {
    testWidgets('$name propagates both values independently', (tester) async {
      await tester.pumpWidget(MaterialApp(home: view));
      expect(find.textContaining(name), findsWidgets);
      expect(find.text('left: 0'), findsOneWidget);
      expect(find.text('right: 0'), findsOneWidget);
      await tester.tap(find.text('左を加算'));
      await tester.pump();
      expect(find.text('left: 1'), findsOneWidget);
      expect(find.text('right: 0'), findsOneWidget);
      await tester.tap(find.text('右を加算'));
      await tester.pump();
      expect(find.text('left: 1'), findsOneWidget);
      expect(find.text('right: 1'), findsOneWidget);
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      expect(tester.takeException(), isNull);
    });
  }
}
