// Pattern 172: ReorderList
// Native Flutter gesture UI; shared implementation owns widget state.
import 'package:flutter/material.dart';
import '../../../../core/data_processing/interactive_pattern_example.dart';

class Pattern172View extends StatelessWidget {
  const Pattern172View({super.key});

  @override
  Widget build(BuildContext context) =>
      const InteractivePatternExample(patternId: 172);
}
