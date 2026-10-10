import 'package:flutter/material.dart';

class Pattern098View extends StatelessWidget {
  const Pattern098View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 098: RegexValidation')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Text('正規表現バリデーション実装。'),
    ),
  );
}
