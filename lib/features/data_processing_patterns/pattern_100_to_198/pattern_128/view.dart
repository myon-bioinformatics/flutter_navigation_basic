import 'package:flutter/material.dart';

class Pattern128View extends StatelessWidget {
  const Pattern128View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 128: StreamController')),
    body: const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('StreamController による手動 Stream 制御。'),
          SizedBox(height: 12),
          Text('JS Stream参照実装あり。Flutterでの直接実行は未接続。'),
        ],
      ),
    ),
  );
}
