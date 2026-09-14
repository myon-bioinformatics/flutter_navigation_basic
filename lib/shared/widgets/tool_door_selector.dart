import 'package:flutter/material.dart';

import '../../core/navigation/app_tools.dart';
import '../../core/navigation/route_names.dart';
import '../display/display_scope.dart';

/// Shared Door-to-Door tool selector for Tools screen footers.
///
/// Uses [Navigator.of] with named routes so both default (`main.dart` /
/// [AppRoutes]) and production (`main_prod.dart` / [AppNavigation])
/// entrypoints work without a global navigator key.
class ToolDoorSelector extends StatelessWidget {
  const ToolDoorSelector({
    super.key,
    required this.currentRouteName,
    this.tools,
    this.beforeNavigate,
  });

  /// Route of the screen hosting this selector (skipped on select).
  final String currentRouteName;

  /// Injectable for tests; defaults to [appTools].
  final List<AppTool>? tools;

  /// Optional gate before leaving via the selector (e.g. dirty confirm).
  /// Return `true` to navigate, `false` to stay.
  final Future<bool> Function()? beforeNavigate;

  void _navigateTo(BuildContext context, String routeName) {
    final navigator = Navigator.of(context);
    if (routeName == RouteNames.home) {
      navigator.pushNamedAndRemoveUntil(routeName, (route) => false);
      return;
    }
    navigator.pushNamed(routeName);
  }

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
    final catalog = tools ?? appTools;
    final current = catalog.cast<AppTool?>().firstWhere(
          (t) => t!.routeName == currentRouteName,
          orElse: () => null,
        );

    return Semantics(
      container: true,
      label: display.text('tools.doorToDoor.label'),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                display.text('tools.doorToDoor.label'),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                display.text('tools.doorToDoor.hint'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: current?.routeName,
                decoration: InputDecoration(
                  labelText: display.text('tools.doorToDoor.label'),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  for (final tool in catalog)
                    DropdownMenuItem<String>(
                      value: tool.routeName,
                      enabled: tool.routeName != currentRouteName,
                      child: Text(
                        tool.routeName == currentRouteName
                            ? display.text(
                                'tools.doorToDoor.current',
                                arguments: {
                                  'name': display.text(tool.labelKey),
                                },
                              )
                            : display.text(tool.labelKey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (route) async {
                  if (route == null || route == currentRouteName) return;
                  final match = catalog.where((t) => t.routeName == route);
                  if (match.isEmpty) return;
                  final gate = beforeNavigate;
                  if (gate != null && !await gate()) return;
                  if (!context.mounted) return;
                  _navigateTo(context, match.first.routeName);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
