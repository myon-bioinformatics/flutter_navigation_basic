# Opt-in local Python curl import in the real Flutter web editor

This increment connects `HttpRequestDraftPage` to `curl_request.py` **at runtime**,
not to a generated result asset. It is an explicitly selected development/CI
configuration; the normal static Pages build continues to use the legacy Dart
parser. The selected Python path has **no automatic Dart fallback**.

## Build Python versus application Python

`actions/setup-python` installs Python on a CI runner. It does not put an
interpreter in Flutter JavaScript, an Android APK, or an iOS application. Existing
Python oracles and fixture generation are build/test-side use only.

This adapter uses a Python process on the same computer that serves the web build.
It requires no public endpoint, account, paid service, extra Python package, curl
execution, request proxy, or Python interpreter downloaded by a page. Browser-side
Wasm Python and native app interpreter packaging remain distinct follow-ups.

```sh
flutter pub get
flutter build web --release -t lib/main.dart --base-href / --dart-define=CURL_PYTHON_RUNTIME=true
python -S tool/python/curl_runtime_server.py --web-root build/web --port 8080
# Open http://127.0.0.1:8080/#/tools/http/request-draft (not localhost).
```

The two Python modules must be kept together. This is a local development server,
not production hosting. Do not publish or tunnel it. All other runtime modes stay
unchanged. In particular, phones opening a hosted Pages URL do not acquire Python
merely because a CI runner installed it.

## Responsibilities and failure behavior

The existing Python parser owns curl tokenization, safe-subset recognition,
query/form decoding and Basic-header generation. `curl_import.dart` maps the reply
into existing editor rows (including new row IDs and empty rows) and keeps later
`RequestDraftValidator` warnings. The web transport is a small `dart:js_interop`
XHR boundary. Native builds compile a stub, not a browser import.

The current import-stage parser returns diagnostic codes without argument text;
full error-message argument parity and the remaining Dart validator/export/auth
semantics are not represented as migrated. The normal parser is deliberately
retained until all deployment targets have an appropriate measured runtime.

On an opted-in build, click Import: raw curl text goes to the fixed same-origin
`/__runtime__/curl-import` endpoint. The Dart transport refuses non-HTTP/non-127.0.0.1
origins. The server binds 127.0.0.1 and enforces the exact Host and Origin, a custom
request header, content type and a single bounded Content-Length; it provides no
CORS opt-in. It never dereferences @file or sends the parsed HTTP request.

Input is capped at 65,536 bytes; response at 1 MiB; server read and browser XHR
timeouts are 5 seconds. Request concurrency is bounded to eight handlers. Static
files are confined to the selected build root, without directory listings or
symlink escapes. Parsed values may contain credentials: no body/access logging,
no shared-corpus upload and no persistent storage. Browser test inputs are synthetic.

Unavailable runtime, timeout and malformed reply leave the draft unchanged and
show an error. Duplicate import is disabled while loading; edits, Clear and preset
changes invalidate late replies. Completion after widget disposal does not setState.

## Evidence

- `test_curl_runtime_server.py` exercises the actual loopback server, including
  origin/framing/size/UTF-8 guards, partial-body timeout/EOF, no credential logging
  and restricted static serving. It is collected by existing Python CI.
- `curl_python_runtime_test.dart` reuses the prior 47-case contract fixture for
  editor projection and adds invalid-reply, unavailable and timeout cases.
- Widget tests inject an async importer for duplicate-load, stale-edit and disposal.
- `curl-runtime.yml` installs Python on the runner, builds Flutter with explicit
  runtime activation, starts the real parser server and drives the real page via
  existing Playwright/helper code. It tests real replies, refusals, outage/retry,
  timeout, malformed responses and late replies on Chromium/Firefox/WebKit plus
  mobile emulations. This is not physical-device or installed-mobile-runtime proof.
- Browser artifacts contain screenshots, traces, JUnit, a compact receipt and the
  existing `yourself.py --minimal` environment observation. Screenshots are review
  evidence, **not yet checked-in pixel-golden comparisons**. No automatic baseline
  acceptance hides a UI change. No Stagehand/model key is required by this lane.

An implementation or previously green head does not establish success on a new
head: record the new workflow's actual completion separately. No existing curl
Dart file is removed in this increment, and the catalogue stub count is unchanged.
