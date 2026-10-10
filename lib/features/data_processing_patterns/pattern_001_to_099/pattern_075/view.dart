import 'package:flutter/material.dart';

class Pattern075View extends StatelessWidget {
  const Pattern075View({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pattern 075: CacheSerialization')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Text('キャッシュのシリアライズ/デシリアライズ。'),
    ),
  );
}
