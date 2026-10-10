import 'package:flutter/material.dart';

class Pattern084View extends StatelessWidget {
  const Pattern084View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 084: StreamBuffer')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Text('ストリームバッファリング実装。'),
    ),
  );
}
