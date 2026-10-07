// Pattern 024: StopWord — generated example, not runtime text processing.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/data_processing/processed_list_example.dart';

import 'service.dart';

class Pattern024View extends StatelessWidget {
  const Pattern024View({super.key, this.bundle});

  final AssetBundle? bundle;

  @override
  Widget build(BuildContext context) => ProcessedListExample(
        title: 'Pattern 024: StopWord',
        asset: Pattern024Service(bundle: bundle),
      );
}
