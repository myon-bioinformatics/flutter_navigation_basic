import 'package:flutter/material.dart';

/// JS Promise catalogue analogue: no Node runtime is bundled with Flutter.
class Pattern124View extends StatelessWidget {
  const Pattern124View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 124: FutureWait')),
    body: const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Future.wait による並列実行。'),
          SizedBox(height: 12),
          Text('JS Promise参照実装あり。Flutterでの直接実行は未接続。'),
        ],
      ),
    ),
  );
}
