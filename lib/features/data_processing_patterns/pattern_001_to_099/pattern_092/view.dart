import 'package:flutter/material.dart';

class Pattern092View extends StatelessWidget {
  const Pattern092View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 092: EmailValidation')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Text('メールアドレスバリデーション。'),
    ),
  );
}
