import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/home/domain/home_controller.dart';
import 'package:flutter_application_1/features/home/presentation/home_screen.dart';
import 'package:flutter_application_1/screens/generic_screen.dart';
import 'package:flutter_application_1/shared/widgets/home_overview_panel.dart';
import 'package:flutter_application_1/shared/display/display_scope.dart';

import '../../../support/display_test_harness.dart';

Future<void> _pumpHome(WidgetTester tester, {DisplayController? controller, Random? random}) async {
  final resolvedController = controller ?? await loadTestDisplayController();
  await tester.pumpWidget(
    MaterialApp(
      home: DisplayScope(
        controller: resolvedController,
        child: HomeScreen(controller: HomeController(), discoveryRandom: random),
      ),
    ),
  );
}

final sampleScreens = <ScreenData>[
  ScreenData(
    screenDataId: 5, name: 'Screen5', title: 'Legacy', emoji: '🔗',
    description: 'Legacy static link', category: 'api',
    navigationPattern: '', apiPattern: '', themePattern: '', dataPattern: '',
  ),
  for (var id = 6; id <= 9; id++)
    ScreenData(
      screenDataId: id, name: 'Screen$id', title: 'Pattern $id', emoji: '📱',
      description: 'Discovery pattern $id', category: 'navigation',
      navigationPattern: '', apiPattern: '', themePattern: '', dataPattern: '',
    ),
];

class _SequentialRandom implements Random {
  int next = 0;
  @override
  int nextInt(int max) => (next++) % max;
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0.0;
}

void main() {
  testWidgets('refresh selects the next Python-generated triple', (tester) async {
    final rows = (jsonDecode(await rootBundle.loadString('assets/home_discovery_draws.json'))
        as Map<String, dynamic>)['draws'] as List;
    final first = (rows[0] as List).cast<int>();
    final second = (rows[1] as List).cast<int>();
    expect(first.toSet(), isNot(equals(second.toSet())));

    final fullCatalog = <ScreenData>[
      for (var id = 6; id <= 198; id++)
        ScreenData(
          screenDataId: id, name: 'Screen$id', title: 'Pattern $id',
          emoji: '📱', description: 'Discovery pattern $id',
          category: 'navigation', navigationPattern: '', apiPattern: '',
          themePattern: '', dataPattern: '',
        ),
    ];
    ScreensConfig.resetCache(loader: () async => fullCatalog);
    await _pumpHome(tester, random: _SequentialRandom());
    await tester.pumpAndSettle();
    for (final id in first) {
      expect(find.text('Screen$id · Pattern $id'), findsOneWidget);
    }
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();
    for (final id in second) {
      expect(find.text('Screen$id · Pattern $id'), findsOneWidget);
    }
  });

  setUp(() {
    ScreensConfig.resetCache(loader: () async => sampleScreens);
  });

  tearDown(() {
    ScreensConfig.resetCache();
  });

  test('runtime consumes proposed Python draw and handles sparse catalog', () {
    final selected = pickHomeDiscoveryScreens(sampleScreens, [[9, 7, 6]], random: Random(42));
    expect(selected.map((s) => s.screenDataId), [9, 7, 6]);
    expect(selected.length, 3);
    expect(selected.map((s) => s.screenDataId).toSet().length, 3);
    expect(selected.every((s) => s.screenDataId >= 6), isTrue);
    expect(pickHomeDiscoveryScreens(sampleScreens.take(1).toList(), [[9, 7, 6]],
        random: Random(42)).length, 0);
    expect(pickHomeDiscoveryScreens(sampleScreens.skip(1).take(2).toList(), [[9, 7, 6]],
        random: Random(42)).length, 2);
  });

  test('candidate selection does not promote fixed Screen5', () {
    final proposed = pickHomeDiscoveryScreens(
        sampleScreens, [[9, 7, 6]], random: Random(42));
    expect(proposed.map((screen) => screen.screenDataId), [9, 7, 6]);
    expect(proposed.any((screen) => screen.screenDataId == 5), isFalse);
  });

  testWidgets('renders catalog-driven action cards and a weekday-aware date', (tester) async {
    await _pumpHome(tester);

    expect(find.text('Home 🏠'), findsOneWidget);

    final now = DateTime.now();
    const englishWeekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final expectedWeekday = englishWeekdays[now.weekday - 1];
    expect(find.textContaining('($expectedWeekday)'), findsOneWidget);
  });

  testWidgets('renders translated chrome and weekday for a non-English display locale', (tester) async {
    final controller = await loadTestDisplayController(
      initialValues: {DisplayController.preferenceKey: 'jpn'},
    );

    await _pumpHome(tester, controller: controller);

    expect(find.text('ホーム 🏠'), findsOneWidget);

    final now = DateTime.now();
    const japaneseWeekdays = ['月', '火', '水', '木', '金', '土', '日'];
    final expectedWeekday = japaneseWeekdays[now.weekday - 1];
    expect(find.textContaining('($expectedWeekday)'), findsOneWidget);
  });
}
