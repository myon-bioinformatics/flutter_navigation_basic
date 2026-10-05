# FilterBasic: Python producer and Flutter asset boundary

This #144 slice implements the FilterBasic CLI for supplied JSON inputs and
connects one generated example to the existing Pattern 001 catalogue view.
It does **not** claim that arbitrary input is filtered at Flutter runtime, or
that a new Screen 199/200 or new application route has been added.

## Producer and consumer

```sh
python -S tool/python/filter_basic.py --input tool/python/fixtures/filter_basic_input.json --output assets/data_processing/filter_basic.json
python -S tool/python/filter_basic.py --input tool/python/fixtures/filter_basic_input.json --output assets/data_processing/filter_basic.json --check
```

The input is an object with `values` (list) and required `equals` (any JSON value).
Filtering retains input order and duplicates using Python JSON-decoded equality
(including Python's numeric/boolean equality); non-finite JSON is rejected.
Stdout, or `--output`, is an object with the resulting `values`. Exit 0 means
success, 1 means stale generated values in check mode, and 2 means invalid
arguments/input or I/O failure. Check mode does not rewrite the asset and checks
only the consumed `values` contract, not unrelated metadata or formatting.

Python owns filtering, input validation and asset generation. The shared
`JsonListAsset` owns Flutter asset loading/JSON boundary validation only.
`Pattern001Service` formats the loaded values, and the existing controller/view
show loading, result, failure and retry. The duplicate Dart `list_filters.dart`
introduced earlier in #145 is removed. Existing per-pattern model/controller
public shapes remain for catalogue compatibility; this slice does not claim
that all generated file duplication has been consolidated.

## Failure evidence

The existing oracle-wrapper regression now invokes the actual FilterBasic CLI
with invalid input (native exit 2), deliberately asserts that it succeeded, and
retains native pytest exit 1 both with and without JUnit. The JUnit-enabled path
runs under the existing `expected_child_failure.py`: its outer exit 0 indicates
that native exit 1 was expected, not that the native test passed. Raw native
receipts/output/JUnit remain in the existing short-retention controlled artifact.

`failure_identity.py` imports the repository's vendored xprobe and uses canonical
`record_from_checkout()` identity for compact cases. Fingerprints include only a
schema, repository and xprobe-redacted class/test/kind; they exclude encounter
order, run/report ID, commit and raw payloads. Corpus IDs remain scoped to the
canonical checkout SHA/report to avoid cross-commit ID conflicts. The captured
JUnit is reordered without rerunning the native command to verify stable IDs.
The producer's compact corpus never includes traceback/messages/parameter labels.

The old test-only `.junit-tools` checkout is no longer consumed by this test.
Its redundant workflow checkout step remains a cleanup candidate; the shared
JUnit collector is unchanged and its output is not claimed to use the producer's
new fingerprint field. This distinction must stay visible in #144 until that
integration has been evaluated/changed in the appropriate scope.

## Verification boundary

`test_filter_basic.py` checks CLI exits, generated-asset drift, Unicode/null,
file I/O and enrolment. `test_junit_evidence.py` exercises the native chain and
redaction. Both are collected through the existing `tool/python/pytest.ini`.
Pattern 001's Flutter test is under the existing
`test/features/data_processing_patterns` pattern-shard path; it loads the real
asset and checks malformed/missing assets plus UI loading/error/retry.
Asset-only changes select the existing Flutter workflow, whose Python-oracle
lane runs the drift check. No new CI bootstrap or package dependency is needed.

The real repository stub audit is authoritative: before #145, 790/792 with 0
undecodable files; expected after, 789/792 (one service). Count reduction alone
is not proof of end-to-end behavior. Local focused tests do not replace the
current-head CI, Flutter evidence or full-checkout audit.
