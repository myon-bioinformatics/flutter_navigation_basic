import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/irony_generator/domain/irony_generator_controller.dart';
import 'package:flutter_application_1/features/irony_generator/presentation/irony_generator_page.dart';
import 'package:flutter_application_1/shared/widgets/tool_door_selector.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/display_test_harness.dart';

Future<Widget> _app(Widget child) async =>
    MaterialApp(home: await wrapWithDisplayScope(child));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('irony page exposes tone filters, favorite, and Door',
      (tester) async {
    await tester.pumpWidget(
      await _app(IronyGeneratorPage(controller: IronyGeneratorController())),
    );
    await tester.pumpAndSettle();

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Tech'), findsWidgets);
    expect(find.text('Generate again'), findsOneWidget);
    expect(find.text('Favorite'), findsOneWidget);
    expect(find.byType(ToolDoorSelector), findsOneWidget);

    await tester.tap(find.text('Favorite'));
    await tester.pump();
    expect(find.text('Favorited'), findsOneWidget);
    expect(find.text('Favorites · 1'), findsOneWidget);
  });

  testWidgets('irony generate again refreshes recent history', (tester) async {
    await tester.pumpWidget(
      await _app(IronyGeneratorPage(controller: IronyGeneratorController())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Generate again'));
    await tester.pump();

    expect(find.byTooltip('Remove from recent'), findsOneWidget);
  });
}
