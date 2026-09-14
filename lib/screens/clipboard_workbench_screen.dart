import 'package:flutter/material.dart';

import '../features/clipboard_workbench/presentation/clipboard_workbench_page.dart';

/// Thin public wrapper; implementation lives in features/.
class ClipboardWorkbenchScreen extends StatelessWidget {
  const ClipboardWorkbenchScreen({super.key});

  @override
  Widget build(BuildContext context) => const ClipboardWorkbenchPage();
}
