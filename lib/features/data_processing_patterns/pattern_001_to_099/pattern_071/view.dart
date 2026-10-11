import 'package:flutter/material.dart';

class Pattern071View extends StatelessWidget {
  const Pattern071View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 071: CacheKey')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Text('効果的なキャッシュキー生成戦略。'),
    ),
  );
}
