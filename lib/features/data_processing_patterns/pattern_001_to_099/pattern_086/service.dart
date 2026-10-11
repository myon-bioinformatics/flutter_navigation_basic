// Pattern 086: Deduplication — reuse the shared distinct-selection asset.
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/data_processing/json_list_asset.dart';

class Pattern086Service extends JsonListAsset {
  Pattern086Service({AssetBundle? bundle})
      : super('assets/data_processing/distinct_filter.json', bundle: bundle);
}
