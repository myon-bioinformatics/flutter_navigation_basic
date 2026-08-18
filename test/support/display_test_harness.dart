import 'package:flutter/material.dart';
import 'package:flutter_application_1/shared/display/display_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Loads a [DisplayController] deterministically for tests by seeding an
/// in-memory `SharedPreferences` mock first. `DisplayController.load()` goes
/// through `SharedPreferences.getInstance()`, which talks to a real platform
/// channel with no handler registered in a plain widget test; without
/// `setMockInitialValues` that call never settles instead of failing fast,
/// hanging `pumpAndSettle()`/`await` for the whole test file.
Future<DisplayController> loadTestDisplayController({
  Map<String, Object> initialValues = const {},
}) async {
  SharedPreferences.setMockInitialValues(initialValues);
  return DisplayController.load();
}

/// Wraps [child] in a [DisplayScope] backed by a freshly loaded
/// [DisplayController], mirroring how `main.dart`/`main_prod.dart` bootstrap
/// the app. Widget tests that pump a screen reading `DisplayScope.of(context)`
/// must await this before `pumpWidget`, otherwise `DisplayScope.of` throws.
Future<Widget> wrapWithDisplayScope(Widget child) async {
  final controller = await loadTestDisplayController();
  return DisplayScope(controller: controller, child: child);
}
