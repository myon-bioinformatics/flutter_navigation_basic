# Multi-runner JUnit, retry and failure-pattern history

This is an **independent test-tooling slice**, not part of the Python runtime
packaging or Worker196 implementation.

Python stdlib coordinates existing native test tools. Node, Deno and Playwright
remain responsible for executing JavaScript, TypeScript, browser interactions,
timers, fetch, clicks and their asynchronous lifecycles.

```sh
# Existing native Node suite, with a single bounded retry of the same files
python3 tool/python/test.py --node --retry-failed

# Deno: explicit selected file; Deno must be installed
python3 tool/python/test.py --external-runner deno \
  --test-file tool/javascript/tests/example.test.mjs --retry-failed

# Playwright Node: requires e2e dependencies and browser installation
python3 tool/python/test.py --external-runner playwright-node \
  --test-file e2e/tests/example.spec.ts --retry-failed

# Playwright Python: requires pytest + pytest-playwright and installed browsers
python3 tool/python/test.py --external-runner playwright-python \
  --test-file path/to/test_browser.py --retry-failed
```

These paths are examples, not a claim those particular files exist.

The external adapter requires explicit, existing test files **inside the repo**;
Node Playwright files must live under `e2e/`. No shell, arbitrary commands or
network install is invoked by the wrapper. Missing tools, missing/invalid JUnit,
zero executed tests, subprocess failure and timeouts fail closed.

The `--retry-failed` option performs **at most one rerun of the exact selected
file scope**, NOT an inferred individual testcase rerun. JUnit testcase names
are not reliable cross-runner source IDs. Retrying one selected file may rerun
passing tests in that file. An initial failure is never turned into exit 0,
even if the retry succeeds. The retry JUnit is written separately with a
`.retry.xml` suffix. The JSON history contains both attempts and a
`flaky_recovered` indicator.

The `test-attempts/1` receipt records runner, selected files, counts,
exit codes and a SHA-256 fingerprint of each failure message. Raw failure
messages are **not** stored in the history, but native JUnit, stdout and stderr
can contain sensitive content. Keep raw artifacts access-controlled.

This PR's CI exercises adapter command contracts, fake JUnit failures and a
real Node flaky retry. It does not claim installed Deno or browser E2E execution
until the required toolchain and browser dependencies are present in the CI lane.
Future work may use stable source IDs for narrower per-test reruns, but must
reject ambiguous IDs rather than silently running a different test.
