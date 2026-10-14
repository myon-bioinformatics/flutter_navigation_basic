#!/usr/bin/env python3
"""Screenshot comparison CLI backed by the locked browser-test-kit implementation."""
import importlib.util
from pathlib import Path

_path = Path(__file__).resolve().parent / "vendor" / "image_diff.py"
_spec = importlib.util.spec_from_file_location("_browser_test_kit_image_diff", _path)
_module = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_module)

load = _module.load
compare = _module.compare
main = _module.main

if __name__ == "__main__":
    raise SystemExit(main())
