// Pattern 001: FilterBasic — Python-generated example, not a runtime filter.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controller.dart';

class Pattern001View extends GetView<Pattern001Controller> {
  const Pattern001View({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pattern 001: FilterBasic')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pythonで生成したフィルター結果を読み込む例。',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Obx(() => Text('状態: ${controller.status.value}')),
            Obx(() => controller.hasError.value
                ? Text(controller.errorMessage.value)
                : const SizedBox.shrink()),
            const SizedBox(height: 16),
            Obx(() => ElevatedButton(
                  onPressed: controller.isLoading.value ? null : controller.execute,
                  child: const Text('実行'),
                )),
          ],
        ),
      ),
    );
  }
}
