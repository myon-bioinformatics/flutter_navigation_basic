import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/shared/widgets/home_overview_panel.dart';

class _RefreshHarness extends StatefulWidget {
  const _RefreshHarness({required this.actions});

  final List<HomeOverviewAction> actions;

  @override
  State<_RefreshHarness> createState() => _RefreshHarnessState();
}

class _RefreshHarnessState extends State<_RefreshHarness> {
  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            key: const Key('refresh'),
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: HomeOverviewPanel(actions: widget.actions),
    );
  }
}

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

  testWidgets('revision metric does not flash back to loading on a parent rebuild', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: _RefreshHarness(
          actions: [
            HomeOverviewAction(
              label: 'Navigation Hub',
              subtitle: 'Browse patterns',
              icon: Icons.map_outlined,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The checked-in build_meta.json has no revision data, so the metric
    // settles on the "unknown" display sha rather than "loading…".
    expect(find.textContaining('loading…'), findsNothing);
    expect(find.textContaining('unknown'), findsOneWidget);

    // Mirrors HomeScreen's Refresh action, which calls setState on an
    // ancestor and rebuilds HomeOverviewPanel and its children.
    await tester.tap(find.byKey(const Key('refresh')));
    await tester.pump();

    // With the future cached, the rebuild must not reset the FutureBuilder
    // to a waiting state, so "loading…" should never reappear even for a
    // single frame, and the previously resolved value stays put.
    expect(find.textContaining('loading…'), findsNothing);
    expect(find.textContaining('unknown'), findsOneWidget);
  });
}
