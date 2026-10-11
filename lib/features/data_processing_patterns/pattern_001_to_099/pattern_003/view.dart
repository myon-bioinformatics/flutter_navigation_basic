// Pattern 003: FilterNested — generated example, not runtime processing.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/data_processing/processed_list_example.dart';

import 'service.dart';

class Pattern003View extends StatelessWidget {
  const Pattern003View({super.key, this.bundle});

  final AssetBundle? bundle;

  @override
  Widget build(BuildContext context) => ProcessedListExample(
        title: 'Pattern 003: FilterNested',
        asset: Pattern003Service(bundle: bundle),
      );
}
