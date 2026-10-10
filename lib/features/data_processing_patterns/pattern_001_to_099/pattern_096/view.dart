import 'package:flutter/material.dart';

class Pattern096View extends StatelessWidget {
  const Pattern096View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 096: DateValidation')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Text('日付形式バリデーション。'),
    ),
  );
}
