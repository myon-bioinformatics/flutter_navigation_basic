import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/config/app_config.dart';
import 'core/navigation/app_navigation.dart';
import 'core/navigation/route_names.dart';
import 'core/services/storage_service.dart';
import 'core/logging/logger_service.dart';
import 'shared/themes/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.initialize(env: AppEnvironment.production);
  await StorageService.initialize();
  LoggerService.info('App started in production mode');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConfig.appName,
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      initialRoute: RouteNames.home,
      getPages: appRoutes,
    );
  }
}
