import 'dart:async';
import 'dart:js_interop';

@JS('XMLHttpRequest')
extension type _Request._(JSObject _) implements JSObject {
  external factory _Request();
  external void open(String method, String url);
  external void setRequestHeader(String name, String value);
  external void send(JSAny? data);
  external void abort();
  external int get status;
  external String get responseText;
  external String get responseURL;
  external set timeout(int value);
  external set onload(JSFunction? value);
  external set onerror(JSFunction? value);
  external set ontimeout(JSFunction? value);
  external set onabort(JSFunction? value);
}

/// This first runtime adapter sends data only to the serving loopback origin.
/// No remote endpoint configuration, CORS bypass or silent Dart fallback.
Future<String> postCurlToPython(String raw) {
  final base = Uri.base;
  if (base.scheme != 'http' || base.host != '127.0.0.1') {
    return Future.error(StateError('runtimeUnavailable'));
  }
  final endpoint = base.resolve('/__runtime__/curl-import');
  final done = Completer<String>();
  final request = _Request();
  void fail(Object error) {
    if (!done.isCompleted) done.completeError(error);
  }
  request.open('POST', endpoint.toString());
  request.timeout = 5000;
  request.setRequestHeader('Content-Type', 'text/plain; charset=utf-8');
  request.setRequestHeader('X-Curl-Runtime', '1');
  request.onload = (() {
    if (done.isCompleted) return;
    if (request.status != 200 || request.responseURL != endpoint.toString()) {
      fail(StateError('runtimeUnavailable'));
    } else if (request.responseText.length > 1048576) {
      fail(const FormatException('runtimeResponse'));
    } else {
      done.complete(request.responseText);
    }
  }).toJS;
  request.onerror = (() => fail(StateError('runtimeUnavailable'))).toJS;
  request.ontimeout = (() => fail(TimeoutException('runtimeTimeout'))).toJS;
  request.onabort = (() => fail(StateError('runtimeUnavailable'))).toJS;
  try {
    request.send(raw.toJS);
  } catch (_) {
    request.abort();
    fail(StateError('runtimeUnavailable'));
  }
  return done.future;
}
