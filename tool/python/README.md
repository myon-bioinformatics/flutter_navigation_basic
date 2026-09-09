# Python test / oracle tooling

This directory holds **dev/test-only** helpers for light calculation checks,
golden/oracle tests, and GitHub Actions status lookup.

## Tooling language split (stdlib-first)

Prefer each language's **standard library** for scripts/tests that do not need
a compile step. Avoid new environment dependencies unless allowlisted.

| Language | Prefer for | Notes |
| --- | --- | --- |
| **Dart / Flutter** | App runtime, widget/UI tests, repo toolkit (`tool/*.dart`) | App source of truth |
| **Python stdlib** | Actions status (`actions_latest.py`), JSON/zip/http one-liners, timezone oracle (`tool/time/`) | No pip required |
| **Python + allowlisted pip** | Structured oracles (`pytest`, `pydantic`) under `tool/python/requirements.txt` only | Not for app runtime |
| **Deno** (optional) | TS one-file fetch/CLI scripts with zero `node_modules` | OK when JS/TS + std fetch fits better than Python |

Root-level / app-tree `requirements.txt` remains prohibited.

## Setup (only needed for pytest oracles)

```bash
python3 -m venv .venv-python
source .venv-python/bin/activate
python -m pip install -r tool/python/requirements.txt
```

`--actions-latest` itself is **stdlib + `gh` or `GITHUB_TOKEN`** and does not need the venv.

## One-command entrypoint

```bash
# Local calculation oracles (default)
python3 tool/python/test.py
# same via Dart dispatcher
dart run tool/dev.dart py

# Latest GitHub Actions status for this branch
python3 tool/python/test.py --actions-latest
python3 tool/python/test.py --actions-latest --json
python3 tool/python/test.py --actions-latest --write build/diagnostics/actions-latest.json
dart run tool/dev.dart py --actions-latest --json

# Freshness: by default the run head_sha must equal git HEAD.
# Override only when intentionally inspecting an older green run:
python3 tool/python/test.py --actions-latest --allow-stale

# Download archived CI artifact from that run (also freshness-gated)
python3 tool/python/test.py --actions-latest --download-artifact python-oracle-summary

# Pytest mode switch via conftest
python3 tool/python/test.py --pytest -- --oracle-mode=local
python3 tool/python/test.py --pytest -- --oracle-mode=actions
python3 tool/python/test.py --pytest -- --oracle-mode=actions --actions-summary build/diagnostics/actions-latest.json

# Outcome tallies (passed/failed/skipped/xfailed/xpassed/error)
python3 tool/python/test.py --pytest -- --outcomes-json build/diagnostics/python-oracle/pytest_outcomes.json
# Flutter JSON reporter → same status vocabulary (known:/xfail: skips count as xfailed)
flutter test --file-reporter=json:build/diagnostics/flutter-test.json test/shared
python3 tool/python/test.py --flutter-outcomes build/diagnostics/flutter-test.json --json
```

## Outcome statuses

Aligned with pytest’s mix:

| Status | Meaning |
| --- | --- |
| `passed` | Asserted green |
| `failed` | Unexpected failure |
| `skipped` | Not run (mode/env gate, etc.) |
| `xfailed` | Expected fail / known gap (`pytest.mark.xfail`, or Flutter skip reason `known:` / `xfail:`) |
| `xpassed` | Marked xfail but passed |
| `error` | Collection/setup error |

CI uploads these counts inside the `python-oracle-summary` artifact (`pytest_outcomes.json` + `receipt.json`).

## Useful stdlib one-liners

```bash
# Pretty-print / validate JSON receipts and goldens
python3 -m json.tool tool/python/fixtures/coordinate_area_cases.json | head
python3 -m json.tool build/diagnostics/actions-latest.json > /dev/null

# Inspect / pack diagnostic zips
python3 -m zipfile -l build/diagnostics/some.zip
python3 -m zipfile -c build/diagnostics/bundle.zip build/diagnostics/python-oracle

# Tiny static server for local web artifacts
python3 -m http.server 8000 --directory build/web
```

## Current coverage

- `fixtures/coordinate_area_cases.json`: shared golden vectors for zoom / span policy
- `tests/test_coordinate_area.py`: latitude-aware Maps framing oracles
- `tests/test_actions_latest.py`: optional CI-green assertion (`--oracle-mode=actions`)
- `tests/test_outcomes.py` / `outcomes.py`: multi-status tallies including xfail/known
- `tests/test_known_xfail_example.py`: documents `xfail(reason="known: …")` for receipts
- `actions_latest.py` / `test.py`: fetch latest Actions jobs + optional artifact download
- CI uploads `python-oracle-summary` for later `--download-artifact` use
- Latest-stable Flutter shards run **core** paths only (`tool/ci/flutter_core_test_paths.txt`); pattern catalogues stay on pinned shards
