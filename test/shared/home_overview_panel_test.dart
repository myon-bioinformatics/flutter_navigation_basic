import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/shared/diagnostics/build_metadata.dart';
import 'package:flutter_application_1/shared/widgets/home_overview_panel.dart';

class _RefreshHarness extends StatefulWidget {
  const _RefreshHarness({required this.actions, this.metadataLoader = BuildMetadata.load});

  final List<HomeOverviewAction> actions;
  final Future<BuildMetadata> Function() metadataLoader;

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
      body: HomeOverviewPanel(actions: widget.actions, metadataLoader: widget.metadataLoader),
    );
  }
}

BuildMetadata _fakeMetadata() {
  return BuildMetadata(
    version: 'unknown',
    buildNumber: 0,
    stage: 'unknown',
    platform: 'unmeasured',
    mode: 'unknown',
    artifactBytes: null,
    sourceBytes: null,
    assetBytes: null,
    revision: RevisionMetadata.fromJson(const {}),
    screens: const {},
    routeSources: const {},
  );
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
    var loadCount = 0;
    final completer = Completer<BuildMetadata>();
    Future<BuildMetadata> loader() {
      loadCount += 1;
      return completer.future;
    }

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
          metadataLoader: loader,
        ),
      ),
    );

    // Before the injected future resolves, the metric shows the loading
    // state and the loader has been invoked exactly once (on initState).
    expect(find.textContaining('loading…'), findsOneWidget);
    expect(loadCount, 1);

    completer.complete(_fakeMetadata());
    await tester.pumpAndSettle();

    // Once the initial metadata future resolves, the metric settles on the
    // "unknown" display sha (the fake metadata has no revision data).
    expect(find.textContaining('loading…'), findsNothing);
    expect(find.textContaining('unknown'), findsOneWidget);
    expect(loadCount, 1);

    // Mirrors HomeScreen's Refresh action, which calls setState on an
    // ancestor and rebuilds HomeOverviewPanel and its children.
    await tester.tap(find.byKey(const Key('refresh')));
    await tester.pump();

    // With the future cached, the rebuild must not reset the FutureBuilder
    // to a waiting state, so "loading…" should never reappear even for a
    // single frame, the previously resolved value stays put, and the
    // loader must not be invoked again.
    expect(find.textContaining('loading…'), findsNothing);
    expect(find.textContaining('unknown'), findsOneWidget);
    expect(loadCount, 1);
  });
}
