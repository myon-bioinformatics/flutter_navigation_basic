import 'package:flutter/material.dart';

import '../features/clipboard_shelf/presentation/clipboard_shelf_page.dart';

/// Thin public wrapper; implementation lives in features/.
class ClipboardShelfScreen extends StatelessWidget {
  const ClipboardShelfScreen({super.key});

  @override
  Widget build(BuildContext context) => const ClipboardShelfPage();
}
