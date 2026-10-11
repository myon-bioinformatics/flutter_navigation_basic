import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_166/view.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_167/view.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_168/view.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_169/view.dart';
import 'package:flutter_application_1/features/data_processing_patterns/pattern_100_to_198/pattern_170/view.dart';

void main() {
  for (final (name, view) in <(String, Widget)>[
    ('MVC', const Pattern166View()),
    ('MVVM', const Pattern167View()),
    ('MVP', const Pattern168View()),
    ('CleanArch', const Pattern169View()),
  ]) {
    testWidgets('$name updates and resets the application state', (tester) async {
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
  testWidgets('AtomState holds independent state values', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Pattern170View()));
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
