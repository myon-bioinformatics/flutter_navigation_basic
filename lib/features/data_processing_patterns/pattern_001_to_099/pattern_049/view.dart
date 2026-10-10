import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/data_processing/json_list_asset.dart';
import 'package:flutter_application_1/core/data_processing/processed_list_example.dart';

class Pattern049View extends StatelessWidget {
  const Pattern049View({super.key, this.bundle});
  final AssetBundle? bundle;

  @override
  Widget build(BuildContext context) => ProcessedListExample(
    title: 'Pattern 049: GroupedList',
    asset: JsonListAsset('assets/data_processing/structure_049.json', bundle: bundle),
  );
}
