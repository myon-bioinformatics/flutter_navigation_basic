# Timezone oracle tooling

Development-only reference tooling for future multi-timezone / Now Timeline features.

The Flutter application does **not** execute Python at runtime. These scripts use only the Python standard library (`datetime` + `zoneinfo`) as an independent oracle for IANA timezone behavior, especially DST boundaries.

## Commands

```bash
python3 tool/time/verify_timezone.py
python3 tool/time/generate_timezone_cases.py --check
python3 tool/time/generate_timezone_cases.py
```

- `verify_timezone.py` validates every committed fixture case against the host IANA timezone data.
- `generate_timezone_cases.py --check` confirms that the fixture still matches the deterministic source cases.
- `generate_timezone_cases.py` rewrites the fixture when the explicit reference cases are intentionally changed.

The initial fixture covers `Asia/Tokyo`, `Europe/London`, and `America/New_York`, including both sides of the 2026 London and New York DST transitions.

No pip packages are required for this timezone oracle. Pip-based Python test
deps, when needed elsewhere, are allowlisted only under
`tool/python/requirements.txt`. If the host Python installation does not
provide IANA timezone data, these scripts fail with a clear message rather than
adding a package dependency.

## CI

These stdlib checks run in `.github/workflows/non-dart.yml` inside a
`python:3.12-slim` container (with `tzdata`), not in the Flutter gate.
