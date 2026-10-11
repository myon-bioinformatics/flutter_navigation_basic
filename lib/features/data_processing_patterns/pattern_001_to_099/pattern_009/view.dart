// Pattern 009: SortBasic — generated example, not runtime sorting.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/data_processing/processed_list_example.dart';

import 'service.dart';

class Pattern009View extends StatelessWidget {
  const Pattern009View({super.key, this.bundle});

  final AssetBundle? bundle;

  @override
  Widget build(BuildContext context) => ProcessedListExample(
        title: 'Pattern 009: SortBasic',
        asset: Pattern009Service(bundle: bundle),
      );
}
