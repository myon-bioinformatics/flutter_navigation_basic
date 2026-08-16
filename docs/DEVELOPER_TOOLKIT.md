# Developer Toolkit

This repository keeps repeatable diagnostics in Dart so local development, CI, and AI-assisted coding can use the same commands.

## Policy

- Dart / Flutter SDK APIs are the default for repository tooling.
- Python is allowed only when the standard library or `python -m` materially simplifies an OS/network/test/packaging task that would otherwise be awkward in Dart.
- **Do not add `requirements.txt`.** Python tooling in this repository must not require pip-installed dependencies.
- Runtime Flutter dependencies must never be added merely to support developer diagnostics.
- Network probes and mocks are developer/test utilities; they are not shipped as application runtime features.
- Generated diagnostics live under `build/` and are git-ignored.

## Recommended one-command entrypoint

Use the dispatcher for normal work:

```bash
dart run tool/dev.dart check
dart run tool/dev.dart full
dart run tool/dev.dart bundle
dart run tool/dev.dart all
```

- `check`: dependency resolution, lockfile reproducibility, inspect, analyze, test.
- `full`: `check` plus both release web builds and size reporting.
- `bundle`: collect diagnostics and package them as a ZIP when a standard Python launcher is available.
- `all`: full validation followed by diagnostic bundle generation.

The dispatcher also exposes `inspect`, `versions`, `net`, and `mock`. Each underlying Dart script remains independently runnable for focused troubleshooting.

## Repository inspector

```bash
dart run tool/inspect.dart
```

Reports:

- Flutter / Dart / channel
- Git HEAD
- source size excluding `.git`, `.dart_tool`, and `build`
- Dart file counts
- terminal `pattern_NNN` directory count
- asset size
- GetX residual counts in `lib/` (reference catalogue intentionally included)
- direct locked dependency versions
- existing `build/web` size, when present

Machine-readable output:

```bash
dart run tool/inspect.dart --json
```

## Repeatable health check

```bash
dart run tool/check.dart
dart run tool/check.dart --full
```

The full mode includes both release web entrypoints and prints build sizes. Each step reports its duration and exit status.

## Latest stable direct dependencies

```bash
dart run tool/check_versions.dart
```

Uses `dart pub outdated --json` and parses the result in Dart. Packages omitted because they are already current are treated as non-stale.

## Network probe

```bash
dart run tool/net_probe.dart https://example.com
```

Shows DNS resolution, TCP connection details, TLS peer-certificate metadata for HTTPS, HTTP status/headers/body-byte count, redirects, and timings. DNS, TCP, TLS, HTTP response-header wait, and response-stream inactivity are bounded so a stalled peer does not leave the probe hanging indefinitely. The `HttpClient` and sockets are closed on both success and exception paths.

## Local HTTP mock/stub

```bash
dart run tool/mock_http_server.dart --port 8787
```

Built only with `dart:io`. Endpoints:

- `GET /health`
- `/status/<100..599>`
- `/delay/<0..30000>`
- `/echo`

Example:

```bash
dart run tool/dev.dart net http://127.0.0.1:8787/health
```

## Diagnostic bundle

```bash
dart run tool/dev.dart bundle
dart run tool/dev.dart bundle --output build/my-diagnostics.zip
```

The Dart orchestrator collects reusable diagnostics under `build/diagnostics/`, including inspector JSON, Flutter version and doctor output, dependency/outdated information, pub dependency graph, and Git status. It then uses only the Python standard-library `zipfile` module to create and verify the ZIP.

If Python is unavailable, the uncompressed `build/diagnostics/` directory is retained and the command reports that ZIP packaging was skipped. On Windows the standard `py -3` launcher is tried before `python3` and `python`.

**Review diagnostic files before sharing them outside your machine or organization.** They are not intended to contain application secrets, but `flutter doctor -v`, SDK metadata, Git status, and similar outputs may expose machine-local paths, device/toolchain details, repository state, or other environment-specific information.

## Python boundary

Python may still be used as an operating-system Swiss-army knife, for example:

```bash
python3 -m json.tool assets/ui_showcase.json
python3 -m http.server 8080
python3 -m zipfile -l build/diagnostics.zip
```

These commands require no repository Python package setup. If a proposed tool needs a `requirements.txt`, implement it in Dart first or make a separate explicit tooling decision instead of quietly introducing pip dependencies.
