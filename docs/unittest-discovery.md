# Focused standard-library test discovery

Run from this repository root with Python 3.11 or newer. These commands use
Python’s built-in test runner; no pip, uv sync, pytest or browser installation
is needed for the listed checks. `-S` keeps site-packages out of the interpreter.

```sh
python -S -m unittest discover -s python/tests -p test_flutter_focused_ci_contract.py -v
```

Validated on Linux / CPython 3.12.14: **4 tests, exit 0** (2026-11-03).

```sh
python -S -m unittest discover -s .github/scripts -p test_ci_status_label.py -v
```

Validated on Linux / CPython 3.12.14: **13 tests, exit 0** (2026-11-03).

To narrow the first command to a test name, use the built-in `-k` filter:

```sh
python -S -m unittest discover -s python/tests -p test_flutter_focused_ci_contract.py -v -k test_generic_scope_is_outside_default_test_directory
```

`-s` is the discovery start directory, `-p` matches test filenames, `-k`
filters test names, `-v` prints each executed test, and `-f` stops at the first
failure. Quote filename patterns so the shell does not expand them. Check the
final `Ran N tests` line: zero tests is not a successful verification, even
though unittest can exit 0. `-k` runs selected tests; it is not a list-only mode.

These are focused checks, not the complete project suite. Keep the existing
pytest/CI command for full coverage and native JUnit or fixture support.
Unittest does not collect module-level pytest functions or apply pytest
fixtures, parametrization, markers, conftest hooks or configured pythonpath.
A broad `test*.py` pattern can import pytest-only modules and fail under `-S`.
Do not add an extra CI pass over tests already owned by pytest just to expose
this local command. No custom discovery runner is required.
