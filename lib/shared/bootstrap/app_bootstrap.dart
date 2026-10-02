import 'package:flutter/material.dart';

import '../display/display_scope.dart';

/// Shared startup policy for every entrypoint (`main.dart`, `main_prod.dart`).
///
/// Entrypoint-specific initialization runs in [prepare] before display
/// loading. A catalog (or [prepare]) failure shows [StartupErrorApp] instead
/// of a hang or an unhandled pre-`runApp` exception; a preferences failure is
/// absorbed inside [DisplayController.load].
Future<void> bootstrapApp({
  required Widget app,
  Future<void> Function()? prepare,
  Future<DisplayController> Function() loadDisplay = DisplayController.load,
}) async {
  final DisplayController display;
  try {
    await prepare?.call();
    display = await loadDisplay();
  } catch (error, stack) {
    FlutterError.reportError(FlutterErrorDetails(
      exception: error,
      stack: stack,
      library: 'app bootstrap',
    ));
    runApp(StartupErrorApp(error: error));
    return;
  }
  runApp(DisplayScope(controller: display, child: app));
}

/// Static, catalog-independent error screen (no [DisplayScope] available).
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Semantics(
              identifier: 'startup-error',
              child: Text(
                'Startup failed: the app could not load its display text.\n$error',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
