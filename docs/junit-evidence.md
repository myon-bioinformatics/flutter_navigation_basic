The primary Python lane uploads its ordinary pytest JUnit XML and the controlled
child's evidence as separate `junit-*` Actions artifacts (14 days, including
producer failure). Raw diagnostics are not published to Pages. The exact two XML
paths are inputs to the pinned shared JUnit identity collector; missing, malformed
or truncated reports fail collection. Ordinary pytest failures still fail the
producer and workflow.

The controlled child is intentionally red inside a green regression. It runs with
and without JUnit, checks both exit codes are 1, and uses the shared xprobe importer
to check failure/setup-error identities and sentinel redaction. Compact context
has `commit_sha=null`; this lane does not infer provenance from Git or connect the
canonical metadata producer.

The importer is test-only and byte-verified before loading. CI checks out upstream
xprobe at `7e7015b2df69ad446b968f6fa49711b5b1dbdd3f` into `.junit-tools`.
For a local full pytest run, place that commit's `xprobe.py` in
`.junit-tools/xprobe.py` first (Git blob `dbc5b7d55005d6288c072a7612584d6170c216f4`).
No runtime import or dependency is added.

The regression uses the real `tool/python/test.py` wrapper and verifies its native
`outcomes.json` counts/exitstatus with and without JUnit. Ordinary outcomes and the
existing oracle receipt remain separate from compact identity. The collector uses
the existing Python/workflow path selection; Dart, Docker and Playwright reports
are outside its expected set.
