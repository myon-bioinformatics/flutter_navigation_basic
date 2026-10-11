import 'package:flutter/material.dart';

class Pattern100View extends StatelessWidget {
  const Pattern100View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 100: AsyncValidation')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Text('非同期バリデーション (サーバー確認)。'),
    ),
  );
}
