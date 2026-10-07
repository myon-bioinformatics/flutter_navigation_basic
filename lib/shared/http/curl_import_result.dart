import 'request_draft.dart';
import 'request_draft_codec.dart';

/// Result shared by legacy and external curl import implementations.
class CurlImportResult {
  const CurlImportResult({
    this.draft,
    this.errors = const <RequestDraftIssue>[],
    this.warnings = const <RequestDraftIssue>[],
  });

  final RequestDraft? draft;
  final List<RequestDraftIssue> errors;
  final List<RequestDraftIssue> warnings;

  bool get isOk => draft != null && errors.isEmpty;
}
