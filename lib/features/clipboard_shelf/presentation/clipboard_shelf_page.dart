import 'package:flutter/material.dart';

import '../../../core/navigation/route_names.dart';
import '../../../shared/display/display_scope.dart';
import '../../../shared/widgets/clipboard_shelf.dart';
import '../../../shared/widgets/tool_door_selector.dart';

class ClipboardShelfPage extends StatelessWidget {
  const ClipboardShelfPage({super.key});

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(display.text('clipboardShelf.appBarTitle'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 72),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipboardShelf(),
                SizedBox(height: 24),
                ToolDoorSelector(currentRouteName: RouteNames.clipboardShelf),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
