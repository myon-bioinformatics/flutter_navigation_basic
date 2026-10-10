import 'package:flutter/material.dart';

class Pattern091View extends StatelessWidget {
  const Pattern091View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 091: ValidationBasic')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Text('基本的な入力バリデーション実装。'),
    ),
  );
}
