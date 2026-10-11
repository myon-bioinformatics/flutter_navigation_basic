// Pattern 018: GeoFilter
// Processing is implemented and tested in Python; Flutter CLI bridge is pending.
import 'package:flutter/material.dart';

class Pattern018View extends StatelessWidget {
  const Pattern018View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 018: GeoFilter')),
    body: const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('距離による絞り込みの独立処理はPython CLIで実装済みです。'),
          SizedBox(height: 12),
          Text('Flutter画面からの実行は未接続です。'),
        ],
      ),
    ),
  );
}
