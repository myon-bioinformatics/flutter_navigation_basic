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

  for (final raw in packages) {
    final package = raw as Map<String, dynamic>;
    final name = package['package'] as String?;
    if (name == null || !tracked.contains(name)) continue;

    final current = (package['current'] as Map<String, dynamic>?)?['version'];
    final latest = (package['latest'] as Map<String, dynamic>?)?['version'];
    if (current != latest) {
      stale.add('$name: current=$current, latest=$latest');
    }
  }

  if (stale.isNotEmpty) {
    stderr.writeln('Direct dependency not on latest stable:');
    for (final line in stale) {
      stderr.writeln('  $line');
    }
    exitCode = 1;
    return;
  }

  // `dart pub outdated --json` may omit packages that are already current.
  // Therefore absence from the result is treated as "no outdated finding",
  // matching the previous CI behavior while keeping parsing in Dart.
  stdout.writeln(
    'No outdated stable release found for tracked direct dependencies: '
    '${tracked.toList()..sort()}',
  );
}
