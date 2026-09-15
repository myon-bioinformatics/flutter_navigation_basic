import 'request_draft.dart';
import 'request_draft_codec.dart';
import 'request_executor.dart';

/// Capability flags for the live HTTP executor on this platform.
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

const liveHttpCapabilities = LiveHttpCapabilities(
  supportsLiveHttp: false,
  browserForbiddenHeadersStripped: false,
  platformLabel: 'unknown',
  limitationKey: 'httpDraft.live.unsupported',
);

/// Live network execution is unavailable on this stub platform.
Future<RequestExecutionResult> executeLiveRequest(RequestDraft draft) async {
  final uri = RequestDraftCodec.buildUri(draft);
  final target = uri == null
      ? draft.normalizedUrl
      : (uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path);
  return RequestExecutionResult(
    statusCode: 0,
    body: {
      'ok': false,
      'error': 'live_http_unsupported',
      'platform': liveHttpCapabilities.platformLabel,
    },
    requestTarget: target,
  );
}
