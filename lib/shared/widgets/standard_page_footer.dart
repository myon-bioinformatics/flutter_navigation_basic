import 'package:flutter/material.dart';
import 'tool_door_selector.dart';

/// Shared bottom-of-page navigation for catalogue pages.
/// Keep the selector's route semantics and tool list in one implementation.
class StandardPageFooter extends StatelessWidget {
  const StandardPageFooter({super.key, required this.currentRouteName});
  final String currentRouteName;

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: ToolDoorSelector(currentRouteName: currentRouteName),
        ),
      );
}
