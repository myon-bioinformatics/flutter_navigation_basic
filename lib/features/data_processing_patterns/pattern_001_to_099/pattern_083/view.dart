import 'package:flutter/material.dart';

class Pattern083View extends StatelessWidget {
  const Pattern083View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 083: Dispose')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Text('適切なリソース解放パターン。'),
    ),
  );
}
