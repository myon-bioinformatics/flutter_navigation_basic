import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/shared/diagnostics/route_diagnostics_observer.dart';
import 'package:flutter_application_1/shared/diagnostics/weight_badge_overlay.dart';

void main() {
  testWidgets('web diagnostics strip stays in the layout', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [RouteDiagnosticsObserver.instance],
        builder: (context, child) => Column(
          children: [
            Expanded(child: child ?? const SizedBox.shrink()),
            const WeightDiagnosticsStrip(),
          ],
        ),
        home: const Scaffold(body: Text('content')),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('content'), findsOneWidget);
    expect(find.textContaining('⚖'), findsOneWidget);
  });
}
