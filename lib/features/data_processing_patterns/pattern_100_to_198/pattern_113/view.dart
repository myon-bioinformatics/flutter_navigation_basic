// Pattern 113: DataDeduplicate — generated report, not runtime processing.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/data_processing/processed_list_example.dart';

import 'service.dart';

class Pattern113View extends StatelessWidget {
  const Pattern113View({super.key, this.bundle});

  final AssetBundle? bundle;

  @override
  Widget build(BuildContext context) => ProcessedListExample(
        title: 'Pattern 113: DataDeduplicate',
        asset: Pattern113Service(bundle: bundle),
      );
}
