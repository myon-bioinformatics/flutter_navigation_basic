import 'package:flutter/material.dart';

class Pattern111View extends StatelessWidget {
  const Pattern111View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 111: DataEnrich')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Text('外部データによるデータ補完。'),
    ),
  );
}
