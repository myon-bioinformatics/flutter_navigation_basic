// Pattern 183: MultiSelect
// Native Flutter gesture UI; shared implementation owns widget state.
import 'package:flutter/material.dart';
import '../../../../core/data_processing/interactive_pattern_example.dart';

class Pattern183View extends StatelessWidget {
  const Pattern183View({super.key});

  @override
  Widget build(BuildContext context) =>
      const InteractivePatternExample(patternId: 183);
}
