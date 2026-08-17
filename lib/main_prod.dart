import 'package:flutter/material.dart';
import 'core/config/app_config.dart';
import 'core/navigation/app_navigation.dart';
import 'core/navigation/route_names.dart';
import 'core/services/storage_service.dart';
import 'core/logging/logger_service.dart';
import 'shared/diagnostics/route_diagnostics_observer.dart';
import 'shared/diagnostics/weight_badge_overlay.dart';
import 'shared/display/display_scope.dart';
import 'shared/themes/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.initialize(env: AppEnvironment.production);
  await StorageService.initialize();
  final display = await DisplayController.load();
  LoggerService.info('App started in production mode');
  runApp(DisplayScope(controller: display, child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AppNavigation.navigatorKey,
      title: AppConfig.appName,
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      initialRoute: RouteNames.home,
      routes: AppNavigation.routes,
      navigatorObservers: [RouteDiagnosticsObserver.instance],
      builder: (context, child) => WeightBadgeOverlay(
        preferFeatureWeights: true,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
