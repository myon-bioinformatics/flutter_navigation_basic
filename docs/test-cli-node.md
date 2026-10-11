# Python / Node test CLI (first slice)

This is a local, stdlib-only orchestration layer, not a replacement for the
language-native test runners or the existing failure-identity JUnit collector.

```sh
python3 tool/python/test.py --pytest
python3 tool/python/test.py --node
python3 tool/python/test.py --python            # explicit Python-only (alias --pytest/--py)
python3 tool/python/test.py --python -x         # pytest stops at first failure
python3 tool/python/test.py --python --node    # both runners, nonzero if either fails
python3 tool/python/test.py --print-message "from: agent; test complete"
python3 tool/python/test.py --node --node-name-pattern 'request'
python3 tool/python/test.py --node --node-test-file tool/javascript/tests/example.test.mjs
python3 tool/python/test.py --node --node-receipt build/test-results/node-summary.json
```

- Python remains `pytest`; Node remains `node --test`. The wrapper uses
  `subprocess.run` with an argv array, **not** a shell.
- Node emits native JUnit to `build/test-results/node.xml`, plus its normal
  human-readable reporter to stdout. An optional JSON receipt summarizes
  passed/failed/skipped and failure messages (max 2000 chars each).
- A nonzero Node exit, missing/malformed/empty JUnit, timeout or missing Node
  fails closed. Stale JUnit is removed before execution. The underlying Node
  test error is still printed; the wrapper does not mask it.
- Refactor smoke uses the wrapper for the existing JavaScript async-boundary
  suite; the canonical collector still consumes the unchanged native JUnit.
- `--node-name-pattern` is Node's regex filter, not pytest `-k`.
  This initial slice does **not** promise automatic rerun of individual failed
  tests from JUnit: Node's JUnit names do not necessarily identify a unique
  source file, and a blind rerun could execute the wrong test. A later extension
  should capture source IDs, detect collisions, and retain the original failure
  as evidence even when a rerun succeeds.
- Deno, Playwright (Node/Python), browser click/fetch/lifecycle and Flutter Web
  integration are **future adapters**. Passing Flutter Web E2E is useful
  cross-platform evidence, not proof of Android/iOS native behavior.

## Runner selection and printing

No runner flags retains the historical **pytest-only** default (avoids breaking
Python-only environments). `--node` selects Node only; `--python`, `--py`, or
`--pytest` selects Python only; specify both for both. `-x`/`--exitfirst`
is pytest's stop-on-first-failure flag and is rejected when only Node runs.
Combined runs preserve failure exit status even if the other runner succeeds.

`--print-message TEXT` prints literal user/agent-supplied text. Repeating it
prints multiple messages; by itself it runs no tests. It deliberately does
**not** interpret Python expressions, execute `python -c`, or inject text into
shell commands. Use `python3 -c` separately for deliberate scripting; the
common test CLI remains an execution-safe test orchestrator.
