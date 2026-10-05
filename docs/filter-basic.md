# Filtering examples: one Python producer, shared Flutter boundary

The #144 work in #145 implements FilterBasic (001), FilterMultiple (002) and
FilterNested (003) with the same stdlib-only CLI. Existing catalogue views load
Python-generated results: **generated examples, not arbitrary-input filtering
at Flutter runtime**. No new route, Screen 199/200 or dependency is added.

## Generate and verify

```sh
python -S tool/python/filter_basic.py --input tool/python/fixtures/filter_basic_input.json --output assets/data_processing/filter_basic.json --check
python -S tool/python/filter_basic.py --input tool/python/fixtures/filter_multiple_input.json --output assets/data_processing/filter_multiple.json --check
python -S tool/python/filter_basic.py --input tool/python/fixtures/filter_nested_input.json --output assets/data_processing/filter_nested.json --check
```

Remove `--check` to generate; omit `--output` for stdout; `--input -` reads stdin.
Exit **0** means success, **1** stale generated values, **2** invalid arguments,
input or I/O. Check mode never rewrites assets. Only consumed `values` are
compared, preserving JSON types but ignoring unrelated metadata and formatting.

## Processing contract

`values` is a list. Basic input uses required `equals` (any JSON value).
Multiple/nested input instead uses a nonempty `conditions` list:

```json
{"values":[{"profile":{"tags":["blue"]},"active":true}],"conditions":[{"path":["profile","tags",0],"equals":"blue"},{"path":["active"],"equals":true}],"match":"all"}
```

`match` is `all` (default) or `any`. Conditions contain required `equals` and
optional `path`; an omitted/empty path selects the whole value. Paths contain
literal object keys or non-negative integer list indices. `a.b` is a literal
key, not dot notation. Missing keys, out-of-range indices and incompatible
intermediate types do not match, even against null; explicit null can match.
Negative/fractional/boolean indices, unknown condition fields, empty conditions,
ambiguous equals+conditions and unknown match modes are rejected before
filtering, even for an empty input. No expression/code evaluation is supported.

Filtering retains order and duplicates using Python JSON-decoded equality
(including numeric/boolean equality); non-finite JSON constants are rejected.
Output is an object containing the selected original `values`.

## Dart responsibility and consolidation

Python owns filtering, validation, generation and drift checking. Shared
`JsonListAsset` only loads/validates JSON; no predicate or synthetic fallback.
The earlier duplicate Dart `list_filters.dart` was removed in this PR.

All three examples now share `ProcessedListExample` loading/result/error/retry
and disposal state. Their six duplicate model/controller files are deleted;
services are asset-path constructors, and views configure presentation.
No GetX binding, global registration or controller reset is needed. The old
internal `run()`/message-model interfaces are intentionally replaced by
`load()` values. Existing view names and const construction are preserved.
The shared Flutter suite replaces all three former per-pattern test files;
this does not claim the rest of the catalogue is consolidated or GetX-free.

## Failure evidence and verification

The real negative-path regression remains CLI invalid-input **exit 2** → native
pytest **exit 1** with/without JUnit → existing expected-failure wrapper **exit 0**
when the failure is expected → vendored xprobe. Native failure codes are kept;
wrapper success is not normalized native success. Raw JUnit/receipts stay in
the short-retention controlled artifact. Producer fingerprints exclude encounter
order/run ID/commit/raw payloads and include repository context; corpus IDs
retain canonical checkout/report scope.

The unchanged shared collector still needs downstream context/stable-identity
propagation (earlier measured null commit context and ordinal IDs). Unused
`.junit-tools` workflow checkouts also remain cleanup work. These gaps are not
claimed fixed and do not require another tooling bootstrap.

Existing pytest collects `test_filter_basic.py`, `test_filter_conditions.py`
and native `test_junit_evidence.py`. All three examples use the shared Flutter
`filter_conditions_test.dart` in the existing pattern-shard directory, checking
real assets, malformed/missing data, loading, duplicate-load prevention,
errors/retry, empty results and completion after disposal without GetX.

The repository-local CI audit is authoritative. Starting **790/792,
undecodable 0** became **787/792** for 001–003. Removing 001's GetX scaffold
changes the runtime file count, not that already-reduced placeholder count.
Record current-head results in #144; older-head green is not current evidence.
