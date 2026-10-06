# Python curl import: shared Docker toolchain and real Flutter Web E2E

`HttpRequestDraftPage` sends entered curl text to `curl_request.py` at runtime,
not to a generated example. The Python path never silently falls back to Dart.
The existing static Pages/native configuration remains separate until its runtime
packaging is measured; this migration does not remove working offline behavior.

## Canonical build/test container

`Dockerfile.e2e` now owns the shared Flutter/Python/Node/npm/npx/Deno environment.
It uses Ubuntu 24.04's Python 3.12, pinned Flutter 3.47.0, Node 22, and the official
Deno 2.9.6 binary image. npm/npx ship with Node; TypeScript execution is proved by
an offline, permission-free Deno smoke. Playwright's three browser engines are
installed once and reused by the five desktop/mobile-emulation projects.

The existing npm range policy is retained (not falsely described as a fully
byte-reproducible image). CI records the resolved tool versions and image ID.
Dependency/browser layers are cached independently of application source and the
late `CURL_PYTHON_RUNTIME` build argument. The checked-in Flutter lock must match
`flutter pub get`; a changed lock is not silently accepted inside the image.

```sh
docker build -f Dockerfile.e2e --build-arg CURL_PYTHON_RUNTIME=true -t flutter-nav-curl-runtime .
mkdir -p e2e/test-results build/curl-runtime
docker run --rm --init --ipc=host \
  -e PLAYWRIGHT_JUNIT_OUTPUT_FILE=test-results/curl-runtime.xml \
  -v "$PWD/e2e/test-results:/repo/e2e/test-results" \
  -v "$PWD/build/curl-runtime:/repo/build/curl-runtime" \
  flutter-nav-curl-runtime \
  test --project chromium --project firefox --project webkit \
  --project mobile-chromium --project mobile-webkit \
  tests/curl_runtime.spec.ts --reporter=line,junit
```

The server and browsers run **inside the same image** and communicate over its
127.0.0.1. No published port or host Docker socket is required. Do not expose or
tunnel this development server. The shared entrypoint preserves the native test
exit code, bounds runtime tests to 15 minutes, and stops the child server on exit.
Its required tool checks fail closed; missing Deno/Node/Python is not a pass.
Without the build argument, the existing static Docker E2E entrypoint and default
portable test list remain supported. Do not enable the runtime environment flag
on an image that was built as a static application.

This packages Python and the parser **with the tested Web build in the image**.
It does not imply CPython is inside the browser JavaScript or an Android/iOS app.
Native interpreter packaging and browser Wasm remain possible separate targets,
not an excuse to retain Dart logic in this tested runtime path. This user-approved
runtime slice supersedes older developer-tool-only Python wording in the general
ownership rubric. Node/npx/Deno are build/test capabilities here, not new browser
or mobile dependencies.

## Non-container development

```sh
flutter pub get
flutter build web --release -t lib/main.dart --base-href / --dart-define=CURL_PYTHON_RUNTIME=true
python -S tool/python/curl_runtime_server.py --web-root build/web --port 8080
# Open http://127.0.0.1:8080/#/tools/http/request-draft (not localhost).
```

The Python parser and server modules stay together. This uses no paid service,
account, public endpoint, extra Python package, curl execution or request proxy.

## Responsibilities and failure behavior

Python owns curl tokenization, safe-subset recognition, query/form decoding and
Basic-header generation. Dart maps replies into editor rows/IDs and displays
loading, errors and retry. The selected web transport is a small js_interop XHR
boundary; native builds compile a transport stub, not a browser import.
Diagnostic codes omit raw argument text. Full diagnostic-argument parity and
remaining validator/export/auth logic are not represented as migrated.

The endpoint is fixed to same-origin `/__runtime__/curl-import`. The transport
rejects non-HTTP/non-127.0.0.1 origins. The server binds loopback and enforces exact
Host/Origin, a custom header, content type and a single bounded Content-Length.
No CORS opt-in, @file dereferencing or outbound HTTP request is provided.
Input: 65,536 bytes; response: 1 MiB; server/XHR timeouts: 5 seconds; concurrency:
eight handlers. Static serving prevents directory listings and symlink escapes.
Values may contain credentials: no access/body logs or shared-corpus payloads.
All browser fixtures are synthetic.

Unavailable/slow/malformed replies leave the draft unchanged and display an
error. Duplicate import is disabled while loading. Edits, Clear and preset changes
invalidate late results. Disposed widgets never receive a late setState.

## Evidence and migration gate

- Existing Python tests cover real loopback requests and security/error bounds.
- Dart projection tests consume the 47-case contract fixture; widget tests cover
  async loading, invalidation and disposal.
- `curl-runtime.yml` builds this Dockerfile, then runs the actual editor and
  Python process in the same container, using the existing Python Playwright CLI.
- The browser suite covers success, rejected input, outage/retry, timeout,
  malformed reply and editing during a delayed real reply in five projects.
  It observes emitted semantics **text**, not an assumed parent `aria-label`;
  disabled state belongs to the nested button. These boundaries were checked
  against the preceding failed run's retained DOM traces.
- CI verifies that at least 30 cases actually ran without skips/failures/errors,
  that traces are retained, and that success screenshots exist in all projects.
  It reuses vendored `check_png.py` rather than introducing another PNG validator.
- Artifacts retain screenshots, traces, JUnit, synthetic receipts, `yourself.py`
  minimal environment data, fixed-command tool versions, image ID and the real
  CI checkout SHA (which can be a PR merge SHA rather than PR head).

Screenshots are review snapshots, not automatically accepted pixel goldens.
Mobile profiles are browser emulations, not installed Android/iOS proof.
A new implementation is not a green run: report actual Docker E2E completion
before advancing the removal of the legacy Dart parser. Static/legacy modes are
kept distinct, and this container/evidence slice does not change stub counts.
