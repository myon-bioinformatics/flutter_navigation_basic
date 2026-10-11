import 'package:flutter/material.dart';

/// Catalogue identity and display only; producer runs in the Python CLI.
class Pattern115View extends StatelessWidget {
  const Pattern115View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 115: Constraint')),
    body: const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('制約定義によるデータ整合性チェック。'),
          SizedBox(height: 12),
          Text('Python CLIに処理を移管済み。Flutter側での実行は未接続。'),
        ],
      ),
    ),
  );
}
