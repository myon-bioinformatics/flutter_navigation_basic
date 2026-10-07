import 'curl_import_result.dart';

/// Web builds intentionally do not import the legacy Dart curl parser.
///
/// This function exists only so the shared import surface type-checks. Runtime
/// selection is a compile-time contract: Web production for this slice is built
/// with CURL_PYTHON_RUNTIME=true and routes through importPythonCurl.
CurlImportResult importLegacyCurl(
  String raw, {
  required String Function() newId,
}) =>
    throw UnsupportedError('legacy curl parser is not linked in Web builds');
