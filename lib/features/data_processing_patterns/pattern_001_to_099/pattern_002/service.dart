// Pattern 002: FilterMultiple — only the Python result-asset boundary.
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/data_processing/json_list_asset.dart';

class Pattern002Service extends JsonListAsset {
  Pattern002Service({AssetBundle? bundle})
      : super('assets/data_processing/filter_multiple.json', bundle: bundle);
}
