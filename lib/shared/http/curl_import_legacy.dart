import 'curl_import_result.dart';
import 'curl_safe_subset.dart';

CurlImportResult importLegacyCurl(
  String raw, {
  required String Function() newId,
}) =>
    CurlSafeSubset.tryParse(raw, newId: newId);
