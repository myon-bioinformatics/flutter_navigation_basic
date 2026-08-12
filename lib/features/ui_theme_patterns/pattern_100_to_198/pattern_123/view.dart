// Pattern 123: FlexibleLayout
// Flexible + Expanded によるレイアウト。
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controller.dart';

class Pattern123View extends GetView<Pattern123Controller> {
  const Pattern123View({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pattern 123: FlexibleLayout'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Flexible + Expanded によるレイアウト。',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Obx(() => Text('状態: ${controller.status.value}')),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: controller.execute,
              child: const Text('実行'),
            ),
          ],
        ),
      ),
    );
  }
}
