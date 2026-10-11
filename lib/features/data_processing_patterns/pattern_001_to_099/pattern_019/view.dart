// Pattern 019: TextIndex — generated example, not runtime text processing.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/data_processing/processed_list_example.dart';

import 'service.dart';

class Pattern019View extends StatelessWidget {
  const Pattern019View({super.key, this.bundle});

  final AssetBundle? bundle;

  @override
  Widget build(BuildContext context) => ProcessedListExample(
        title: 'Pattern 019: TextIndex',
        asset: Pattern019Service(bundle: bundle),
      );
}
