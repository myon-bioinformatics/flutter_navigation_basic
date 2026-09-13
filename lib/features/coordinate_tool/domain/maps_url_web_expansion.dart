/// Web short-link expansion is intentionally unsupported.
///
/// Browsers follow redirects inside XHR/fetch before Dart can validate each
/// Location hop. Refusing expansion avoids GETting attacker-controlled
/// redirect targets. Paste a fully expanded Google/Apple Maps URL instead.
Future<Uri> expandMapsShareUrlOnWeb(Uri url) async {
  throw UnsupportedError(
    'Maps short-link expansion is unsupported on Flutter Web because redirect '
    'hops cannot be validated before the browser issues GET requests. Paste a '
    'fully expanded Google Maps or Apple Maps URL instead. (url: $url)',
  );
}
