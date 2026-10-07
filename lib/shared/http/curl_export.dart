import 'request_draft.dart';
import 'request_draft_codec.dart';

/// Export a request draft as curl without depending on the legacy curl parser.
///
/// Export remains Dart-owned for now because the editor uses it synchronously
/// for preview/copy. Parsing is a separate responsibility and may be supplied
/// by the Python runtime.
String exportCurl(
  RequestDraft draft, {
  bool redactSecrets = true,
}) =>
    RequestDraftCodec.toCurl(draft, redactSecrets: redactSecrets);
