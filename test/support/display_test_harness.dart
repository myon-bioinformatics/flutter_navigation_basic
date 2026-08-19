import 'package:flutter/material.dart';
import 'package:flutter_application_1/shared/display/display_scope.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Loads a [DisplayController] deterministically for widget tests.
///
/// `DisplayController.load()` performs real asynchronous work before any widget
/// is pumped: it loads the display catalog from `rootBundle`, then opens
/// `SharedPreferences`. Running that future directly inside `testWidgets`
/// executes it in the fake-async zone and can deadlock until the framework's
/// per-test timeout. Seed preferences synchronously, then perform the bootstrap
/// through the binding's real-async escape hatch so the asset/platform futures
/// can complete normally.
Future<DisplayController> loadTestDisplayController({
  Map<String, Object> initialValues = const {},
}) async {
  SharedPreferences.setMockInitialValues(initialValues);

  final controller = await TestWidgetsFlutterBinding.instance
      .runAsync<DisplayController>(DisplayController.load);
  if (controller == null) {
    throw StateError('DisplayController.load() failed in test bootstrap.');
  }
  return controller;
}

/// Wraps [child] in a [DisplayScope] backed by a freshly loaded
/// [DisplayController], mirroring how `main.dart`/`main_prod.dart` bootstrap
/// the app. Keeping the real-async boundary here means existing widget tests
/// get deterministic bootstrap behavior without file-by-file timeout fixes.
Future<Widget> wrapWithDisplayScope(Widget child) async {
  final controller = await loadTestDisplayController();
  return DisplayScope(controller: controller, child: child);
}
