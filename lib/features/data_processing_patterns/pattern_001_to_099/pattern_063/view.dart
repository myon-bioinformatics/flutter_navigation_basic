import 'package:flutter/material.dart';

class Pattern063View extends StatelessWidget {
  const Pattern063View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 063: TtlCache')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Text('TTL 付きキャッシュ実装。'),
    ),
  );
}
