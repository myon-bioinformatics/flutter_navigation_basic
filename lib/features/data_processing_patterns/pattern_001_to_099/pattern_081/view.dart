import 'package:flutter/material.dart';

class Pattern081View extends StatelessWidget {
  const Pattern081View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 081: MemoryLimit')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Text('メモリ上限監視と解放。'),
    ),
  );
}
