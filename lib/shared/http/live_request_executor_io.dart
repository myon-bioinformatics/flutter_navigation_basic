import 'dart:convert';
import 'dart:io';

import 'request_draft.dart';
import 'request_draft_codec.dart';
import 'request_executor.dart';
import 'request_field.dart';

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
  supportsLiveHttp: true,
  browserForbiddenHeadersStripped: false,
  platformLabel: 'io',
  limitationKey: 'httpDraft.live.ioReady',
);

/// Executes [draft] with `dart:io` [HttpClient].
///
/// Does **not** enable insecure TLS (`-k`) or automatic redirects (`-L`);
/// those remain explicit follow-ups.
Future<RequestExecutionResult> executeLiveRequest(RequestDraft draft) async {
  final issues = RequestDraftValidator.validate(draft);
  if (issues.isNotEmpty) {
    return RequestExecutionResult(
      statusCode: 0,
      body: {
        'ok': false,
        'error': 'validation_failed',
        'issues': [for (final i in issues) i.code],
      },
      executionPath: 'live-validation',
    );
  }

  final uri = RequestDraftCodec.buildUri(draft);
  if (uri == null) {
    return const RequestExecutionResult(
      statusCode: 0,
      body: {'ok': false, 'error': 'invalid_url'},
      executionPath: 'live-validation',
    );
  }
  final target = uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;
  final headers =
      RequestDraftCodec.buildHeaders(draft, redactSecrets: false);
  final body = RequestDraftCodec.buildBody(draft, redactSecrets: false);
  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 15);
  client.idleTimeout = const Duration(seconds: 15);
  try {
    final request = await client.openUrl(draft.method.label, uri);
    // Explicitly disable automatic redirects — labels claim no `-L`.
    request.followRedirects = false;
    request.maxRedirects = 0;
    headers.forEach(request.headers.set);
    final canWriteBody = draft.method != HttpMethod.get &&
        draft.method != HttpMethod.head &&
        body != null &&
        body.isNotEmpty;
    if (canWriteBody) {
      request.write(body);
    }
    final response = await request.close().timeout(const Duration(seconds: 30));
    final responseBody =
        await response.transform(utf8.decoder).join().timeout(
              const Duration(seconds: 30),
            );
    final responseHeaders = <String, String>{};
    response.headers.forEach((name, values) {
      responseHeaders[name] = values.join(', ');
    });
    Map<String, Object?> bodyMap;
    try {
      final decoded = responseBody.isEmpty ? null : jsonDecode(responseBody);
      if (decoded is Map) {
        bodyMap = Map<String, Object?>.from(decoded);
      } else {
        bodyMap = {'text': responseBody};
      }
    } on FormatException {
      bodyMap = {'text': responseBody};
    }
    return RequestExecutionResult(
      statusCode: response.statusCode,
      headers: responseHeaders,
      body: bodyMap,
      requestTarget: target,
      executionPath: 'live',
      wireDraft: draft,
    );
  } on Object catch (error) {
    return RequestExecutionResult(
      statusCode: 0,
      body: {
        'ok': false,
        'error': 'live_http_failed',
        'message': '$error',
      },
      requestTarget: target,
      executionPath: 'live-error',
      wireDraft: draft,
    );
  } finally {
    client.close(force: true);
  }
}
