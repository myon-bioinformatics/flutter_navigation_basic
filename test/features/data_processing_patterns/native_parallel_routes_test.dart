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
      await tester.pump();

      // Isolate.run/compute complete on the real event loop. pumpAndSettle
      // alone cannot guarantee completion of an external isolate's Future.
      await tester.runAsync(() async {
        for (var attempt = 0; attempt < 100; attempt++) {
          final status = tester.widget<Text>(
            find.byKey(const ValueKey('parallel-status')),
          ).data ?? '';
          if (status.contains('55') || status.startsWith('失敗:')) return;
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      });
      await tester.pump();
      final actualStatus = tester.widget<Text>(
        find.byKey(const ValueKey('parallel-status')),
      ).data ?? '';
      expect(actualStatus, contains('55'),
          reason: 'Pattern $id actual status: $actualStatus');
      expect(actualStatus, isNot(startsWith('失敗:')),
          reason: 'Pattern $id actual status: $actualStatus');
    });
  }
}
