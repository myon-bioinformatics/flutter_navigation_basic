import 'package:flutter/material.dart';

class Pattern094View extends StatelessWidget {
  const Pattern094View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 094: PhoneValidation')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Text('電話番号バリデーション。'),
    ),
  );
}
