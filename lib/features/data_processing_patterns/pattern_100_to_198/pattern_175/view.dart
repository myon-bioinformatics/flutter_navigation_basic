// Pattern 175: RemoveItem
// Native Flutter gesture UI; shared implementation owns widget state.
import 'package:flutter/material.dart';
import '../../../../core/data_processing/interactive_pattern_example.dart';

class Pattern175View extends StatelessWidget {
  const Pattern175View({super.key});

  @override
  Widget build(BuildContext context) =>
      const InteractivePatternExample(patternId: 175);
}
