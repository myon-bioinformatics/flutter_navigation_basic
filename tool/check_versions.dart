import 'dart:convert';
import 'dart:io';

import 'src/toolkit_io.dart';

Future<void> main(List<String> args) async {
  final tracked = args.isEmpty
      ? {'get', 'shared_preferences', 'flutter_lints'}
      : args.toSet();

  final result = await runCommand('dart', ['pub', 'outdated', '--json']);
  if (!result.ok) {
    stderr.write(result.stderrText);
    exitCode = result.exitCode;
    return;
  }

  final data = jsonDecode(result.stdoutText) as Map<String, dynamic>;
  final packages = (data['packages'] as List<dynamic>? ?? const []);
  final stale = <String>[];
  final observed = <String>{};

  for (final raw in packages) {
    final package = raw as Map<String, dynamic>;
    final name = package['package'] as String?;
    if (name == null || !tracked.contains(name)) continue;
    observed.add(name);

    final current = (package['current'] as Map<String, dynamic>?)?['version'];
    final latest = (package['latest'] as Map<String, dynamic>?)?['version'];
    if (current != latest) {
      stale.add('$name: current=$current, latest=$latest');
    }
  }

  final missing = tracked.difference(observed);
  if (missing.isNotEmpty) {
    stderr.writeln('Tracked packages missing from pub outdated output: '
        '${missing.toList()..sort()}');
    exitCode = 2;
    return;
  }

  if (stale.isNotEmpty) {
    stderr.writeln('Direct dependency not on latest stable:');
    for (final line in stale) {
      stderr.writeln('  $line');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'Tracked direct dependencies are on latest stable releases: '
    '${tracked.toList()..sort()}',
  );
}
