import 'package:flutter/material.dart';

class Pattern059View extends StatelessWidget {
  const Pattern059View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 059: ChartData')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Text('グラフ表示向けデータ準備。'),
    ),
  );
}
