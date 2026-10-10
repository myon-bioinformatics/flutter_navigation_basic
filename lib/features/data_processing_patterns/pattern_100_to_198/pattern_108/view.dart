import 'package:flutter/material.dart';

class Pattern108View extends StatelessWidget {
  const Pattern108View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 108: TimeZone')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Text('タイムゾーン変換処理。'),
    ),
  );
}
