// Pattern 030: DistinctFilter — generated example, not runtime processing.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/data_processing/processed_list_example.dart';

import 'service.dart';

class Pattern030View extends StatelessWidget {
  const Pattern030View({super.key, this.bundle});

  final AssetBundle? bundle;

  @override
  Widget build(BuildContext context) => ProcessedListExample(
        title: 'Pattern 030: DistinctFilter',
        asset: Pattern030Service(bundle: bundle),
      );
}
