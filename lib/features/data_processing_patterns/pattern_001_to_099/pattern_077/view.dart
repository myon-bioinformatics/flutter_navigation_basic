import 'package:flutter/material.dart';

class Pattern077View extends StatelessWidget {
  const Pattern077View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 077: ApiCache')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Text('API レスポンスキャッシュ。'),
    ),
  );
}
