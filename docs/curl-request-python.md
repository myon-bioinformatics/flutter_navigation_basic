# Curl import: portable Python parsing and a shared compatibility contract

Issue #144 / PR #145 adds `tool/python/curl_request.py` as the first HTTP parsing
migration slice. It uses only the Python standard library, and handles arbitrary
input rather than returning a canned catalogue example. It **does not execute
curl, shell commands or network requests**.

```sh
printf '%s' "curl -G -d 'q=cat&a=1&a=2' https://example.com/" |
  python -I -S tool/python/curl_request.py
python -I -S tool/python/curl_request.py --input request.txt
```

The CLI returns JSON with `ok`, `draft`, `errors` and `warnings`. Exit **0** is a
successful import; exit **2** is rejected input, invalid arguments or a read
failure. Its argv surface reuses the vendored stdlib-only `cli_args.py`;
unknown options, extra positional arguments and missing option values return
`httpDraft.curl.error.arguments` as JSON with empty stderr rather than exposing
argparse usage or caller values. Read failures omit file paths. Parser diagnostics contain stable codes,
not raw option values. Parsed fields, however, can include passwords/tokens:
returning a sensitive field is not redaction. Do not publish arbitrary parser
output as CI logs or shared failure corpus entries. Tests use synthetic examples.

## Import stage

The supported subset follows `CurlSafeSubset.tryParse`: method/URL, repeated
headers, literal data, URL-encoded form/query fields, Basic Authorization,
user-agent/referer and GET/HEAD selection. Ordering and duplicate fields are
preserved. Long value-taking options support `--flag=value`, including empty
values. Display-only flags produce warnings; unsupported options and `@file`
body forms are rejected. Quoted metacharacters are literal data, never expansion.

The small lexer retains the editor's quote/backslash and fullwidth-ASCII
normalization behavior. Blindly substituting `shlex.split` would consume
unquoted backslashes that the editor preserves. Query/form decoding reuses
`urllib.parse.parse_qsl` with strict UTF-8 and percent-escape checking.

Input is limited to **65,536 UTF-8 bytes**, read with one extra byte to detect
oversize input; token count is limited to **4,096**. NUL, malformed percent escapes
and malformed UTF-8 are rejected with structured diagnostics. These extra boundary
checks are Python-specific and do not imply the existing Dart parser has them.

The result excludes UI row IDs and empty editor rows. It is an import projection,
not the full `RequestDraft` contract: URL validation, duplicate-header warnings,
JSON-body validation, redaction/export, authentication signing and transport are
not moved in this slice. Existing mixed-data/GET semantics are preserved; this
is compatibility with the repository's safe subset, not full command-line curl.

## Tests and current runtime boundary

`tool/python/fixtures/curl_request_cases.json` contains independently specified
input/result pairs, not expectations regenerated from the new parser. Python
checks every case through both the function and isolated `-I -S` CLI. The new
`test/shared/http/curl_request_contract_test.dart` projects the existing Dart
parser onto those same cases. It is under the already-enrolled `test/shared`
core path. The fixture is under `tool/python/fixtures`, covered by the existing
Python/Flutter CI path rules; no new workflow or dependency is needed.

The Python tests also cover bounded input, invalid encoding, file input from an
isolated directory, secret-free error codes and non-execution of commands/files.
Run them with:

```sh
python -m pytest tool/python/tests/test_curl_request.py --junitxml=curl-tests.xml
flutter test test/shared/http/curl_request_contract_test.dart
```

The opted-in Web build now uses the measured Flutter-to-Python runtime bridge
(`CURL_PYTHON_RUNTIME=true`) and does **not** silently fall back to the legacy
Dart parser. Docker browser E2E covers successful application, rejection,
runtime outage/retry, timeout/duplicate submission, malformed replies and edits
during delayed replies. Default static/native builds still retain the legacy
parser until their runtime/packaging boundary is replaced and measured. This
slice does not reduce the generated pattern-stub count.
