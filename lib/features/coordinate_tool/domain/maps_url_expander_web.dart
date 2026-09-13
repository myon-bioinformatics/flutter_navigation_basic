import 'maps_url_web_expansion.dart';

/// Web Maps short-link expander — fails closed without starting a network request.
///
/// Hop-level SSRF prevention is not possible with browser-followed redirects, so
/// this entry point never opens an XHR/fetch. Callers should ask users to paste
/// an already-expanded Google Maps or Apple Maps URL.
Future<Uri> expandMapsShareUrl(Uri url) => expandMapsShareUrlOnWeb(url);
