import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/data_processing/json_list_asset.dart';
import 'package:flutter_application_1/core/data_processing/processed_list_example.dart';

class Pattern048View extends StatelessWidget {
  const Pattern048View({super.key, this.bundle});
  final AssetBundle? bundle;

  @override
  Widget build(BuildContext context) => ProcessedListExample(
    title: 'Pattern 048: FlatList',
    asset: JsonListAsset('assets/data_processing/structure_048.json', bundle: bundle),
  );
}
