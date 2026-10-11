// Pattern 029: TopN — generated example, not runtime collection logic.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/data_processing/processed_list_example.dart';

import 'service.dart';

class Pattern029View extends StatelessWidget {
  const Pattern029View({super.key, this.bundle});
  final AssetBundle? bundle;

  @override
  Widget build(BuildContext context) => ProcessedListExample(
        title: 'Pattern 029: TopN',
        asset: Pattern029Service(bundle: bundle),
      );
}
