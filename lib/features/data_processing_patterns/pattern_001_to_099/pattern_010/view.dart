// Pattern 010: SortMultiKey — generated example, not runtime sorting.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/data_processing/processed_list_example.dart';

import 'service.dart';

class Pattern010View extends StatelessWidget {
  const Pattern010View({super.key, this.bundle});

  final AssetBundle? bundle;

  @override
  Widget build(BuildContext context) => ProcessedListExample(
        title: 'Pattern 010: SortMultiKey',
        asset: Pattern010Service(bundle: bundle),
      );
}
