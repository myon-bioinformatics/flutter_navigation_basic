# List-selection examples: one Python producer, shared Flutter boundary

Issue #144 / PR #145 implements FilterBasic (001), FilterMultiple (002),
FilterNested (003), DistinctFilter (030) and Deduplication (086). The
responsibility-named stdlib-only `list_selection.py` command shares validation,
JSON I/O, asset generation and drift checking. No per-pattern Python copy.
Flutter currently displays **generated catalogue examples, not arbitrary-input
runtime filtering/deduplication**. The Python CLI itself is repository-independent
and can be invoked from an isolated runtime location; wiring/packaging that runtime
into Flutter targets is a separate measured step, not claimed by this slice.
No new route, Screen 199/200 or dependency is added.

## Generate and verify

```sh
python -S tool/python/list_selection.py --input tool/python/fixtures/filter_basic_input.json --output assets/data_processing/filter_basic.json --check
python -S tool/python/list_selection.py --input tool/python/fixtures/filter_multiple_input.json --output assets/data_processing/filter_multiple.json --check
python -S tool/python/list_selection.py --input tool/python/fixtures/filter_nested_input.json --output assets/data_processing/filter_nested.json --check
python -S tool/python/list_selection.py --input tool/python/fixtures/distinct_filter_input.json --output assets/data_processing/distinct_filter.json --check
```

Remove `--check` to generate; omit `--output` for stdout; `--input -` reads stdin.
Exit **0** means success, **1** stale generated values, **2** invalid arguments,
input or I/O. Checks never rewrite assets and compare only consumed `values`,
preserving JSON types while ignoring unrelated metadata/formatting.

## Processing contracts

`values` is a list. The default `operation` is `filter`, preserving existing
inputs. Basic filtering uses required `equals` (any JSON value). Multiple/nested
filtering instead uses a nonempty `conditions` list, with `match` set to `all`
(default) or `any`. Each condition accepts required `equals` and optional `path`.
An omitted/empty path selects the whole value. Paths contain literal object keys
or non-negative integer list indices; `a.b` is a literal key, not dot notation.
Missing keys, out-of-range indices and incompatible intermediate types do not
match, even against null; explicit null can match. Invalid/ambiguous conditions
are rejected before filtering, even for empty input. No expression evaluation.
Filtering preserves order/duplicates using Python JSON-decoded equality,
including its numeric/boolean equality.

`{"operation":"distinct","values":[...]}` keeps each first occurrence by its
canonical JSON representation (`sort_keys=True`, compact separators). Object
key order is ignored; array order, boolean/integer/float encodings and signed
floating-point zero remain distinct. The selected original values are returned,
not reconstructed values. Distinct mode accepts only `operation` and `values`;
filter conditions, key selectors and unknown options are rejected, not ignored.
This in-memory operation retains full canonical keys; it is not a streaming or
constant-memory implementation.

Patterns 030 and 086 deliberately reuse this same processor and the same
`distinct_filter.json` catalogue result because their documented responsibility
is the same stable deduplication operation. No second Python file or duplicate
asset is created for 086. Pattern 113 is **not** folded into this contract yet:
its catalogue description says “deduplication validation”, so its validation and
reporting semantics must be defined before reuse is claimed.

Both modes reject non-finite constants and numbers that overflow while decoding
(e.g. `1e999`), even if no value would be selected. Before this fix the latter
could incorrectly exit 0 with empty output; regression tests retain that case.

## Dart responsibility and consolidation

Python owns processing/validation/generation/drift checking. `JsonListAsset`
only loads/validates the result shape. `ProcessedListExample` shares local
loading/result/error/retry/disposal state across 001/002/003/030/086.
Ten duplicate model/controller files are removed. Services select assets;
views configure presentation, with no GetX registration or global reset.
The old internal `run()`/message-model contract is replaced by `load()` values;
view names and const construction remain. One shared Flutter suite replaces
five former per-pattern test files. Other catalogue scaffolds are not claimed
GetX-free. The earlier duplicate Dart `list_filters.dart` remains removed.

## Failure evidence and verification

The existing intentional-red chain exercises the reproduced numeric overflow:
actual CLI **exit 2** → native pytest **exit 1** with/without JUnit → existing
`expected_child_failure.py` wrapper **exit 0** for a matched expected failure →
vendored xprobe. Ordinary invalid-type CLI tests remain covered separately.
No new failure bootstrap or second heavy native run is added for 086 because it
reuses the already-tested distinct processor rather than introducing a new one.
Raw JUnit/receipts stay in short-retention controlled artifacts. Producer cases
have repository/canonical checkout context and run-order-independent fingerprints;
raw messages/stdout/parameter sentinels do not enter the compact corpus.
The unchanged shared downstream collector still needs context/fingerprint
propagation, and unused `.junit-tools` checkouts remain cleanup work.

Existing pytest collects basic/conditions/distinct tests and the native chain.
The shared `filter_conditions_test.dart` remains in the existing pattern-shard
path and covers real assets, unmodified result consumption, malformed/missing
data, loading/duplicate-load prevention, errors/retry/empty results and disposal.
The CLI is also covered by isolated `python -I -S` source-copy tests: the single
file runs without repository, Flutter, site packages or generated assets for
filter/distinct success and invalid-input exit 2. This demonstrates a portable
stdlib processing boundary, not that every Flutter target already bundles Python.
No local Flutter SDK or full checkout is available; local focused source copies
are not full CI/audit evidence.

The authoritative audit starts at **790/792, undecodable 0**. 001–003 reduce it
to **787/792** and 030 to **786/792**; their GetX consolidation changes file
counts separately from placeholder counts. The 086 reuse slice should reduce the
PR value to **785/792** while leaving the service denominator unchanged. Record
the measured current-head result from CI in #144 before calling that value
verified; merged main remains a separate baseline until this PR is integrated.
