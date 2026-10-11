import 'package:flutter/material.dart';

class Pattern067View extends StatelessWidget {
  const Pattern067View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 067: WriteBack')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Text('Write-Back キャッシュ戦略。'),
    ),
  );
}
