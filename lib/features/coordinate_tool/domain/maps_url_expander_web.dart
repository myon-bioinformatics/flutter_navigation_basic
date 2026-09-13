import 'dart:async';
import 'dart:html' as html;

import 'maps_url_policy.dart';

/// Expands a share URL by reading the final [HttpRequest.responseUrl] after
/// browser-followed redirects.
///
/// Web cannot inspect each redirect hop before the browser GETs it. This
/// helper therefore:
/// - refuses disallowed initial short URLs,
/// - aborts the XHR on timeout / error,
/// - accepts the result only when [MapsUrlPolicy.isAllowedExpandedMapsUri]
///   passes (defense in depth; hop-level SSRF prevention is IO-only).
///
/// CORS note: Google/Apple short-link hosts often omit CORS headers for
/// cross-origin XHR, so Flutter Web may still fail even for valid links.
Future<Uri> expandMapsShareUrl(Uri url) async {
  if (!MapsUrlPolicy.isAllowedShortShareUri(url)) {
    throw StateError('Refusing to expand disallowed Maps URL: $url');
  }

  final completer = Completer<Uri>();
  final request = html.HttpRequest();
  Timer? timeout;
  StreamSubscription<html.ProgressEvent>? loadSub;
  StreamSubscription<html.ProgressEvent>? errorSub;

  void cleanup() {
    timeout?.cancel();
    timeout = null;
    loadSub?.cancel();
    loadSub = null;
    errorSub?.cancel();
    errorSub = null;
  }

  void completeError(Object error) {
    cleanup();
    try {
      request.abort();
    } catch (_) {
      // Already finished / not abortable.
    }
    if (!completer.isCompleted) {
      completer.completeError(error);
    }
  }

  void completeValue(Uri value) {
    cleanup();
    if (!completer.isCompleted) {
      completer.complete(value);
    }
  }

  timeout = Timer(const Duration(seconds: 10), () {
    completeError(
      TimeoutException(
        'Timed out expanding Maps short link: ${url.toString()}',
        const Duration(seconds: 10),
      ),
    );
  });

  loadSub = request.onLoad.listen((_) {
    final responseUrl = request.responseUrl;
    final resolved = (responseUrl != null && responseUrl.isNotEmpty)
        ? Uri.tryParse(responseUrl)
        : url;
    if (resolved == null ||
        !MapsUrlPolicy.isAllowedExpandedMapsUri(resolved)) {
      completeError(
        StateError(
          'Expanded Maps URL is not an allowed Maps host: ${responseUrl ?? url}',
        ),
      );
      return;
    }
    completeValue(resolved);
  });
  errorSub = request.onError.listen((_) {
    completeError(
      StateError('Failed to expand Maps short link: ${url.toString()}'),
    );
  });
  request.open('GET', url.toString());
  request.send();
  return completer.future;
}
