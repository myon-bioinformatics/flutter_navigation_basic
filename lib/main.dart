import 'package:flutter/material.dart';
import 'config/app_config.dart';
import 'config/routes.dart';
import 'shared/diagnostics/route_diagnostics_observer.dart';
import 'shared/diagnostics/weight_badge_overlay.dart';
import 'shared/display/display_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final display = await DisplayController.load();
  runApp(DisplayScope(controller: display, child: const App()));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
    return ListenableBuilder(
      listenable: display,
      builder: (context, _) {
        return MaterialApp(
          title: AppConfig.appName,
          theme: AppConfig.theme,
          // External BCP 47 boundary: catalog stores ISO 639-3 (`ind`), Flutter
          // Locale / HTML lang need short tags (`id`).
          locale: display.flutterLocale,
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.home,
          navigatorObservers: [RouteDiagnosticsObserver.instance],
          builder: (context, child) => Column(
            children: [
              Expanded(child: child ?? const SizedBox.shrink()),
              const WeightDiagnosticsStrip(),
            ],
          ),
        );
      },
    );
  }
}
