# Patterns 091–099: Python validation producer (limited implementation)

## Responsibility and actual scope

- `tool/python/validation_patterns.py`: standalone Python 3 stdlib-only CLI, JSON stdin/stdout.
- `tool/python/tests/test_validation_patterns.py`: normal, invalid, boundary, and form aggregation contracts.
- Existing Flutter `view.dart` files remain unchanged. **No Flutter→Python execution bridge or interactive validation form is wired yet.**
- No production/test Dart files were removed in this slice. This is a new producer, not a completed UI migration.

| Pattern | Operation | Contract / limitation |
|---|---|---|
| 091 ValidationBasic | `required` | Nonempty input check, not a form framework |
| 092 EmailValidation | `email` | Practical ASCII heuristic, not RFC-complete or deliverability check |
| 093 PasswordStrength | `password` | Minimum length and character categories, **not** a security-strength estimate |
| 094 PhoneValidation | `phone` | E.164-like digits, no regional numbering-plan verification |
| 095 UrlValidation | `url` | HTTP(S) syntax only, not SSRF protection or host safety |
| 096 DateValidation | `date` | Strict YYYY-MM-DD calendar date |
| 097 RangeValidation | `range` | Inclusive finite numeric bounds |
| 098 RegexValidation | `regex` | Named allowlist only; arbitrary user regex intentionally unsupported |
| 099 FormValidation | `form` | Aggregate field results; no Flutter form lifecycle |

## Handoff / next steps

1. Keep all nine as **限定実装（Python producer exists; Flutter unwired）** in the 198-row audit.
2. Add browser/Flutter UI wiring only when an actual execution path is defined; do not claim standalone CLI tests prove UI functionality.
3. When changing Views, record production Dart/test Dart deletions, case-level JUnit, browser operation and actual output.
4. Never present email/URL/password heuristics as authoritative security validation.
