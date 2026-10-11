import 'package:flutter/material.dart';

class Pattern087View extends StatelessWidget {
  const Pattern087View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 087: Denormalize')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Text('パフォーマンス向けデータ非正規化。'),
    ),
  );
}
