import 'package:flutter/material.dart';

import '../../../shared/widgets/clipboard_prompt_workbench.dart';

class ClipboardWorkbenchPage extends StatelessWidget {
  const ClipboardWorkbenchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clipboard Workbench 📋')),
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
