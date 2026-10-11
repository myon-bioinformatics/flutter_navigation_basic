// Pattern 026: SortedSet — generated example, not runtime collection logic.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/data_processing/processed_list_example.dart';

import 'service.dart';

class Pattern026View extends StatelessWidget {
  const Pattern026View({super.key, this.bundle});
  final AssetBundle? bundle;

  @override
  Widget build(BuildContext context) => ProcessedListExample(
        title: 'Pattern 026: SortedSet',
        asset: Pattern026Service(bundle: bundle),
      );
}
