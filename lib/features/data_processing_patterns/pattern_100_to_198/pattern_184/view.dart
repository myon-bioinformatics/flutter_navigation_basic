// Pattern 184: DragReorder
// Native Flutter gesture UI; shared implementation owns widget state.
import 'package:flutter/material.dart';
import '../../../../core/data_processing/interactive_pattern_example.dart';

class Pattern184View extends StatelessWidget {
  const Pattern184View({super.key});

  @override
  Widget build(BuildContext context) =>
      const InteractivePatternExample(patternId: 184);
}
