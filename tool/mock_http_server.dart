import 'dart:convert';
import 'dart:io';

import 'src/mock_auth.dart';
import 'src/mock_mcp.dart';

Future<void> main(List<String> args) async {
  final port = _readPort(args) ?? 8787;
  final auth = MockAuthHandler();
  final mcp = MockMcpRoutes.forPort(port);
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  stdout.writeln('Mock HTTP server listening on http://127.0.0.1:$port');
  stdout.writeln(
    'Endpoints: /health, /status/<code>, /delay/<ms>, /echo, '
    '/auth/bearer|api-key|basic|digest|hmac|rate-limited, '
    '/mcp, /.well-known/oauth-*, /mcp/support-matrix',
  );

  await for (final request in server) {
    try {
      await _handle(request, auth, mcp);
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

Future<void> _handle(
  HttpRequest request,
  MockAuthHandler auth,
  MockMcpRoutes mcp,
) async {
  final response = request.response;
  response.headers.contentType = ContentType.json;
  final segments = request.uri.pathSegments;

  final headerMap = <String, String>{};
  request.headers.forEach((name, values) {
    if (values.isNotEmpty) headerMap[name] = values.join(', ');
  });
  final queryMap = <String, String>{
    for (final entry in request.uri.queryParameters.entries)
      entry.key: entry.value,
  };

  final requestTarget = request.uri.hasQuery
      ? '${request.uri.path}?${request.uri.query}'
      : request.uri.path;
  final authResult = auth.handle(
    method: request.method,
    path: request.uri.path,
    headers: headerMap,
    query: queryMap,
    requestTarget: requestTarget,
  );
  if (authResult != null) {
    response.statusCode = authResult.statusCode;
    authResult.headers.forEach(response.headers.set);
    response.write(jsonEncode(authResult.body));
    await response.close();
    return;
  }

  final body = await utf8.decoder.bind(request).join();
  final mcpResult = mcp.handle(
    method: request.method,
    path: request.uri.path,
    headers: headerMap,
    rawBody: body.isEmpty ? null : body,
  );
  if (mcpResult != null) {
    response.statusCode = mcpResult.statusCode;
    mcpResult.headers.forEach(response.headers.set);
    if (mcpResult.body != null) {
      response.write(jsonEncode(mcpResult.body));
    }
    await response.close();
    return;
  }

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
