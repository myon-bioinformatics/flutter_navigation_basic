import 'package:flutter/material.dart';

import '../shared/widgets/clipboard_shelf.dart';

class ClipboardShelfScreen extends StatelessWidget {
  const ClipboardShelfScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clipboard Shelf')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 72),
        child: const Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 1100),
            child: ClipboardShelf(),
          ),
        ),
      ),
    );
  }
}
