import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/data_processing/native_notifier_example.dart';

class Pattern159View extends StatelessWidget {
  const Pattern159View({super.key});
  @override Widget build(BuildContext context) => const NativeNotifierExample(
    title: 'Pattern 159: ValueNotifier',
    description: 'ValueNotifier の基本実装。',
    useChangeNotifier: false,
  );
}
