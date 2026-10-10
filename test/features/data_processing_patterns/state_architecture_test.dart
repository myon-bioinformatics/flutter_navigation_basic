import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_162/view.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_163/view.dart';

void main() {
  for (final (name, view) in <(String, Widget)>[
    ('StateNotifier', const Pattern162View()),
    ('Bloc', const Pattern163View()),
  ]) {
    testWidgets('$name handles events, reset and dispose', (tester) async {
      await tester.pumpWidget(MaterialApp(home: view));
      expect(find.textContaining(name), findsWidgets);
      expect(find.text('カウント: 0'), findsOneWidget);
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
