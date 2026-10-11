// Pattern 113: DataDeduplicate — Python-produced validation/report example.
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/data_processing/json_list_asset.dart';

class Pattern113Service extends JsonListAsset {
  Pattern113Service({AssetBundle? bundle})
      : super('assets/data_processing/deduplicate_report.json', bundle: bundle);
}
