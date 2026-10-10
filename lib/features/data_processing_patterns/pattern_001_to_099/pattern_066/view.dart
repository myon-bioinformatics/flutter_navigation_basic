import 'package:flutter/material.dart';

class Pattern066View extends StatelessWidget {
  const Pattern066View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 066: WriteThrough')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Text('Write-Through キャッシュ戦略。'),
    ),
  );
}
