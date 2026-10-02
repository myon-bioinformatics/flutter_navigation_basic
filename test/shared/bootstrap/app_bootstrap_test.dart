import 'package:flutter/material.dart';
import 'package:flutter_application_1/shared/bootstrap/app_bootstrap.dart';
import 'package:flutter_application_1/shared/display/display_locale_codes.dart';
import 'package:flutter_application_1/shared/display/display_scope.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('catalog failure reaches the explicit startup error', (
    tester,
  ) async {
    final reported = <FlutterErrorDetails>[];
    final original = FlutterError.onError;
    FlutterError.onError = reported.add;
    addTearDown(() => FlutterError.onError = original);

    await bootstrapApp(
      app: const Text('app', textDirection: TextDirection.ltr),
      loadDisplay: () => DisplayController.load(
        catalogLoader: () => throw StateError('catalog missing'),
      ),
    );
    await tester.pump();

    expect(find.byType(StartupErrorApp), findsOneWidget);
    expect(find.textContaining('catalog missing'), findsOneWidget);
    expect(find.text('app'), findsNothing);
    expect(reported, hasLength(1));
  });

  testWidgets('preferences failure still renders usable UI in default locale',
      (tester) async {
    await bootstrapApp(
      app: Builder(
        builder: (context) => Text(
          DisplayScope.of(context).locale,
          textDirection: TextDirection.ltr,
        ),
      ),
      loadDisplay: () => DisplayController.load(
        preferencesLoader: () => throw StateError('storage rejected'),
      ),
    );
    await tester.pump();

    expect(find.byType(StartupErrorApp), findsNothing);
    expect(find.text(DisplayLocaleCodes.eng), findsOneWidget);
  });

  test('setLocale without persistence updates in-memory locale', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = await DisplayController.load(
      preferencesLoader: () => throw StateError('storage rejected'),
    );
    await controller.setLocale('jpn');
    expect(controller.locale, 'jpn');
  });
}
