import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/data_processing/processed_list_example.dart';
import 'service.dart';
class Pattern037View extends StatelessWidget {
  const Pattern037View({super.key, this.bundle});
  final AssetBundle? bundle;
  @override
  Widget build(BuildContext context) => ProcessedListExample(title: 'Pattern 037: PullRefresh', asset: Pattern037Service(bundle: bundle));
}
