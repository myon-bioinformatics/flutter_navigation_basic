import 'package:flutter/material.dart';

class Pattern064View extends StatelessWidget {
  const Pattern064View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 064: WeakRefCache')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Text('弱参照を使ったキャッシュ実装 (擬似)。'),
    ),
  );
}
