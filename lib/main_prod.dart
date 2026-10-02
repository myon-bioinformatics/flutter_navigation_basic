import 'package:flutter/material.dart';

import 'core/config/app_config.dart';
import 'core/logging/logger_service.dart';
import 'core/navigation/app_navigation.dart';
import 'core/navigation/route_names.dart';
import 'core/services/storage_service.dart';
import 'features/now_timeline/presentation/time_rules_bootstrap.dart';
import 'shared/diagnostics/route_diagnostics_observer.dart';
import 'shared/diagnostics/weight_badge_overlay.dart';
import 'shared/bootstrap/app_bootstrap.dart';
import 'shared/display/display_scope.dart';
import 'shared/themes/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Native/iOS + production-entrypoint build lane. Production-only
  // initialization stays explicit here; display policy is shared.
  await bootstrapApp(
    prepare: () async {
      await loadTimeRules();
      await AppConfig.initialize(env: AppEnvironment.production);
      await StorageService.initialize();
    },
    app: const MyApp(),
  );
  LoggerService.info('App started in production mode');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
    return ListenableBuilder(
      listenable: display,
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: AppNavigation.navigatorKey,
          title: AppConfig.appName,
          theme: AppTheme.light,
          locale: display.flutterLocale,
          debugShowCheckedModeBanner: false,
          initialRoute: RouteNames.home,
          routes: AppNavigation.routes,
          navigatorObservers: [RouteDiagnosticsObserver.instance],
          builder: (context, child) => WeightBadgeOverlay(
            preferFeatureWeights: true,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
