import 'curl_import_result.dart';
import 'curl_safe_subset.dart';

/// Static Web compatibility adapter.
///
/// The Python-enabled Docker/runtime build never calls this function because
/// CURL_PYTHON_RUNTIME=true routes importCurlText through importPythonCurl.
/// Keeping this adapter explicit prevents the runtime-enabled path from
/// silently falling back while preserving ordinary static Web behavior.
CurlImportResult importLegacyCurl(
  String raw, {
  required String Function() newId,
}) =>
    CurlSafeSubset.tryParse(raw, newId: newId);
