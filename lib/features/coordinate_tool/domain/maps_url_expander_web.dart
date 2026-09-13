import 'dart:async';
import 'dart:html' as html;

/// Expands a share URL by reading the final [HttpRequest.responseUrl] after
/// browser-followed redirects.
Future<Uri> expandMapsShareUrl(Uri url) async {
  final completer = Completer<Uri>();
  final request = html.HttpRequest();
  request.open('GET', url.toString());
  request.onLoad.listen((_) {
    final responseUrl = request.responseUrl;
    if (responseUrl != null && responseUrl.isNotEmpty) {
      completer.complete(Uri.parse(responseUrl));
    } else {
      completer.complete(url);
    }
  });
  request.onError.listen((_) {
    if (!completer.isCompleted) {
      completer.completeError(
        StateError('Failed to expand Maps short link: ${url.toString()}'),
      );
    }
  });
  request.send();
  return completer.future;
}
