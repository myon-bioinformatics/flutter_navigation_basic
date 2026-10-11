// Pattern 027: PriorityQueue — generated example, not runtime collection logic.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/data_processing/processed_list_example.dart';

import 'service.dart';

class Pattern027View extends StatelessWidget {
  const Pattern027View({super.key, this.bundle});
  final AssetBundle? bundle;

  @override
  Widget build(BuildContext context) => ProcessedListExample(
        title: 'Pattern 027: PriorityQueue',
        asset: Pattern027Service(bundle: bundle),
      );
}
