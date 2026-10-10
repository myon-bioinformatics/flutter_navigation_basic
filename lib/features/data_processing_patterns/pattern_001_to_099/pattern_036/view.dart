// Pattern 036: LazyList — rendered Python state, no GetX controller.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/data_processing/processed_list_example.dart';

import 'service.dart';

class Pattern036View extends StatelessWidget {
  const Pattern036View({super.key, this.bundle});
  final AssetBundle? bundle;

  @override
  Widget build(BuildContext context) => ProcessedListExample(
        title: 'Pattern 036: LazyList',
        asset: Pattern036Service(bundle: bundle),
      );
}
