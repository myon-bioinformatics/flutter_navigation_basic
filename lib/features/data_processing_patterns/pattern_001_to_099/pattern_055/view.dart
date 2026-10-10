import 'package:flutter/material.dart';

class Pattern055View extends StatelessWidget {
  const Pattern055View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 055: TimelineView')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Text('タイムライン形式リスト。'),
    ),
  );
}
