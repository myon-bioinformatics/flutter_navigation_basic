// Pattern 173: DndGrid
// Native Flutter gesture UI; shared implementation owns widget state.
import 'package:flutter/material.dart';
import '../../../../core/data_processing/interactive_pattern_example.dart';

class Pattern173View extends StatelessWidget {
  const Pattern173View({super.key});

  @override
  Widget build(BuildContext context) =>
      const InteractivePatternExample(patternId: 173);
}
