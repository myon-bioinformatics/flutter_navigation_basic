import 'package:flutter/material.dart';

import '../shared/display/display_scope.dart';
import '../shared/widgets/clipboard_shelf.dart';

class ClipboardShelfScreen extends StatelessWidget {
  const ClipboardShelfScreen({super.key});

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
            child: const ClipboardShelf(),
          ),
        ),
      ),
    );
  }
}
