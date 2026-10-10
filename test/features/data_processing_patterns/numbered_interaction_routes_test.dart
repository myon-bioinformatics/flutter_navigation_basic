import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../lib/config/routes.dart';

void main() {
  testWidgets('seven numbered catalogue routes expose real native interactions',
      (tester) async {
    for (final id in [171, 172, 173, 174, 175, 183, 184]) {
      final route = AppRoutes.routes[AppRoutes.screenRoute(id)];
      expect(route, isNotNull, reason: 'missing /screen$id');
      await tester.pumpWidget(MaterialApp(home: Builder(builder: route!)));
      expect(find.textContaining('順序: A, B, C'), findsOneWidget,
          reason: '/screen$id should expose the real interaction state');
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
