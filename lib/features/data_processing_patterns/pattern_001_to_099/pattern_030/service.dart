// Pattern 030: DistinctFilter — only the Python result-asset boundary.
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/data_processing/json_list_asset.dart';

class Pattern030Service extends JsonListAsset {
  Pattern030Service({AssetBundle? bundle})
      : super('assets/data_processing/distinct_filter.json', bundle: bundle);
}
