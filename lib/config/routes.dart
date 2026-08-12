import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/hub_screen.dart';
import '../screens/screen2.dart';
import '../screens/screen3.dart';
import '../screens/screen4.dart';
import '../screens/generic_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String hub = '/hub';
  static const String screen2 = '/screen2';
  static const String screen3 = '/screen3';
  static const String screen4 = '/screen4';

  static String screenRoute(int id) => '/screen$id';

  static final Map<String, WidgetBuilder> routes = _buildRoutes();

  static Map<String, WidgetBuilder> _buildRoutes() {
    final map = <String, WidgetBuilder>{};

    // Register generic screens for all 198 screens (hub-navigable)
    for (var i = 1; i <= 198; i++) {
      map['/screen$i'] = (_) => GenericScreen(screenId: i);
    }

    // Keep original special screens accessible at their canonical routes
    // (these override the generic entries for screen2/3/4)
    map[home] = (_) => const HomeScreen();
    map[hub] = (_) => const HubScreen();
    map[screen2] = (_) => const Screen2();
    map[screen3] = (_) => const Screen3();
    map[screen4] = (_) => const Screen4();

    return map;
  }
}
