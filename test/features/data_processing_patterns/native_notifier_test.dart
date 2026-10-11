import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_158/view.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_159/view.dart';

void main() {
  final cases = <(String, Widget)>[
    ('ChangeNotifier', const Pattern158View()),
    ('ValueNotifier', const Pattern159View()),
  ];
  for (final (name, view) in cases) {
    testWidgets('$name changes, resets and disposes state', (tester) async {
      await tester.pumpWidget(MaterialApp(home: view));
      expect(find.text('カウント: 0'), findsOneWidget);
      expect(find.textContaining(name), findsWidgets);
      await tester.tap(find.text('加算'));
      await tester.pump();
      expect(find.text('カウント: 1'), findsOneWidget);
      await tester.tap(find.text('リセット'));
      await tester.pump();
      expect(find.text('カウント: 0'), findsOneWidget);
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      expect(tester.takeException(), isNull);
    });
  }
}
