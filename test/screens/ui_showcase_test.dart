import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/screens/ui_showcase_screen.dart';

void main() {
  testWidgets('UI showcase loads external config and compact navigation',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: UiShowcaseScreen()));
    await tester.pumpAndSettle();

    expect(find.text('UI Showcase'), findsWidgets);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(Drawer), findsOneWidget);
    expect(find.text('Internal defaults'), findsOneWidget);
    expect(find.text('External JSON overrides'), findsOneWidget);
  });

  testWidgets('UI showcase renders Base64 media with Image.memory',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: UiShowcaseScreen()));
    await tester.pumpAndSettle();

    final mediaDestination = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Media'),
    );
    await tester.tap(mediaDestination);
    await tester.pumpAndSettle();

    expect(find.text('Embedded media'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Video intentionally optional'), findsOneWidget);
  });
}
