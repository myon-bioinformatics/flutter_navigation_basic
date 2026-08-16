import 'dart:async';
import 'dart:io';

import 'src/toolkit_io.dart';

const _networkTimeout = Duration(seconds: 10);

Future<void> main(List<String> args) async {
  if (args.isEmpty || args.contains('--help')) {
    stdout.writeln('Usage: dart run tool/net_probe.dart <http-or-https-url>');
    stdout.writeln('Shows DNS, TCP, TLS (HTTPS), HTTP status/headers, bytes, and timings.');
    return;
  }

  final uri = Uri.tryParse(args.first);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    stderr.writeln('Invalid URL: ${args.first}');
    exitCode = 64;
    return;
  }
  if (uri.scheme != 'http' && uri.scheme != 'https') {
    stderr.writeln('Only http:// and https:// are supported.');
    exitCode = 64;
    return;
  }

  final port = uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80);
  stdout.writeln('=== Network Probe ===');
  stdout.writeln('target: $uri');
  stdout.writeln();

  try {
    final dnsWatch = Stopwatch()..start();
    final addresses = await InternetAddress.lookup(uri.host).timeout(_networkTimeout);
    dnsWatch.stop();
    stdout.writeln('[DNS] ${formatDuration(dnsWatch.elapsed)}');
    for (final address in addresses) {
      stdout.writeln('  ${address.type.name}: ${address.address}');
    }

    final tcpWatch = Stopwatch()..start();
    final socket = await Socket.connect(
      uri.host,
      port,
      timeout: _networkTimeout,
    );
    try {
      tcpWatch.stop();
      stdout.writeln('[TCP] ${formatDuration(tcpWatch.elapsed)}');
      stdout.writeln('  local : ${socket.address.address}:${socket.port}');
      stdout.writeln('  remote: ${socket.remoteAddress.address}:${socket.remotePort}');
    } finally {
      await socket.close();
    }

    if (uri.scheme == 'https') {
      final tlsWatch = Stopwatch()..start();
      final secure = await SecureSocket.connect(
        uri.host,
        port,
        timeout: _networkTimeout,
      );
      try {
        tlsWatch.stop();
        stdout.writeln('[TLS] ${formatDuration(tlsWatch.elapsed)}');
        final cert = secure.peerCertificate;
        if (cert != null) {
          stdout.writeln('  subject : ${cert.subject}');
          stdout.writeln('  issuer  : ${cert.issuer}');
          stdout.writeln('  valid   : ${cert.startValidity.toIso8601String()} '
              '→ ${cert.endValidity.toIso8601String()}');
          stdout.writeln('  sha1    : ${cert.sha1}');
        }
      } finally {
        await secure.close();
      }
    }

    final client = HttpClient()
      ..connectionTimeout = _networkTimeout
      ..userAgent = 'flutter-navigation-basic-dev-probe/1.0';
    try {
      final httpWatch = Stopwatch()..start();
      final request = await client.getUrl(uri).timeout(_networkTimeout);
      request.followRedirects = true;
      request.maxRedirects = 5;
      final response = await request.close().timeout(_networkTimeout);
      var bodyBytes = 0;
      await for (final chunk in response.timeout(_networkTimeout)) {
        bodyBytes += chunk.length;
      }
      httpWatch.stop();

      stdout.writeln('[HTTP] ${formatDuration(httpWatch.elapsed)}');
      stdout.writeln('  status   : ${response.statusCode} ${response.reasonPhrase}');
      stdout.writeln('  redirects: ${response.redirects.length}');
      stdout.writeln('  bytes    : $bodyBytes (${formatBytes(bodyBytes)})');
      response.headers.forEach((name, values) {
        stdout.writeln('  <$name: ${values.join(', ')}');
      });

      if (response.statusCode >= 400) exitCode = 1;
    } finally {
      client.close(force: true);
    }
  } on TimeoutException catch (error) {
    stderr.writeln('Probe timed out after ${_networkTimeout.inSeconds}s: $error');
    exitCode = 1;
  } on Object catch (error) {
    stderr.writeln('Probe failed: $error');
    exitCode = 1;
  }
}
