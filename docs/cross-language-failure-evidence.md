# Cross-language failure evidence

The repository uses **pytest as the orchestration boundary**, not as a reason to
rewrite every test in Python. Native runners remain authoritative for their own
languages and platforms.

```text
Flutter / Dart ─┐
Playwright / TS ├─ native child process ─ exit status ─┐
Go / other CLI ─┘                 └─ JUnit XML (when available)
                                                       ↓
                                              pytest orchestration
                                                       ↓
                                         xprobe.cases_from_junit()
                                                       ↓
                                       compact failure identity/evidence
```

## Contract

1. A wrapper must preserve the native child exit status. Producing or parsing
   JUnit must never turn a failing child green.
2. When a native runner can emit JUnit, retain that report as the exchange
   format and import failure/error identity with the vendored `xprobe.py`.
3. Raw traceback, stdout/stderr, assertion messages and parameter values are
   diagnostic artifacts; compact shared identity must keep xprobe's redaction
   boundary rather than copying those values into the corpus.
4. A runner that cannot emit JUnit may start with bounded exit-code evidence.
   Add a JUnit adapter only when it provides useful cross-runner identity.
5. pytest may launch Flutter, Playwright, Go or other fixed/allowlisted child
   commands, but it does not replace their native test semantics.
6. Reports and child failures must remain observable even when an earlier
   evidence step fails; CI should prefer `if: always()` for evidence collection
   where that does not mask the producer result.

## Current state

Python already proves this contract with a controlled failing child in
`tool/python/tests/test_junit_evidence.py`: the same child is run with and
without JUnit, both return code 1, and xprobe imports only compact failure/error
identity.

The shared reusable JUnit identity workflow consumes the retained JUnit
artifacts after the producer job. Later #144→#200 implementation PRs should
reuse this path for native runners where practical instead of adding
language-specific failure collectors.

This document does not claim that Flutter, Playwright or Go are all JUnit-wired
today. It fixes the direction and invariants so those adapters can be added only
when their implementation slice needs them.
