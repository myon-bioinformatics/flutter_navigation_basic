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

No `requirements.txt` is used or required. If the host Python installation does not provide IANA timezone data, the scripts fail with a clear message rather than adding a package dependency.
