import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/config/routes.dart';
import 'package:flutter_application_1/screens/generic_screen.dart';
import 'package:flutter_application_1/screens/pattern_template_screen.dart';
import 'package:flutter_application_1/shared/widgets/standard_page_footer.dart';
import 'package:flutter_application_1/shared/widgets/standard_page_shell.dart';
import 'package:flutter_application_1/shared/widgets/tool_door_selector.dart';
import 'package:flutter_application_1/shared/display/display_scope.dart';

import '../support/display_test_harness.dart';

Future<void> _pumpGeneric(
  WidgetTester tester,
  int screenId, {
  DisplayController? controller,
  bool preloadCatalogue = true,
  TextScaler? textScaler,
  Map<String, WidgetBuilder> routes = const {},
}) async {
  final resolvedController = controller ?? await loadTestDisplayController();
  // Asset decoding can use a real isolate. Complete it outside the widget
  // fake clock; cached rootBundle futures otherwise outlive a prior test zone.
  if (preloadCatalogue) await tester.runAsync(ScreensConfig.load);
  await tester.pumpWidget(
    MaterialApp(
      routes: routes,
      builder: textScaler == null ? null : (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: DisplayScope(controller: resolvedController, child: GenericScreen(screenId: screenId)),
    ),
  );
  // GenericScreen loads assets/screens.json asynchronously; wait for the spinner to clear.
  for (var attempt = 0; attempt < 200; attempt++) {
    await tester.pump();
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) return;
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
  }
  await tester.pump();
}

// SliverLayoutBuilder intentionally does not build a template outside the
// viewport/cache region. Materialize it through bounded real outer gestures
// before asking finders to inspect its controls; do not change production cache.
Future<void> _materializeGenericTemplate(WidgetTester tester) async {
  final viewport = find.byKey(const Key('generic-template-viewport'));
  final outer = find.descendant(
    of: find.byKey(const Key('generic-body-scroll')),
    matching: find.byType(Scrollable),
  ).first;
  expect(outer, findsOneWidget);
  final positions = <Map<String, double>>[];
  Map<String, double> position() {
    final value = tester.state<ScrollableState>(outer).position;
    return {'pixels': value.pixels, 'min': value.minScrollExtent,
      'max': value.maxScrollExtent, 'viewport': value.viewportDimension};
  }
  for (var attempt = 0; attempt < 12 && viewport.evaluate().isEmpty; attempt++) {
    final bounds = tester.getRect(outer);
    expect(bounds.width, greaterThan(6));
    expect(bounds.height, greaterThan(24));
    positions.add(position());
    // The left edge avoids dispatching the drag to nested template scrollables.
    await tester.dragFrom(bounds.topLeft + const Offset(3, 24),
        const Offset(0, -120));
    await tester.pumpAndSettle();
    positions.add(position());
  }
  if (positions.isNotEmpty) {
    expect(positions.last['pixels']!, greaterThan(positions.first['pixels']!),
        reason: 'Outer gestures must actually move the viewport: $positions');
    final last = positions.last;
    expect(last.values.every((value) => value.isFinite), isTrue,
        reason: 'Outer extent must remain finite: $positions');
    expect(last['pixels']!, inInclusiveRange(last['min']!, last['max']!),
        reason: 'Settled outer offset must be within its extent: $positions');
  }
  expect(viewport, findsOneWidget,
      reason: 'Template not materialized after bounded outer drags: $positions');
}

// Keep nested-scroll failures diagnostic: a visible outer body alone does not
// establish that a whole control fits its inner list/grid viewport.
List<Map<String, Object>> _scrollGeometry(WidgetTester tester, Finder target) {
  final geometry = <Map<String, Object>>[];
  tester.element(target).visitAncestorElements((element) {
    if (element is StatefulElement && element.state is ScrollableState) {
      final state = element.state as ScrollableState;
      final render = element.findRenderObject();
      if (render is RenderBox && render.hasSize) {
        geometry.add({
          'viewport': render.localToGlobal(Offset.zero) & render.size,
          'axis': state.position.axis,
          'pixels': state.position.pixels,
          'min': state.position.minScrollExtent,
          'max': state.position.maxScrollExtent,
          'viewportDimension': state.position.viewportDimension,
        });
      }
    }
    return true;
  });
  return geometry;
}

