import 'package:flutter/material.dart';

class Pattern101View extends StatelessWidget {
  const Pattern101View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 101: CrossField')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Text('クロスフィールドバリデーション。'),
    ),
  );
}
