import 'package:flutter/material.dart';

class Pattern102View extends StatelessWidget {
  const Pattern102View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 102: SanitizeInput')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Text('XSS/SQLインジェクション防止の入力サニタイズ。'),
    ),
  );
}
