# Data processing responsibility audit

The catalogue numbers do not require one Dart implementation each.
Run the read-only stdlib inventory:

    python -S tool/python/pattern_responsibility_audit.py --json --check

It produces per-pattern source files, evidence status, proposed owner,
related standalone CLI and test, stale README flag and known limitations.
The Refactor smoke Python job publishes JSON as an artifact.

A green run means its named structural/test contracts passed, NOT that every
business function is complete or that an external Python/MJS CLI runs inside
Flutter. Current debt includes fake GetX services in patterns 001-044 and
native-gesture patterns, description-only cache/validation examples,
obsolete README references, and real browser behavior not yet wired to UI.

Pattern 102: input sanitize title is not proof of XSS/SQL defense.
Patterns 187/191/192/195/196/198 are bounded in-memory references, not
database/distributed/persistent equivalents.

Any later deletion should first document actual use, data contract,
negative tests, native UI gesture/lifecycle checks, and whether the Flutter
execution bridge exists or is intentionally out of scope.

Browser-test-kit is a natural home for generic Playwright target, screenshot
and evidence helpers. Flutter-specific UI IDs/routes belong in this repo.
The Python wrapper can invoke Playwright from a one-liner but Playwright
and its browser binaries remain dependencies for real browser control.

Before merging PR #145, run the E2E-only native interaction routes from
the Python and Node Playwright CLIs, inspect the resulting evidence, and
merge with a normal merge commit (never squash the full commit history).
