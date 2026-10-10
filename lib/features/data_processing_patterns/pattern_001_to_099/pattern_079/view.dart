import 'package:flutter/material.dart';

class Pattern079View extends StatelessWidget {
  const Pattern079View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 079: LazyInit')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Text('遅延初期化パターン。'),
    ),
  );
}
