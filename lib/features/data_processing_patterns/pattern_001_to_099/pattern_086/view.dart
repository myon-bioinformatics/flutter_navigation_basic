// Pattern 086: Deduplication — generated example, not runtime processing.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/data_processing/processed_list_example.dart';

import 'service.dart';

class Pattern086View extends StatelessWidget {
  const Pattern086View({super.key, this.bundle});

  final AssetBundle? bundle;

  @override
  Widget build(BuildContext context) => ProcessedListExample(
        title: 'Pattern 086: Deduplication',
        asset: Pattern086Service(bundle: bundle),
      );
}
