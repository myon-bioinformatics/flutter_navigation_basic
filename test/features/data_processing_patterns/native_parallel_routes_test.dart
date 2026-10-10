import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../lib/config/routes.dart';

void main() {
  for (final id in [136, 137]) {
    testWidgets('pattern $id executes a real computation', (tester) async {
      final route = AppRoutes.routes[AppRoutes.screenRoute(id)];
      expect(route, isNotNull);
      await tester.pumpWidget(MaterialApp(home: Builder(builder: route!)));
      expect(find.text('未実行'), findsOneWidget);
      await tester.tap(find.text('実行'));
      await tester.pumpAndSettle();
      expect(find.textContaining('55'), findsOneWidget);
      expect(find.textContaining('失敗:'), findsNothing);
    });
  }
}
