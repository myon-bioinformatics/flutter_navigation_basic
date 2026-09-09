# Python test / oracle tooling

This directory holds **dev/test-only** Python dependencies for light calculation
checks and golden/oracle helpers.

## Policy

- Flutter / Dart remains the source of truth for app behavior and UI tests.
- Python may use pip packages listed in `tool/python/requirements.txt`.
- Root-level or app-tree `requirements.txt` files remain prohibited.
- Prefer stdlib when it is enough (see `tool/time/`).
- Do not import these packages from Flutter runtime code.

## Setup

```bash
python3 -m venv .venv-python
source .venv-python/bin/activate
pip install -r tool/python/requirements.txt
pytest tool/python/tests
```

## Current coverage

- `fixtures/coordinate_area_cases.json`: shared golden vectors for zoom / span policy
- `tests/test_coordinate_area.py`: loads the shared fixture and checks latitude-aware
  Google Maps zoom heuristics plus Apple Maps `spn` eligibility
