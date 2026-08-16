import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final port = _readPort(args) ?? 8787;
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  stdout.writeln('Mock HTTP server listening on http://127.0.0.1:$port');
  stdout.writeln('Endpoints: /health, /status/<code>, /delay/<ms>, /echo');

  await for (final request in server) {
    try {
      await _handle(request);
    } on Object catch (error) {
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'error': error.toString()}));
      await request.response.close();
    }
  }
}

int? _readPort(List<String> args) {
  final index = args.indexOf('--port');
  if (index == -1 || index + 1 >= args.length) return null;
  return int.tryParse(args[index + 1]);
}

Future<void> _handle(HttpRequest request) async {
  final response = request.response;
  response.headers.contentType = ContentType.json;
  final segments = request.uri.pathSegments;

  if (request.uri.path == '/health') {
    response.write(jsonEncode({'ok': true, 'service': 'developer-toolkit-mock'}));
    await response.close();
    return;
  }

  if (segments.length == 2 && segments.first == 'status') {
    final status = int.tryParse(segments[1]);
    if (status == null || status < 100 || status > 599) {
      response.statusCode = HttpStatus.badRequest;
      response.write(jsonEncode({'error': 'status must be 100..599'}));
    } else {
      response.statusCode = status;
      response.write(jsonEncode({'status': status}));
    }
    await response.close();
    return;
  }

  if (segments.length == 2 && segments.first == 'delay') {
    final milliseconds = int.tryParse(segments[1]);
    if (milliseconds == null || milliseconds < 0 || milliseconds > 30000) {
      response.statusCode = HttpStatus.badRequest;
      response.write(jsonEncode({'error': 'delay must be 0..30000 ms'}));
    } else {
      await Future<void>.delayed(Duration(milliseconds: milliseconds));
      response.write(jsonEncode({'delayedMs': milliseconds}));
    }
    await response.close();
    return;
  }

  if (request.uri.path == '/echo') {
    final body = await utf8.decoder.bind(request).join();
    final headers = <String, List<String>>{};
    request.headers.forEach((name, values) => headers[name] = values);
    response.write(jsonEncode({
      'method': request.method,
      'path': request.uri.toString(),
      'headers': headers,
      'body': body,
    }));
    await response.close();
    return;
  }

  response.statusCode = HttpStatus.notFound;
  response.write(jsonEncode({'error': 'not found'}));
  await response.close();
}
