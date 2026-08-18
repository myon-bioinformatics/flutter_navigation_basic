import 'package:flutter/material.dart';
import 'package:flutter_application_1/shared/display/display_scope.dart';

/// Wraps [child] in a [DisplayScope] backed by a freshly loaded
/// [DisplayController], mirroring how `main.dart`/`main_prod.dart` bootstrap
/// the app. Widget tests that pump a screen reading `DisplayScope.of(context)`
/// must await this before `pumpWidget`, otherwise `DisplayScope.of` throws.
Future<Widget> wrapWithDisplayScope(Widget child) async {
  final controller = await DisplayController.load();
  return DisplayScope(controller: controller, child: child);
}
