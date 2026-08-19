import 'dart:js_interop';

@JS('window.open')
external JSAny? _windowOpen(JSString url, JSString target);

Future<bool> openExternalUrl(Uri uri) async {
  _windowOpen(uri.toString().toJS, '_blank'.toJS);
  return true;
}
