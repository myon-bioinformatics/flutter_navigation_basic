import 'package:flutter/material.dart';

class Pattern060View extends StatelessWidget {
  const Pattern060View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 060: HeatmapData')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Text('ヒートマップ向けデータ集計。'),
    ),
  );
}
