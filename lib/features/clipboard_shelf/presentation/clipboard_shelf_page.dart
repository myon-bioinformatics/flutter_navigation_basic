import 'package:flutter/material.dart';

import '../../../shared/widgets/clipboard_shelf.dart';

class ClipboardShelfPage extends StatelessWidget {
  const ClipboardShelfPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clipboard Shelf')),
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
