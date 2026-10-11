import 'package:flutter/material.dart';

class Pattern076View extends StatelessWidget {
  const Pattern076View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 076: ImageCache')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Text('画像専用キャッシュ管理。'),
    ),
  );
}
