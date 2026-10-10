import 'package:flutter/material.dart';

/// Catalogue identity and display only; producer runs in the Python CLI.
class Pattern120View extends StatelessWidget {
  const Pattern120View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 120: Zip')),
    body: const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('複数リストの Zip 結合処理。'),
          SizedBox(height: 12),
          Text('Python CLIに処理を移管済み。Flutter側での実行は未接続。'),
        ],
      ),
    ),
  );
}
