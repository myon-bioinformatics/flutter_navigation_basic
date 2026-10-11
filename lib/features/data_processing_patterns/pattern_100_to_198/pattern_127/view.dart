import 'package:flutter/material.dart';

class Pattern127View extends StatelessWidget {
  const Pattern127View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 127: StreamBasic')),
    body: const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('基本的な Stream の生成と購読。'),
          SizedBox(height: 12),
          Text('JS Stream参照実装あり。Flutterでの直接実行は未接続。'),
        ],
      ),
    ),
  );
}
