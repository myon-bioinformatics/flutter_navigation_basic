import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/coordinate_tool/presentation/coordinate_tool_page.dart';
import 'package:flutter_application_1/screens/home_screen.dart';
import 'package:flutter_application_1/shared/display/display_scope.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/display_test_harness.dart';

void main() {
  Future<void> pumpWithLocale(
    WidgetTester tester, {
    required String locale,
    required Widget home,
  }) async {
    final controller = await loadTestDisplayController(
      initialValues: {DisplayController.preferenceKey: locale},
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: controller.flutterLocale,
        home: DisplayScope(controller: controller, child: home),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('German home chrome renders without RenderFlex overflow', (tester) async {
    final errors = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details);
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);

    await pumpWithLocale(
      tester,
      locale: 'deu',
      home: const HomeScreen(),
    );

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(
      errors.where((e) => e.exceptionAsString().contains('overflowed')),
      isEmpty,
      reason: errors.map((e) => e.exceptionAsString()).join('\n'),
    );
  });

  testWidgets('German coordinate tool chrome renders without RenderFlex overflow', (tester) async {
    final errors = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details);
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);

    await pumpWithLocale(
      tester,
      locale: 'deu',
      home: const CoordinateToolPage(),
    );

    expect(find.byType(CoordinateToolPage), findsOneWidget);
    expect(
      errors.where((e) => e.exceptionAsString().contains('overflowed')),
      isEmpty,
      reason: errors.map((e) => e.exceptionAsString()).join('\n'),
    );
  });
}
