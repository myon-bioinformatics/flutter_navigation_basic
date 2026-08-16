import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/shared/widgets/home_overview_panel.dart';

void main() {
  testWidgets('home overview shows metrics and actions', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeOverviewPanel(
            actions: [
              HomeOverviewAction(
                label: 'Navigation Hub',
                subtitle: 'Browse patterns',
                icon: Icons.map_outlined,
                onTap: () => tapped = true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('792 · Reference patterns'), findsOneWidget);
    expect(find.text('Navigation Hub'), findsOneWidget);

    await tester.tap(find.text('Navigation Hub'));
    expect(tapped, isTrue);
  });
}
