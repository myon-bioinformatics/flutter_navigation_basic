// Pattern 043: WindowPaging — rendered Python state, no GetX controller.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/data_processing/processed_list_example.dart';

import 'service.dart';

class Pattern043View extends StatelessWidget {
  const Pattern043View({super.key, this.bundle});
  final AssetBundle? bundle;

  @override
  Widget build(BuildContext context) => ProcessedListExample(
        title: 'Pattern 043: WindowPaging',
        asset: Pattern043Service(bundle: bundle),
      );
}
