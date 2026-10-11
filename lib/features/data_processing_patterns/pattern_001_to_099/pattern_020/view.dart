// Pattern 020: InvertedIndex — generated example, not runtime text processing.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/data_processing/processed_list_example.dart';

import 'service.dart';

class Pattern020View extends StatelessWidget {
  const Pattern020View({super.key, this.bundle});

  final AssetBundle? bundle;

  @override
  Widget build(BuildContext context) => ProcessedListExample(
        title: 'Pattern 020: InvertedIndex',
        asset: Pattern020Service(bundle: bundle),
      );
}
