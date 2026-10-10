// Pattern 171: SortableList
// Native Flutter gesture UI; shared implementation owns widget state.
import 'package:flutter/material.dart';
import '../../../../core/data_processing/interactive_pattern_example.dart';

class Pattern171View extends StatelessWidget {
  const Pattern171View({super.key});

  @override
  Widget build(BuildContext context) =>
      const InteractivePatternExample(patternId: 171);
}
