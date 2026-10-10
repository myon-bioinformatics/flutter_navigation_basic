import 'package:flutter/material.dart';

class Pattern103View extends StatelessWidget {
  const Pattern103View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 103: DataNormalize')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Text('データ正規化 (文字列トリム、大文字小文字統一等)。'),
    ),
  );
}
