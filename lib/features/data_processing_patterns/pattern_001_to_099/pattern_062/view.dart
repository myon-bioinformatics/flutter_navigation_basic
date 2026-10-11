import 'package:flutter/material.dart';

class Pattern062View extends StatelessWidget {
  const Pattern062View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 062: LruCache')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Text('LRU (最近最未使用) キャッシュ実装。'),
    ),
  );
}
