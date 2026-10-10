import 'package:flutter/material.dart';

class Pattern056View extends StatelessWidget {
  const Pattern056View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 056: MasonryGrid')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Text('Masonry グリッドレイアウト (擬似実装)。'),
    ),
  );
}
