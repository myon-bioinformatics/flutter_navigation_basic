import 'package:flutter/material.dart';

class Pattern070View extends StatelessWidget {
  const Pattern070View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 070: CacheWarmup')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Text('起動時キャッシュウォームアップ。'),
    ),
  );
}
