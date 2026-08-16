import 'dart:io';

import 'src/toolkit_io.dart';

Future<void> main(List<String> args) async {
  final command = args.isEmpty ? 'help' : args.first;
  final rest = args.skip(1).toList();

  switch (command) {
    case 'inspect':
      exitCode = await _forward('dart', ['run', 'tool/inspect.dart', ...rest]);
      return;
    case 'check':
      exitCode = await _forward('dart', ['run', 'tool/check.dart', ...rest]);
      return;
    case 'full':
      exitCode = await _forward('dart', ['run', 'tool/check.dart', '--full', ...rest]);
      return;
    case 'versions':
      exitCode = await _forward('dart', ['run', 'tool/check_versions.dart', ...rest]);
      return;
    case 'meta':
      exitCode = await _forward('dart', ['run', 'tool/build_meta.dart', ...rest]);
      return;
    case 'size':
      exitCode = await _forward('dart', ['run', 'tool/android_size.dart', ...rest]);
      return;
    case 'net':
      if (rest.isEmpty) {
        stderr.writeln('Usage: dart run tool/dev.dart net <url>');
        exitCode = 64;
        return;
      }
      exitCode = await _forward('dart', ['run', 'tool/net_probe.dart', ...rest]);
      return;
    case 'mock':
      exitCode = await _forward('dart', ['run', 'tool/mock_http_server.dart', ...rest]);
      return;
    case 'bundle':
      exitCode = await _bundle(rest);
      return;
    case 'all':
      final checkCode = await _forward('dart', ['run', 'tool/check.dart', '--full']);
      if (checkCode != 0) {
        exitCode = checkCode;
        return;
      }
      exitCode = await _bundle(rest);
      return;
    case 'help':
    case '--help':
    case '-h':
      _printHelp();
      return;
    default:
      stderr.writeln('Unknown command: $command');
      _printHelp();
      exitCode = 64;
  }
}

Future<int> _forward(String executable, List<String> arguments) async {
  final result = await runCommand(executable, arguments, stream: true);
  return result.exitCode;
}

Future<int> _bundle(List<String> args) async {
  final outputName = _readOutputPath(args);
  if (outputName == null) return 64;

  final diagnostics = Directory('build/diagnostics');
  if (await diagnostics.exists()) {
    await diagnostics.delete(recursive: true);
  }
  await diagnostics.create(recursive: true);

  stdout.writeln('Creating diagnostic bundle staging directory...');
  stdout.writeln(
    'Note: diagnostics may include machine-local SDK paths and environment details; '
    'review before sharing externally.',
  );

  final probes = <_Capture>[
    const _Capture(
      'inspect.json',
      'dart',
      ['run', 'tool/inspect.dart', '--json'],
    ),
    const _Capture('flutter-version.txt', 'flutter', ['--version']),
    const _Capture('flutter-doctor.txt', 'flutter', ['doctor', '-v']),
    const _Capture('pub-outdated.txt', 'dart', ['pub', 'outdated']),
    const _Capture('pub-deps.txt', 'flutter', ['pub', 'deps', '--style=compact']),
    const _Capture('git-status.txt', 'git', ['status', '--short', '--branch']),
  ];

  for (final probe in probes) {
    stdout.writeln('--- ${probe.fileName}');
    final result = await runCommand(probe.executable, probe.arguments);
    final file = File('${diagnostics.path}/${probe.fileName}');
    await file.writeAsString(
      '${result.stdoutText}'
      '${result.stderrText.isEmpty ? '' : '\n[stderr]\n${result.stderrText}'}'
      '\n[exit=${result.exitCode} duration=${formatDuration(result.duration)}]\n',
    );
    if (!result.ok) {
      stderr.writeln('WARN: ${probe.fileName} exited ${result.exitCode}; captured in bundle.');
    }
  }

  final output = File(outputName);
  await output.parent.create(recursive: true);
  if (await output.exists()) await output.delete();

  final python = await _findPython();
  if (python == null) {
    stderr.writeln(
      'Python was not found. Diagnostic files are available at ${diagnostics.path}, '
      'but ZIP creation was skipped.',
    );
    return 2;
  }

  final zip = await runCommand(
    python.executable,
    [...python.prefixArguments, '-m', 'zipfile', '-c', output.path, diagnostics.path],
    stream: true,
  );
  if (!zip.ok) return zip.exitCode;

  final verify = await runCommand(
    python.executable,
    [...python.prefixArguments, '-m', 'zipfile', '-t', output.path],
    stream: true,
  );
  if (!verify.ok) return verify.exitCode;

  stdout.writeln('Diagnostic bundle: ${output.path} (${formatBytes(await output.length())})');
  return 0;
}

String? _readOutputPath(List<String> args) {
  final index = args.indexOf('--output');
  if (index < 0) return 'build/diagnostics.zip';
  if (index + 1 >= args.length) {
    stderr.writeln('Missing value after --output.');
    return null;
  }
  final value = args[index + 1].trim();
  if (value.isEmpty || value.startsWith('--')) {
    stderr.writeln('Invalid --output value. Provide a non-empty ZIP path.');
    return null;
  }
  return value;
}

Future<_PythonCommand?> _findPython() async {
  final candidates = <_PythonCommand>[
    if (Platform.isWindows) const _PythonCommand('py', ['-3']),
    const _PythonCommand('python3', []),
    const _PythonCommand('python', []),
  ];

  for (final candidate in candidates) {
    try {
      final result = await runCommand(
        candidate.executable,
        [...candidate.prefixArguments, '--version'],
      );
      if (result.ok) return candidate;
    } on ProcessException {
      // Try the next standard launcher name.
    }
  }
  return null;
}

void _printHelp() {
  stdout.writeln('''Developer Toolkit

Usage:
  dart run tool/dev.dart inspect [--json]
  dart run tool/dev.dart check
  dart run tool/dev.dart full
  dart run tool/dev.dart versions
  dart run tool/dev.dart meta [--artifact path] [--analysis path] [--platform name]
  dart run tool/dev.dart size [--target lib/main_prod.dart]
  dart run tool/dev.dart net <url>
  dart run tool/dev.dart mock [args]
  dart run tool/dev.dart bundle [--output path.zip]
  dart run tool/dev.dart all [--output path.zip]

Recommended one-liners:
  dart run tool/dev.dart check   # quick repository health
  dart run tool/dev.dart full    # quick health + both release web builds
  dart run tool/dev.dart meta    # refresh app/screen source metadata
  dart run tool/dev.dart size    # Android arm64 release + --analyze-size + metadata
  dart run tool/dev.dart bundle  # reusable diagnostic ZIP
  dart run tool/dev.dart all     # full validation + diagnostic ZIP
''');
}

class _Capture {
  const _Capture(this.fileName, this.executable, this.arguments);

  final String fileName;
  final String executable;
  final List<String> arguments;
}

class _PythonCommand {
  const _PythonCommand(this.executable, this.prefixArguments);

  final String executable;
  final List<String> prefixArguments;
}
