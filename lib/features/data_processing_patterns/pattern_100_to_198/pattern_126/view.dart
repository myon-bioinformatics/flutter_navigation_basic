import 'package:flutter/material.dart';

/// JS Promise catalogue analogue: no Node runtime is bundled with Flutter.
class Pattern126View extends StatelessWidget {
  const Pattern126View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 126: FutureTimeout')),
    body: const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Future.timeout によるタイムアウト制御。'),
          SizedBox(height: 12),
          Text('JS Promise参照実装あり。Flutterでの直接実行は未接続。'),
        ],
      ),
    ),
  );
}
