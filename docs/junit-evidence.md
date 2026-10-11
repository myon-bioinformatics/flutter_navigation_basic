# Python JUnit evidence

The primary Python lane uploads its ordinary pytest JUnit XML and the controlled
child's evidence as separate `junit-*` Actions artifacts (14 days, including
producer failure). Raw diagnostics are not published to Pages. The exact two XML
paths are inputs to the pinned shared JUnit identity collector; missing, malformed
or truncated reports fail collection. Ordinary pytest failures still fail the
producer and workflow.

The controlled child is intentionally red inside a green regression. It runs with
and without JUnit, checks both exit codes are 1, and uses the shared xprobe importer
to check failure/setup-error identities and sentinel redaction. Compact cases
carry the checkout SHA from the canonical repository-metadata generator and a
run-order-independent fingerprint (`tool/python/failure_identity.py`). The shared
collector separately records the commit its caller states.

The importer is the repository's vendored `tool/python/vendor/xprobe.py`, pinned and
byte-checked through `tool/python/vendor.lock.json`; the regression asserts it loads
that file. CI no longer checks out a separate xprobe copy.
No runtime import or dependency is added.

The regression uses the real `tool/python/test.py` wrapper and verifies its native
`outcomes.json` counts/exitstatus with and without JUnit. Ordinary outcomes and the
existing oracle receipt remain separate from compact identity. The collector uses
the existing Python/workflow path selection; Dart, Docker and Playwright reports
are outside its expected set.
