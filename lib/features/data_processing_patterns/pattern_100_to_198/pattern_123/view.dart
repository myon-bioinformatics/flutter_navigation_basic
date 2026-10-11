import 'package:flutter/material.dart';

/// JS Promise catalogue analogue: no Node runtime is bundled with Flutter.
class Pattern123View extends StatelessWidget {
  const Pattern123View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 123: FutureError')),
    body: const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Future エラーハンドリング実装。'),
          SizedBox(height: 12),
          Text('JS Promise参照実装あり。Flutterでの直接実行は未接続。'),
        ],
      ),
    ),
  );
}
