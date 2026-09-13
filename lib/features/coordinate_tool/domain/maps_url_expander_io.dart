import 'dart:io';

import 'maps_url_policy.dart';

/// One hop result for Maps short-link expansion (no automatic redirects).
class MapsRedirectHop {
  const MapsRedirectHop({
    required this.statusCode,
    this.location,
  });

  final int statusCode;
  final Uri? location;

  bool get isRedirect =>
      statusCode >= 300 && statusCode < 400 && location != null;
}

/// Fetches a single hop without following redirects.
typedef MapsRedirectFetcher = Future<MapsRedirectHop> Function(Uri url);

/// Follows HTTP(S) redirects manually and returns the final URI.
///
/// Each next [Location] is validated with [MapsUrlPolicy.isAllowedRedirectHopUri]
/// **before** the next GET, so private / arbitrary hosts are never contacted.
Future<Uri> expandMapsShareUrl(
  Uri url, {
  MapsRedirectFetcher? fetch,
  int maxRedirects = 15,
}) async {
  if (!MapsUrlPolicy.isAllowedShortShareUri(url) &&
      !MapsUrlPolicy.isAllowedRedirectHopUri(url)) {
    throw StateError('Refusing to expand disallowed Maps URL: $url');
  }

  final fetcher = fetch ?? _httpClientFetcher;
  var current = url;

  for (var hop = 0; hop <= maxRedirects; hop++) {
    if (!MapsUrlPolicy.isAllowedRedirectHopUri(current)) {
      throw StateError('Refusing Maps redirect hop: $current');
    }
    final response = await fetcher(current).timeout(const Duration(seconds: 10));
    if (!response.isRedirect) {
      return current;
    }
    final location = response.location!;
    final next = location.isAbsolute ? location : current.resolveUri(location);
    if (!MapsUrlPolicy.isAllowedRedirectHopUri(next)) {
      throw StateError('Refusing Maps redirect target before GET: $next');
    }
    current = next;
  }
  throw StateError('Too many Maps short-link redirects (max $maxRedirects)');
}

Future<MapsRedirectHop> _httpClientFetcher(Uri url) async {
  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 10);
  try {
    final request = await client.getUrl(url);
    request.followRedirects = false;
    request.maxRedirects = 0;
    request.headers.set(
      HttpHeaders.userAgentHeader,
      'CoordinateTool/1.0 (Flutter; maps short-link expand)',
    );
    final response = await request.close().timeout(const Duration(seconds: 10));
    await response.drain<void>().timeout(const Duration(seconds: 10));

    Uri? location;
    final raw = response.headers.value(HttpHeaders.locationHeader);
    if (raw != null && raw.isNotEmpty) {
      location = Uri.tryParse(raw);
    }
    return MapsRedirectHop(statusCode: response.statusCode, location: location);
  } finally {
    client.close(force: true);
  }
}
