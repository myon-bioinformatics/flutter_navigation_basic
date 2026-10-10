import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/data_processing/native_notifier_example.dart';

class Pattern158View extends StatelessWidget {
  const Pattern158View({super.key});
  @override Widget build(BuildContext context) => const NativeNotifierExample(
    title: 'Pattern 158: ChangeNotifier',
    description: 'ChangeNotifier による状態通知実装。',
    useChangeNotifier: true,
  );
}
