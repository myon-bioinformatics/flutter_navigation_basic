import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/hub_screen.dart';
import '../screens/counter_playground_screen.dart';
import '../screens/irony_generator_screen.dart';
import '../screens/composition_generator_screen.dart';
import '../screens/clipboard_shelf_screen.dart';
import '../screens/clipboard_workbench_screen.dart';
import '../screens/mock_api_screen.dart';
import '../screens/mcp_integration_screen.dart';
import '../screens/generic_screen.dart';
import '../screens/ui_showcase_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String hub = '/hub';

  static const String clipboardShelf = '/core/clipboard-shelf';
  static const String counterPlayground = '/examples/counter-playground';
  static const String ironyGenerator = '/examples/irony-generator';
  static const String compositionGenerator = '/examples/composition-generator';
  static const String clipboardWorkbench = '/examples/clipboard-workbench';
  static const String uiShowcase = '/examples/ui-showcase';

  static const String externalApi = '/examples/external-integration/api';
  static const String externalMcp = '/examples/external-integration/mcp';

  // Compatibility route retained for existing links/bookmarks.
  static const String mockApi = '/examples/mock-api';

  static String screenRoute(int id) => '/screen$id';

  static final Map<String, WidgetBuilder> routes = _buildRoutes();

  static Map<String, WidgetBuilder> _buildRoutes() {
    final map = <String, WidgetBuilder>{};

    for (var i = 1; i <= 198; i++) {
      map[screenRoute(i)] = (_) => GenericScreen(screenId: i);
    }

    map[home] = (_) => const HomeScreen();
    map[hub] = (_) => const HubScreen();
    map[clipboardShelf] = (_) => const ClipboardShelfScreen();
    map[counterPlayground] = (_) => const CounterPlaygroundScreen();
    map[ironyGenerator] = (_) => const IronyGeneratorScreen();
    map[compositionGenerator] = (_) => const CompositionGeneratorScreen();
    map[clipboardWorkbench] = (_) => const ClipboardWorkbenchScreen();
    map[uiShowcase] = (_) => const UiShowcaseScreen();
    map[externalApi] = (_) => const ApiIntegrationScreen();
    map[externalMcp] = (_) => const McpIntegrationScreen();
    map[mockApi] = (_) => const ApiIntegrationScreen();

    return map;
  }
}
