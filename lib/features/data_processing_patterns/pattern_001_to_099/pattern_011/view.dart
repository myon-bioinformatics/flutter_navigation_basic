// Pattern 011: SortStable
// The real sorting contract is implemented by the standalone Python producer.
import 'package:flutter/material.dart';

class Pattern011View extends StatelessWidget {
  const Pattern011View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 011: SortStable')),
    body: const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('安定ソートはPython CLIで実装済みです。'),
          SizedBox(height: 12),
          Text('Flutter画面からの実行は未接続です。'),
        ],
      ),
    ),
  );
}
