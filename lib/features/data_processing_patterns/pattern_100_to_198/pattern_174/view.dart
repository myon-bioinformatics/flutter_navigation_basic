// Pattern 174: InsertItem
// Native Flutter gesture UI; shared implementation owns widget state.
import 'package:flutter/material.dart';
import '../../../../core/data_processing/interactive_pattern_example.dart';

class Pattern174View extends StatelessWidget {
  const Pattern174View({super.key});

  @override
  Widget build(BuildContext context) =>
      const InteractivePatternExample(patternId: 174);
}
