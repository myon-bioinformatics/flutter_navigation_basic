import 'package:flutter/material.dart';

class Pattern080View extends StatelessWidget {
  const Pattern080View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 080: ObjectPool')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Text('オブジェクトプール実装。'),
    ),
  );
}
