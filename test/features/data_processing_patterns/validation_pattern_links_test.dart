import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/config/routes.dart';

void main() {
  for (var id = 91; id <= 99; id++) {
    testWidgets('screen$id exposes GitHub source and tests without fake execution',
        (tester) async {
      final route = AppRoutes.routes[AppRoutes.screenRoute(id)];
      expect(route, isNotNull);
      await tester.pumpWidget(MaterialApp(home: Builder(builder: route!)));
      expect(find.textContaining('Pattern ${id.toString().padLeft(3, '0')}'), findsOneWidget);
      expect(find.textContaining('限定実装'), findsOneWidget);
      expect(find.text('Python実装'), findsOneWidget);
      expect(find.text('Pythonテスト'), findsOneWidget);
      expect(find.text('実行'), findsNothing);
    });
  }

  testWidgets('GitHub link can be copied to clipboard', (tester) async {
    final copied = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied.add(call);
      return null;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding.instance
        .defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform, null));
    final route = AppRoutes.routes[AppRoutes.screenRoute(91)]!;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: route)));
    await tester.tap(find.byTooltip('Python実装 のURLをコピー'));
    await tester.pump();
    expect(copied, hasLength(1));
    expect(copied.single.arguments['text'],
        contains('tool/python/validation_patterns.py'));
  });
}
