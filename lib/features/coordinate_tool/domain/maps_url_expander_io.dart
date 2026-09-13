import 'dart:io';

/// Follows HTTP(S) redirects and returns the final URI.
Future<Uri> expandMapsShareUrl(Uri url) async {
  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 10);
  try {
    final request = await client.getUrl(url);
    request.followRedirects = true;
    request.maxRedirects = 15;
    request.headers.set(
      HttpHeaders.userAgentHeader,
      'CoordinateTool/1.0 (Flutter; maps short-link expand)',
    );
    final response = await request.close().timeout(const Duration(seconds: 10));
    await response.drain<void>().timeout(const Duration(seconds: 10));

    var resolved = url;
    for (final redirect in response.redirects) {
      final location = redirect.location;
      resolved = location.isAbsolute ? location : resolved.resolveUri(location);
    }
    return resolved;
  } finally {
    client.close(force: true);
  }
}
