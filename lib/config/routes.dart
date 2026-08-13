import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/hub_screen.dart';
import '../screens/counter_playground_screen.dart';
import '../screens/irony_generator_screen.dart';
import '../screens/composition_generator_screen.dart';
import '../screens/mock_api_screen.dart';
import '../screens/mcp_integration_screen.dart';
import '../screens/generic_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String hub = '/hub';

  static const String counterPlayground = '/examples/counter-playground';
  static const String ironyGenerator = '/examples/irony-generator';
  static const String compositionGenerator = '/examples/composition-generator';

  static const String externalApi = '/examples/external-integration/api';
  static const String externalMcp = '/examples/external-integration/mcp';

  // Compatibility route retained for existing links/bookmarks.
  static const String mockApi = '/examples/mock-api';

  static String screenRoute(int id) => '/screen$id';

  static final Map<String, WidgetBuilder> routes = _buildRoutes();

  static Map<String, WidgetBuilder> _buildRoutes() {
    final map = <String, WidgetBuilder>{};

    // Keep all 198 catalogue routes available as template-driven screens.
    for (var i = 1; i <= 198; i++) {
      map[screenRoute(i)] = (_) => GenericScreen(screenId: i);
    }

    // Handcrafted examples use semantic URLs and no longer replace catalogue IDs.
    map[home] = (_) => const HomeScreen();
    map[hub] = (_) => const HubScreen();
    map[counterPlayground] = (_) => const CounterPlaygroundScreen();
    map[ironyGenerator] = (_) => const IronyGeneratorScreen();
    map[compositionGenerator] = (_) => const CompositionGeneratorScreen();
    map[externalApi] = (_) => const ApiIntegrationScreen();
    map[externalMcp] = (_) => const McpIntegrationScreen();
    map[mockApi] = (_) => const ApiIntegrationScreen();

    return map;
  }
}
