// Pattern 005: SearchBasic — generated example, not runtime text processing.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/data_processing/processed_list_example.dart';

import 'service.dart';

class Pattern005View extends StatelessWidget {
  const Pattern005View({super.key, this.bundle});

  final AssetBundle? bundle;

  @override
  Widget build(BuildContext context) => ProcessedListExample(
        title: 'Pattern 005: SearchBasic',
        asset: Pattern005Service(bundle: bundle),
      );
}
