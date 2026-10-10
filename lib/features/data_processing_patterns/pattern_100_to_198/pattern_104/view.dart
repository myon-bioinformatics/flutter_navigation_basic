import 'package:flutter/material.dart';

class Pattern104View extends StatelessWidget {
  const Pattern104View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 104: TypeCoercion')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Text('型強制変換処理の安全な実装。'),
    ),
  );
}
