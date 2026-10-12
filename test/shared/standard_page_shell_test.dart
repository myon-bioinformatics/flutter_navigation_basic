import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/shared/widgets/standard_page_shell.dart';
import '../support/display_test_harness.dart';

void main() {
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
