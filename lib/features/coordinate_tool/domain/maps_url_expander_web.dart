import 'dart:async';
import 'dart:html' as html;

/// Expands a share URL by reading the final [HttpRequest.responseUrl] after
/// browser-followed redirects.
///
/// CORS note: Google/Apple short-link hosts often omit CORS headers for
/// cross-origin XHR, so Flutter Web may hit [HttpRequest.onError] even when
/// the browser itself could follow the redirect in a top-level navigation.
Future<Uri> expandMapsShareUrl(Uri url) async {
  final completer = Completer<Uri>();
  final request = html.HttpRequest();
  Timer? timeout;

  void completeError(Object error) {
    timeout?.cancel();
    if (!completer.isCompleted) {
      completer.completeError(error);
    }
  }

  void completeValue(Uri value) {
    timeout?.cancel();
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

  request.open('GET', url.toString());
  request.onLoad.listen((_) {
    final responseUrl = request.responseUrl;
    if (responseUrl != null && responseUrl.isNotEmpty) {
      completeValue(Uri.parse(responseUrl));
    } else {
      completeValue(url);
    }
  });
  request.onError.listen((_) {
    completeError(
      StateError('Failed to expand Maps short link: ${url.toString()}'),
    );
  });
  request.send();
  return completer.future;
}
