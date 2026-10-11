// Pattern 013: SortReverse — generated example, not runtime sorting.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/data_processing/processed_list_example.dart';

import 'service.dart';

class Pattern013View extends StatelessWidget {
  const Pattern013View({super.key, this.bundle});

  final AssetBundle? bundle;

  @override
  Widget build(BuildContext context) => ProcessedListExample(
        title: 'Pattern 013: SortReverse',
        asset: Pattern013Service(bundle: bundle),
      );
}
