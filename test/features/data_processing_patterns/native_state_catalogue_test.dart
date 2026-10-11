import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_151/view.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_152/view.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_153/view.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_154/view.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_155/view.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_156/view.dart';

void main() {
  final cases = <(String, String, Widget)>[
    ('151', 'Pattern 151: GetxState', const Pattern151View()),
    ('152', 'Pattern 152: GetxObservable', const Pattern152View()),
    ('153', 'Pattern 153: GetxController', const Pattern153View()),
    ('154', 'Pattern 154: GetxBinding', const Pattern154View()),
    ('155', 'Pattern 155: GetxWorker', const Pattern155View()),
    ('156', 'Pattern 156: GetxService', const Pattern156View()),
  ];
  for (final (id, title, view) in cases) {
    testWidgets('native state $id has working transitions and no fake GetX run', (tester) async {
      await tester.pumpWidget(MaterialApp(home: view));
      expect(find.text(title), findsOneWidget);
      expect(find.text('カウント: 0'), findsOneWidget);
      expect(find.textContaining('GetXを使用しないFlutter標準'), findsOneWidget);
      expect(find.text('実行'), findsNothing);
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
