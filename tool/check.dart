import 'dart:io';

import 'src/toolkit_io.dart';

Future<void> main(List<String> args) async {
  final full = args.contains('--full');
  final steps = <_Step>[
    const _Step(
      'Resolve dependencies',
      'flutter',
      ['pub', 'get'],
      verifyLockfileAfter: true,
    ),
    const _Step('Inspect repository', 'dart', ['run', 'tool/inspect.dart']),
    const _Step('Analyze', 'flutter', ['analyze', '--no-fatal-infos']),
    const _Step('Test', 'flutter', ['test']),
  ];

  stdout.writeln('Developer Toolkit check (${full ? 'full' : 'quick'})');
  stdout.writeln('Use --full to include both release web builds.');
  stdout.writeln();

  for (final step in steps) {
    if (!await _runStep(step)) return;
    if (step.verifyLockfileAfter) {
      final lock = await runCommand(
        'git',
        ['diff', '--exit-code', '--', 'pubspec.lock'],
      );
      if (!lock.ok) {
        stderr.writeln('FAIL: pubspec.lock changed after flutter pub get.');
        stderr.write(lock.stdoutText);
        stderr.write(lock.stderrText);
        exitCode = 1;
        return;
      }
      stdout.writeln('PASS: pubspec.lock is reproducible.');
    }
  }

  if (full) {
    if (!await _runStep(const _Step(
      'Build default web entrypoint',
      'flutter',
      ['build', 'web', '--release', '--base-href', '/flutter_navigation_basic/'],
    ))) {
      return;
    }
    final defaultSize = await directorySize(Directory('build/web'));
    stdout.writeln('Default web build size: ${formatBytes(defaultSize)}');

    if (!await _runStep(const _Step(
      'Build production entrypoint',
      'flutter',
      [
        'build',
        'web',
        '--release',
        '-t',
        'lib/main_prod.dart',
        '--base-href',
        '/flutter_navigation_basic/',
      ],
    ))) {
      return;
    }
    final productionSize = await directorySize(Directory('build/web'));
    stdout.writeln('Production web build size: ${formatBytes(productionSize)}');
  }

  stdout.writeln();
  stdout.writeln('PASS: developer health check completed.');
}

Future<bool> _runStep(_Step step) async {
  stdout.writeln('--- ${step.label}');
  final result = await runCommand(step.executable, step.arguments, stream: true);
  stdout.writeln('exit=${result.exitCode} duration=${formatDuration(result.duration)}');
  stdout.writeln();
  if (!result.ok) {
    stderr.writeln('FAIL: ${step.label}');
    exitCode = result.exitCode == 0 ? 1 : result.exitCode;
    return false;
  }
  return true;
}

class _Step {
  const _Step(
    this.label,
    this.executable,
    this.arguments, {
    this.verifyLockfileAfter = false,
  });

  final String label;
  final String executable;
  final List<String> arguments;
  final bool verifyLockfileAfter;
}
