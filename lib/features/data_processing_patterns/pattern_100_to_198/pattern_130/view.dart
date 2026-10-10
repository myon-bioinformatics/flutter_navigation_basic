import 'package:flutter/material.dart';

class Pattern130View extends StatelessWidget {
  const Pattern130View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 130: StreamTransform')),
    body: const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Stream の map/where/expand 変換。'),
          SizedBox(height: 12),
          Text('JS Stream参照実装あり。Flutterでの直接実行は未接続。'),
        ],
      ),
    ),
  );
}
