# Developer Toolkit

This repository keeps repeatable diagnostics in Dart so local development, CI, and AI-assisted coding can use the same commands.

## Policy

- Dart / Flutter SDK APIs are the default for repository tooling and app runtime.
- Prefer **stdlib-first** scripts for non-compiled helpers: Python stdlib, Dart
  toolkit, and optional Deno one-file CLIs when that fits better than pip/npm.
- Python stdlib / `python -m` remain preferred for simple OS/network/packaging/Actions tasks.
- **Pip dependencies are allowlisted only at `tool/python/requirements.txt`** for
  dev/test tooling (**pytest only**; no pydantic). Root-level or app-tree
  `requirements.txt` files remain prohibited. App formula assertions stay in
  Dart; Python may keep stdlib structural checks on shared JSON fixtures.
- Runtime Flutter dependencies must never be added merely to support developer diagnostics.
- Network probes and mocks are developer/test utilities; they are not shipped as application runtime features.
- Generated diagnostics live under `build/` and are git-ignored.

See `tool/python/README.md` for pytest setup, `--actions-latest`, and stdlib one-liners.

```bash
python3 tool/python/test.py --actions-latest --json
dart run tool/dev.dart py --actions-latest
python3 -m json.tool tool/python/fixtures/coordinate_area_cases.json | head
python3 tool/python/build_artifact_report.py --root build/web --output build/diagnostics/web-build.json
python3 tool/python/build_artifact_report.py --compare before.json after.json
```

`build_artifact_report.py` is a stdlib-only, report-only size summary (counts,
categories, largest files, gzip estimate, before/after delta). It does not
replace `tool/build_meta.dart` / `tool/inspect.dart` and does not enforce
budgets or require dual CI builds.


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

Built with `dart:io` plus the verified `crypto` package for Digest/HMAC
fixtures. Endpoints:

- `GET /health`
- `/status/<100..599>`
- `/delay/<0..30000>`
- `/echo`
- Auth scenario stubs (demo credentials only — never real secrets):
  - `GET /auth/bearer` — Bearer token (`demo-bearer-token`); also covers
    missing/malformed/expired (`demo-expired-token`) / wrong-audience
    (`demo-wrong-aud-token` → 403)
  - `GET /auth/api-key` — `X-API-Key` header or `api_key` query (`demo-api-key`)
  - `GET /auth/basic` — HTTP Basic (`demo` / `s3cret`)
  - `GET /auth/digest` — Digest challenge/response (same demo user/password);
    requires `qop=auth` + `nc` + `cnonce`, binds `uri=` to the real
    request-target (path + query), requires challenge `opaque`, and accepts
    only `algorithm=MD5`
  - `GET /auth/hmac` — HMAC-SHA256 over `METHOD\npath\ntimestamp\nnonce`
    with `X-Key-Id` / `X-Timestamp` / `X-Nonce` / `X-Signature`
    (`demo-key` / `demo-hmac-secret`); rejects skew and nonce replay
  - `GET /auth/rate-limited` — always `429` with `Retry-After: 1`
- MCP Streamable HTTP foundation stubs (pinned spec `2025-03-26`):
  - `POST /mcp` — JSON-RPC `initialize` / `tools/*` / `resources/*` /
    `prompts/*` / `ping` / `notifications/initialized`
  - After `initialize`, every subsequent POST (including
    `notifications/initialized`) must send the issued `Mcp-Session-Id`
    (missing → HTTP 400, unknown → HTTP 404). Session ids are
    `Random.secure()` base64url.
  - Present `Origin` must match the local allowlist
    (`http://127.0.0.1:8787` / `http://localhost:8787`); disallowed → HTTP
    403. Absent Origin remains OK for CLI/curl.
  - Unsupported client `protocolVersion` still yields a successful
    InitializeResult with the pinned `2025-03-26` (client may disconnect).
  - `GET /.well-known/oauth-authorization-server` — AS metadata fixture
    (+ PKCE S256). Remote discovery parsing does not invent omitted claims.
  - `GET /.well-known/oauth-protected-resource` — protected resource metadata
  - `GET /mcp/support-matrix` — capability flags (Flutter Web in-app OAuth
    is **not** guaranteed)

Example:

```bash
dart run tool/dev.dart net http://127.0.0.1:8787/health
curl -s -H 'Authorization: Bearer demo-bearer-token' \
  http://127.0.0.1:8787/auth/bearer
SESSION=$(curl -s -D - -o /tmp/mcp-init.json -X POST http://127.0.0.1:8787/mcp \
  -H 'content-type: application/json' \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","clientInfo":{"name":"demo","version":"0"}}}' \
  | awk -F': ' 'tolower($1)=="mcp-session-id"{gsub(/\r/,"",$2); print $2; exit}')
curl -s -X POST http://127.0.0.1:8787/mcp \
  -H 'content-type: application/json' \
  -H "mcp-session-id: $SESSION" \
  -d '{"jsonrpc":"2.0","method":"notifications/initialized"}'
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
