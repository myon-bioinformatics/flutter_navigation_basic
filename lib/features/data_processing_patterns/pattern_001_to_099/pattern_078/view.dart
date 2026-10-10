import 'package:flutter/material.dart';

class Pattern078View extends StatelessWidget {
  const Pattern078View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 078: ComputeCache')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Text('計算結果キャッシュ (メモ化)。'),
    ),
  );
}
