import 'package:flutter/material.dart';

class Pattern105View extends StatelessWidget {
  const Pattern105View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 105: DateConvert')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Text('日付フォーマット変換処理。'),
    ),
  );
}
