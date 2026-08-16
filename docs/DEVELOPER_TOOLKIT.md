# Developer Toolkit

This repository keeps repeatable diagnostics in Dart so local development, CI, and AI-assisted coding can use the same commands.

## Policy

- Dart / Flutter SDK APIs are the default for repository tooling.
- Python is allowed only when the standard library or `python -m` materially simplifies an OS/network/test task that would otherwise be awkward in Dart.
- **Do not add `requirements.txt`.** Python tooling in this repository must not require pip-installed dependencies.
- Runtime Flutter dependencies must never be added merely to support developer diagnostics.
- Network probes and mocks are developer/test utilities; they are not shipped as application runtime features.

## Commands

### Repository inspector

```bash
dart run tool/inspect.dart
```

Reports:

- Flutter / Dart / channel
- Git HEAD
- source size excluding `.git`, `.dart_tool`, and `build`
- Dart file counts
- pattern-directory count
- asset size
- GetX residual counts in `lib/` (reference catalogue intentionally included)
- direct locked dependency versions
- existing `build/web` size, when present

Machine-readable output:

```bash
dart run tool/inspect.dart --json
```

### Repeatable health check

Quick development check:

```bash
dart run tool/check.dart
```

Runs dependency resolution, lockfile reproducibility check, repository inspection, analyzer, and tests while printing per-step durations.

Full check including both release web builds and their sizes:

```bash
dart run tool/check.dart --full
```

### Latest stable direct dependencies

```bash
dart run tool/check_versions.dart
```

Uses `dart pub outdated --json` and parses the result in Dart. This replaces ad-hoc Python JSON parsing in CI.

### Network probe

```bash
dart run tool/net_probe.dart https://example.com
```

Shows DNS resolution, TCP connection details, TLS peer-certificate metadata for HTTPS, HTTP status/headers/body-byte count, redirects, and timings. It is intentionally a developer-oriented probe rather than a production HTTP client.

### Local HTTP mock/stub

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
dart run tool/net_probe.dart http://127.0.0.1:8787/health
```

## Python boundary

Python may still be used as an operating-system Swiss-army knife, for example:

```bash
python3 -m json.tool assets/ui_showcase.json
python3 -m http.server 8080
```

Those commands require no repository Python package setup. If a proposed tool needs a `requirements.txt`, implement it in Dart first or justify a separate tooling decision instead of quietly introducing pip dependencies.
