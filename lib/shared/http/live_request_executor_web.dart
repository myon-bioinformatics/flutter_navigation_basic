import 'request_draft.dart';
import 'request_draft_codec.dart';
import 'request_executor.dart';

class LiveHttpCapabilities {
  const LiveHttpCapabilities({
    required this.supportsLiveHttp,
    required this.browserForbiddenHeadersStripped,
    required this.platformLabel,
    required this.limitationKey,
  });

  final bool supportsLiveHttp;
  final bool browserForbiddenHeadersStripped;
  final String platformLabel;
  final String limitationKey;
}

/// Flutter Web cannot send browser-forbidden headers (`Authorization`,
/// `Cookie`, etc.) via XHR/fetch the way curl can. Live in-app execution is
/// therefore not claimed to be curl-equivalent; callers must copy redacted
/// curl instead.
const liveHttpCapabilities = LiveHttpCapabilities(
  supportsLiveHttp: false,
  browserForbiddenHeadersStripped: true,
  platformLabel: 'web',
  limitationKey: 'httpDraft.live.webCorsLimits',
);

Future<RequestExecutionResult> executeLiveRequest(RequestDraft draft) async {
  final uri = RequestDraftCodec.buildUri(draft);
  final target = uri == null
      ? draft.normalizedUrl
      : (uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path);
  return RequestExecutionResult(
    statusCode: 0,
    body: {
      'ok': false,
      'error': 'web_live_http_limited',
      'reason':
          'Browser CORS and forbidden-request-header rules prevent '
          'curl-equivalent live execution. Copy the redacted curl command '
          'instead.',
      'platform': 'web',
    },
    requestTarget: target,
  );
}
