import 'package:flutter/material.dart';

class Pattern150View extends StatelessWidget {
  const Pattern150View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 150: AsyncGenerator')),
    body: const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('非同期ジェネレーター関数の実装。'),
          SizedBox(height: 12),
          Text('JS参照CLIに処理あり。Flutterでの直接実行は未接続。'),
        ],
      ),
    ),
  );
}