void main() {
  testWidgets('numbered catalogue page includes shared navigation footer', (tester) async {
    await _pumpGeneric(tester, 6);
    expect(find.byType(StandardPageShell), findsOneWidget);
    expect(find.byType(StandardPageFooter), findsOneWidget);
    expect(find.byType(ToolDoorSelector), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
  });

  testWidgets('non-detail screen shows translated Back-to-Hub and pattern chips', (tester) async {
    // Screen 3 is in the "realtime" domain, which has no ScreenDetail payload.
    // Its raw description sentence ("Navigation: BasicReplace, API: HttpPut, ...")
    // also renders on the page, so match the exact pattern-chip text rather than
    // a substring that both the chip and the description sentence contain.
    await _pumpGeneric(tester, 3);

    expect(find.text('Back to Hub'), findsWidgets);
    expect(find.byKey(const Key('back-to-hub')), findsOneWidget);
    expect(find.text('Navigation: BasicReplace'), findsOneWidget);
    expect(find.text('API: HttpPut'), findsOneWidget);
    expect(find.text('Theme: TextButton'), findsOneWidget);
    expect(find.text('Data: FilterNested'), findsOneWidget);
  });

  testWidgets('Back to Hub is tappable and navigates', (tester) async {
    await _pumpGeneric(
      tester,
      3,
      routes: {
        AppRoutes.hub: (_) => const Scaffold(body: Text('Hub route reached')),
      },
    );

    final backToHub = find.byKey(const Key('back-to-hub'));
    expect(backToHub, findsOneWidget);
    await tester.tap(backToHub, warnIfMissed: true);
    await tester.pumpAndSettle();

    expect(find.text('Hub route reached'), findsOneWidget);
  });

  // Same-node contract for #97/#99: identifier, tap, and label must share
  // the Key-backed semantics node (fix A / excludeSemantics).
  testWidgets('Back to Hub semantics keep identifier with tap', (tester) async {
    final handle = tester.ensureSemantics();
    try {
      await _pumpGeneric(tester, 3);
      final node = tester.getSemantics(find.byKey(const Key('back-to-hub')));
      final data = node.getSemanticsData();
      expect(node.identifier, 'back-to-hub');
      expect(data.hasFlag(SemanticsFlag.isButton), isTrue);
      expect(data.hasFlag(SemanticsFlag.hasEnabledState), isTrue);
      expect(data.hasFlag(SemanticsFlag.isEnabled), isTrue);
      expect(data.hasFlag(SemanticsFlag.isFocusable), isTrue);
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      expect(data.hasAction(SemanticsAction.focus), isTrue);
      expect(node.label, 'Back to Hub');

      tester.binding.pipelineOwner.semanticsOwner!
          .performAction(node.id, SemanticsAction.focus);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'back-to-hub');

      var children = 0;
      node.visitChildren((_) {
        children++;
        return true;
      });
      expect(children, 0, reason: 'excludeSemantics must not leave a second tappable child');
    } finally {
      handle.dispose();
    }
  });

  testWidgets('detail screen shows translated tab labels and use-case section headers', (tester) async {
    // Screen 1 is in the "integration" domain, which carries a ScreenDetail payload.
    await _pumpGeneric(tester, 1);

    expect(find.text('Use case'), findsOneWidget);
    expect(find.text('UI sample'), findsOneWidget);

    await tester.tap(find.text('Use case'));
    await tester.pumpAndSettle();

    expect(find.text('Purpose'), findsOneWidget);
    expect(find.text('When to use'), findsOneWidget);
    expect(find.text('Design points'), findsOneWidget);
    expect(find.text('Pitfall'), findsOneWidget);
    expect(find.text('Snippet'), findsOneWidget);
  });

  testWidgets('Screen6 load failure shows error and retry succeeds once',
      (tester) async {
    var calls = 0;
    ScreensConfig.resetCache(loader: () async {
      calls++;
      if (calls == 1) {
        throw StateError('synthetic catalogue failure');
      }
      return const [
        ScreenData(
          screenDataId: 6,
          name: 'Screen6',
          title: 'Search',
          emoji: '🔎',
          description: 'Search catalogue',
          category: 'navigation',
          navigationPattern: '',
          apiPattern: '',
          themePattern: '',
          dataPattern: '',
          useCaseJa: '検索結果一覧',
          useCaseEn: 'Search Results',
        ),
        ScreenData(
          screenDataId: 5,
          name: 'Screen5',
          title: 'Results',
          emoji: '🔢',
          description: 'Results',
          category: 'navigation',
          navigationPattern: '',
          apiPattern: '',
          themePattern: '',
          dataPattern: '',
          useCaseJa: '変換結果一覧',
          useCaseEn: 'Transformed Result List',
        ),
      ];
    });
    addTearDown(() => ScreensConfig.resetCache());

    await _pumpGeneric(tester, 6, preloadCatalogue: false);
    expect(calls, 1);
    expect(find.text('Could not load screens.'), findsOneWidget);
    expect(find.byKey(const Key('screen6-catalog-search')), findsNothing);

    final retry = find.widgetWithText(FilledButton, 'Refresh');
    expect(retry, findsOneWidget);
    await tester.tap(retry);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(find.text('Could not load screens.'), findsNothing);
    expect(find.byKey(const Key('screen6-catalog-search')), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);
  });

  testWidgets('Screen6 searches the real catalogue and opens an existing route',
      (tester) async {
    await _pumpGeneric(
      tester,
      6,
      routes: {
        AppRoutes.screenRoute(5): (_) =>
            const Scaffold(body: Text('Screen5 route reached')),
      },
    );

    expect(find.byKey(const Key('screen6-catalog-search')), findsOneWidget);
    expect(find.text('198 / 198'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('screen6-catalog-search')),
      'Transformed Result List',
    );
    await tester.pump();

    expect(find.byKey(const Key('screen6-result-5')), findsOneWidget);
    expect(find.text('1 / 198'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Semantics &&
            widget.properties.identifier == 'screen6-result-5',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Semantics &&
            widget.properties.identifier == 'screen6-result-count',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('screen6-result-5')));
    await tester.pumpAndSettle();
    expect(find.text('Screen5 route reached'), findsOneWidget);
  });

  for (final initialHeight in const [757.0, 500.0]) {
    testWidgets('Screen6 preserves search state across compact resize from $initialHeight',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(1180, initialHeight);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await _pumpGeneric(tester, 6);

      final field = find.byKey(const Key('screen6-catalog-search'));
      final body = find.byWidgetPredicate(
        (widget) => widget is Semantics &&
            widget.properties.identifier == 'screen6-body',
      );
      const query = 'Transformed Result List';
      await tester.ensureVisible(field);
      await tester.enterText(field, query);
      await tester.pumpAndSettle();
      final controller = tester.widget<TextField>(field).controller!;
      final focusNode = tester.widget<EditableText>(find.byType(EditableText)).focusNode;
      const selection = TextSelection(baseOffset: 4, extentOffset: 10);
      controller.selection = selection;
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);
      expect(find.text('1 / 198'), findsOneWidget);
      expect(tester.getSize(body).height < 480, initialHeight == 500);

      final otherHeight = initialHeight == 757 ? 500.0 : 757.0;
      final boundaryHeight = initialHeight + 480 - tester.getSize(body).height;
      for (final height in [
        otherHeight, initialHeight,
        boundaryHeight - 1, boundaryHeight, boundaryHeight + 1,
        otherHeight, initialHeight,
      ]) {
        tester.view.physicalSize = Size(1180, height);
        await tester.pumpAndSettle();
        expect(tester.getSize(body).height, closeTo(480 + height - boundaryHeight, 0.01));
        expect(tester.widget<TextField>(field).controller!.text, query);
        expect(tester.widget<TextField>(field).controller, same(controller));
        expect(controller.selection, selection);
        expect(tester.widget<EditableText>(find.byType(EditableText)).focusNode,
            same(focusNode));
        expect(focusNode.hasFocus, isTrue);
        expect(find.text('1 / 198'), findsOneWidget);
        expect(find.byKey(const Key('screen6-result-5')), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  }

  for (final locale in const ['eng', 'jpn']) {
    testWidgets('Screen6 search identifier retains editable semantics in $locale',
        (tester) async {
      final handle = tester.ensureSemantics();
      try {
        final controller = await loadTestDisplayController(
          initialValues: {DisplayController.preferenceKey: locale},
        );
        await _pumpGeneric(tester, 6, controller: controller);

        final region = find.byWidgetPredicate(
          (widget) => widget is Semantics &&
              widget.properties.identifier == 'screen6-search',
        );
        expect(region, findsOneWidget);
        final node = tester.getSemantics(region);
        expect(node.identifier, 'screen6-search');
        final fields = <SemanticsNode>[];
        void collectFields(SemanticsNode parent) {
          parent.visitChildren((child) {
            if (child.getSemanticsData().hasFlag(SemanticsFlag.isTextField)) {
              fields.add(child);
            }
            collectFields(child);
            return true;
          });
        }

        collectFields(node);
        expect(fields, hasLength(1));
        final field = find.byKey(const Key('screen6-catalog-search'));
        expect(
          tester.widget<TextField>(field).decoration!.hintText,
          controller.text('hub.searchHint'),
        );

        // Keep the stable identifier contract, but verify editability through
        // the real widget instead of pinning a framework-specific semantics
        // action that can vary across Flutter versions.
        await tester.enterText(field, 'Transformed Result List');
        await tester.pump();
        expect(find.text('1 / 198'), findsOneWidget);
        expect(find.byKey(const Key('screen6-result-5')), findsOneWidget);
        expect(region, findsOneWidget);
        expect(tester.getSemantics(region).identifier, 'screen6-search');
        expect(find.byKey(const Key('screen6-catalog-clear')), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        handle.dispose();
      }
    });
  }

  testWidgets('Screen6 supports Japanese search, empty results, and clear',
      (tester) async {
    await _pumpGeneric(tester, 6);

    final field = find.byKey(const Key('screen6-catalog-search'));
    await tester.enterText(field, '変換結果一覧');
    await tester.pump();
    expect(find.byKey(const Key('screen6-result-5')), findsOneWidget);

    await tester.enterText(field, 'definitely-no-such-screen');
    await tester.pump();
    expect(find.text('No screens found.'), findsOneWidget);
    expect(find.text('0 / 198'), findsOneWidget);

    await tester.tap(find.byKey(const Key('screen6-catalog-clear')));
    await tester.pump();
    expect(find.text('198 / 198'), findsOneWidget);
  });

  // Regression: at 390x500 the fixed metadata/chips previously left zero
  // template height (or only 21/37px for 80/48px navigation/tab controls).
  // Presence in the widget tree is insufficient: reveal and hit-test content.
  final compactTargets = <int, Finder Function()>{
    3: () => find.ancestor(
        of: find.text('BasicReplace item 1'), matching: find.byType(ListTile)),
    21: () => find.text('Screen ID: 21'),
    39: () => find.byType(TextField),
    57: () => find.byType(TextField),
    75: () => find.byType(TabBar),
    100: () => find.byType(NavigationBar),
    111: () => find.text('Drawer-style navigation sample'),
    129: () => find.text('Open dialog'),
    147: () => find.ancestor(
        of: find.text('AnimatedCrossFade\n#1'), matching: find.byType(Card)),
    165: () => find.text('Simulate async task'),
    185: () => find.byType(SwitchListTile),
  };
  for (final entry in compactTargets.entries) {
    testWidgets('Screen${entry.key} compact template is reachable above Door',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 500);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await _pumpGeneric(tester, entry.key);
      await _materializeGenericTemplate(tester);
      final target = find.descendant(
        of: find.byType(PatternTemplateBody), matching: entry.value());
      expect(target, findsOneWidget);
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      final body = find.byWidgetPredicate((widget) => widget is Semantics &&
          widget.properties.identifier == 'generic-body');
      final visible = tester.getRect(body);
      final bounds = tester.getRect(target);
      final scrolls = _scrollGeometry(tester, target);
      final geometry = 'Screen${entry.key}: target=$bounds, body=$visible, '
          'Door=${tester.getRect(find.byType(ToolDoorSelector))}, '
          'scrolls=$scrolls';
      expect(bounds.width, greaterThan(0), reason: geometry);
      expect(bounds.height, greaterThan(0), reason: geometry);
      expect(bounds.top, greaterThanOrEqualTo(visible.top - 0.01),
          reason: geometry);
      expect(bounds.bottom, lessThanOrEqualTo(visible.bottom + 0.01),
          reason: geometry);
      for (final scroll in scrolls) {
        if (scroll['axis'] != Axis.vertical) continue;
        final viewport = scroll['viewport']! as Rect;
        expect(bounds.height, lessThanOrEqualTo(viewport.height + 0.01),
            reason: 'Whole control must fit inner viewport. $geometry');
        expect(bounds.top, greaterThanOrEqualTo(viewport.top - 0.01),
            reason: geometry);
        expect(bounds.bottom, lessThanOrEqualTo(viewport.bottom + 0.01),
            reason: geometry);
      }
      expect(target.hitTestable(), findsOneWidget);
      expect(bounds.bottom,
          lessThanOrEqualTo(tester.getRect(find.byType(ToolDoorSelector)).top));
      expect(tester.takeException(), isNull);
      if (entry.key == 39) {
        await tester.enterText(target, 'state stays reachable');
        final submit = find.text('Submit');
        await tester.ensureVisible(submit);
        await tester.pumpAndSettle();
        expect(submit.hitTestable(), findsOneWidget);
        expect(tester.getRect(submit).bottom,
            lessThanOrEqualTo(tester.getRect(body).bottom + 0.01));
      }
    });
  }

  testWidgets('Generic measured metadata cannot consume the finite template viewport',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 500);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await _pumpGeneric(tester, 147, textScaler: const TextScaler.linear(1.25));
    await _materializeGenericTemplate(tester);
    final metadata = find.byKey(const Key('generic-metadata'));
    final viewport = find.byKey(const Key('generic-template-viewport'));
    final body = find.byWidgetPredicate((widget) => widget is Semantics &&
        widget.properties.identifier == 'generic-body');
    final outer = tester.state<ScrollableState>(find.descendant(
      of: find.byKey(const Key('generic-body-scroll')),
      matching: find.byType(Scrollable),
    ).first);
    final metadataHeight = tester.getSize(metadata).height;
    expect(metadataHeight, greaterThan(0));
    expect(tester.getSize(viewport).height, 240);
    expect(outer.position.maxScrollExtent,
        closeTo(metadataHeight + 240 - tester.getSize(body).height, 0.01));
    final card = find.ancestor(
        of: find.text('AnimatedCrossFade\n#1'), matching: find.byType(Card));
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    final bounds = tester.getRect(card);
    final visible = tester.getRect(body).intersect(tester.getRect(viewport));
    expect(bounds.top, greaterThanOrEqualTo(visible.top - 0.01));
    expect(bounds.bottom, lessThanOrEqualTo(visible.bottom + 0.01));
    expect(card.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Generic form preserves edit controller focus and selection on resize',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 500);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await _pumpGeneric(tester, 39);
    await _materializeGenericTemplate(tester);
    final field = find.byType(TextField);
    await tester.ensureVisible(field);
    await tester.enterText(field, 'resize-safe input');
    await tester.pumpAndSettle();
    final controller = tester.widget<TextField>(field).controller!;
    final focus = tester.widget<EditableText>(find.byType(EditableText)).focusNode;
    const selection = TextSelection(baseOffset: 2, extentOffset: 7);
    controller.selection = selection;
    final body = find.byWidgetPredicate((widget) => widget is Semantics &&
        widget.properties.identifier == 'generic-body');
    final metadataHeight = tester.getSize(find.byKey(const Key('generic-metadata'))).height;
    final templateViewport = find.byKey(const Key('generic-template-viewport'));
    final originalTemplate = tester.element(templateViewport);
    final threshold = 500 + metadataHeight + 240 - tester.getSize(body).height;
    for (final size in [
      const Size(1180, 757), const Size(390, 500),
      Size(390, threshold - 1), Size(390, threshold),
      Size(390, threshold + 1), const Size(1180, 757),
      const Size(390, 500),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      await _materializeGenericTemplate(tester);
      await tester.ensureVisible(field);
      await tester.pumpAndSettle();
      expect(tester.element(templateViewport), same(originalTemplate));
      final remaining = tester.getSize(body).height -
          tester.getSize(find.byKey(const Key('generic-metadata'))).height;
      expect(tester.getSize(templateViewport).height,
          closeTo(remaining < 240 ? 240 : remaining, 0.01));
      expect(tester.widget<TextField>(field).controller, same(controller));
      expect(controller.text, 'resize-safe input');
      expect(controller.selection, selection);
      expect(tester.widget<EditableText>(find.byType(EditableText)).focusNode,
          same(focus));
      expect(focus.hasFocus, isTrue);
      expect(field.hitTestable(), findsOneWidget);
      expect(tester.getRect(field).top,
          greaterThanOrEqualTo(tester.getRect(body).top - 0.01));
      expect(tester.getRect(field).bottom,
          lessThanOrEqualTo(tester.getRect(body).bottom + 0.01));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('fresh Generic route has independent editor and pop restores prior state',
      (tester) async {
    final display = await loadTestDisplayController();
    await _pumpGeneric(tester, 39, controller: display, routes: {
      '/fresh-generic': (_) => DisplayScope(
          controller: display, child: const GenericScreen(screenId: 57)),
    });
    await _materializeGenericTemplate(tester);
    final field = find.descendant(
        of: find.byType(PatternTemplateBody), matching: find.byType(TextField));
    await tester.ensureVisible(field);
    await tester.enterText(field, 'first route');
    final firstController = tester.widget<TextField>(field).controller;
    Navigator.of(tester.element(find.byType(GenericScreen)))
        .pushNamed('/fresh-generic');
    await tester.pumpAndSettle();
    await _materializeGenericTemplate(tester);
    await tester.ensureVisible(field);
    final secondController = tester.widget<TextField>(field).controller;
    expect(secondController, isNot(same(firstController)));
    expect(secondController!.text, isEmpty);
    await tester.enterText(field, 'second route');
    Navigator.of(tester.element(find.byType(GenericScreen))).pop();
    await tester.pumpAndSettle();
    await _materializeGenericTemplate(tester);
    expect(tester.widget<TextField>(field).controller, same(firstController));
    expect(firstController!.text, 'first route');
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders translated chrome for a non-English display locale', (tester) async {
    final controller = await loadTestDisplayController(
      initialValues: {DisplayController.preferenceKey: 'jpn'},
    );

    await _pumpGeneric(tester, 3, controller: controller);

    expect(find.text('ハブに戻る'), findsWidgets);
    expect(find.text('ナビゲーション: BasicReplace'), findsOneWidget);
  });
}
