import 'package:flutter/material.dart';

class Pattern058View extends StatelessWidget {
  const Pattern058View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 058: KanbanBoard')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Text('カンバン形式のカード管理 UI。'),
    ),
  );
}
