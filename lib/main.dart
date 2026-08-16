import 'package:flutter/material.dart';
import 'config/app_config.dart';
import 'config/routes.dart';
import 'shared/diagnostics/route_diagnostics_observer.dart';
import 'shared/diagnostics/weight_badge_overlay.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      theme: AppConfig.theme,
      routes: AppRoutes.routes,
      initialRoute: AppRoutes.home,
      navigatorObservers: [RouteDiagnosticsObserver.instance],
      builder: (context, child) => WeightBadgeOverlay(
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
