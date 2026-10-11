import 'package:flutter/material.dart';

class Pattern090View extends StatelessWidget {
  const Pattern090View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 090: ReadThrough')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Text('Read-Through キャッシュ実装。'),
    ),
  );
}
