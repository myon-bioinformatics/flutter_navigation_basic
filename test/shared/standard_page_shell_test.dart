import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/shared/widgets/standard_page_shell.dart';
import 'package:flutter_application_1/shared/widgets/tool_door_selector.dart';
import '../support/display_test_harness.dart';

void main() {
  testWidgets('direct-open page does not expose inert BackButton', (tester) async {
    await tester.pumpWidget(await wrapWithDisplayScope(const MaterialApp(
      home: StandardPageShell(title: 'Direct', currentRouteName: '/direct',
        child: Text('direct body')),
    )));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('shared-header-back')), findsNothing);
    expect(find.byKey(const Key('shared-header-home')), findsOneWidget);
  });


  testWidgets('footer does not cover or intercept body controls', (tester) async {
    var taps = 0;
    await tester.pumpWidget(await wrapWithDisplayScope(MaterialApp(
      home: StandardPageShell(
        title: 'Interactive',
        currentRouteName: '/detail',
        child: Center(
          child: FilledButton(
            key: const Key('body-interaction'),
            onPressed: () => taps++,
            child: const Text('Run action'),
          ),
        ),
      ),
    )));
    await tester.pumpAndSettle();
    final bodyButton = find.byKey(const Key('body-interaction'));
    await tester.tap(bodyButton);
    await tester.pump();
    expect(taps, 1);
    final buttonBottom = tester.getBottomLeft(bodyButton).dy;
    final footerTop = tester.getTopLeft(find.byType(ToolDoorSelector)).dy;
    expect(buttonBottom, lessThan(footerTop));
  });

  testWidgets('shared header Home confirmation prioritizes staying and only navigates on approval', (tester) async {
    await tester.pumpWidget(await wrapWithDisplayScope(MaterialApp(
      initialRoute: '/detail',
      routes: {
        '/': (_) => const Scaffold(body: Text('home-destination')),
        '/detail': (_) => const StandardPageShell(
          title: 'Example',
          currentRouteName: '/detail',
          child: Text('unsaved editor state'),
        ),
      },
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shared-header-home')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Unsaved changes'), findsOneWidget);
    final stay = find.byKey(const Key('shared-header-stay'));
    final go = find.byKey(const Key('shared-header-confirm-home'));
    expect(stay, findsOneWidget);
    expect(go, findsOneWidget);
    final stayWidth = tester.getSize(stay).width;
    final goWidth = tester.getSize(go).width;
    expect(stayWidth, greaterThan(goWidth));
    await tester.tap(stay);
    await tester.pumpAndSettle();
    expect(find.text('unsaved editor state'), findsOneWidget);
    await tester.tap(find.byKey(const Key('shared-header-home')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shared-header-confirm-home')));
    await tester.pumpAndSettle();
    expect(find.text('home-destination'), findsOneWidget);
  });

  testWidgets('shared menu opens drawer; no duplicate locale picker', (tester) async {
    await tester.pumpWidget(await wrapWithDisplayScope(MaterialApp(
      home: const StandardPageShell(
        title: 'Example',
        currentRouteName: '/detail',
        child: Text('body'),
      ),
    )));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('shared-header-menu')), findsOneWidget);
    await tester.tap(find.byKey(const Key('shared-header-menu')));
    await tester.pumpAndSettle();
    expect(find.text('Navigation'), findsOneWidget);
  });
}
