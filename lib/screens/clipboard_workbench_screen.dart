import 'package:flutter/material.dart';

import '../shared/display/display_scope.dart';
import '../shared/widgets/clipboard_prompt_workbench.dart';

class ClipboardWorkbenchScreen extends StatelessWidget {
  const ClipboardWorkbenchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(display.text('home.workbench')),
        actions: const [DisplayLocalePicker(compact: true)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 72),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: const ClipboardPromptWorkbench(),
          ),
        ),
      ),
    );
  }
}
