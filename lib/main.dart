import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'config/app_config.dart';
import 'config/routes.dart';
import 'features/now_timeline/presentation/time_rules_bootstrap.dart';
import 'shared/diagnostics/route_diagnostics_observer.dart';
import 'shared/diagnostics/weight_badge_overlay.dart';
import 'shared/bootstrap/app_bootstrap.dart';
import 'shared/display/display_scope.dart';

final List<SemanticsHandle> _e2eSemanticsHandles = <SemanticsHandle>[];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (const bool.fromEnvironment('E2E', defaultValue: false)) {
    // Keep the handle for the process lifetime so browser E2E can address the
    // Flutter semantics tree deterministically. Production builds never pass
    // this define and therefore preserve platform-driven semantics behavior.
    _e2eSemanticsHandles.add(SemanticsBinding.instance.ensureSemantics());
  }
  // Pages / browser-E2E entrypoint: no production-only services here.
  await bootstrapApp(prepare: loadTimeRules, app: const App());
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
