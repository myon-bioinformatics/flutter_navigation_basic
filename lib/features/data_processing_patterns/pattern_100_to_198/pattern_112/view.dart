import 'package:flutter/material.dart';

class Pattern112View extends StatelessWidget {
  const Pattern112View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 112: DataClean')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Text('欠損値・外れ値のクリーニング処理。'),
    ),
  );
}
