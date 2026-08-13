import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/hub_screen.dart';
import '../screens/counter_playground_screen.dart';
import '../screens/irony_generator_screen.dart';
import '../screens/composition_generator_screen.dart';
import '../screens/generic_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String hub = '/hub';

  // Keep the canonical numeric paths so the 198-screen catalogue remains stable,
  // while exposing semantic route names in source code.
  static const String counterPlayground = '/screen2';
  static const String ironyGenerator = '/screen3';
  static const String compositionGenerator = '/screen4';

  static String screenRoute(int id) => '/screen$id';

  static final Map<String, WidgetBuilder> routes = _buildRoutes();

  static Map<String, WidgetBuilder> _buildRoutes() {
    final map = <String, WidgetBuilder>{};

    // Register generic screens for all 198 catalogue entries.
    for (var i = 1; i <= 198; i++) {
      map['/screen$i'] = (_) => GenericScreen(screenId: i);
    }

    // Preserve the original handcrafted examples at their canonical numeric URLs.
    map[home] = (_) => const HomeScreen();
    map[hub] = (_) => const HubScreen();
    map[counterPlayground] = (_) => const CounterPlaygroundScreen();
    map[ironyGenerator] = (_) => const IronyGeneratorScreen();
    map[compositionGenerator] = (_) => const CompositionGeneratorScreen();

    return map;
  }
}
