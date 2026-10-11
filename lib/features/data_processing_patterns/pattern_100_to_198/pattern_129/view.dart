import 'package:flutter/material.dart';

class Pattern129View extends StatelessWidget {
  const Pattern129View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 129: BroadcastStream')),
    body: const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ブロードキャスト Stream の実装。'),
          SizedBox(height: 12),
          Text('JS Stream参照実装あり。Flutterでの直接実行は未接続。'),
        ],
      ),
    ),
  );
}
