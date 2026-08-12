import 'package:flutter/material.dart';
import 'config/app_config.dart';
import 'config/routes.dart';

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
    );
  }
}
