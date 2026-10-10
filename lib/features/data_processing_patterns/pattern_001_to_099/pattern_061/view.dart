import 'package:flutter/material.dart';

class Pattern061View extends StatelessWidget {
  const Pattern061View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 061: MemoryCacheBasic')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Text('基本的なメモリキャッシュ実装。'),
    ),
  );
}
