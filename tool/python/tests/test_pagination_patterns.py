"""Regression tests for pagination patterns 031-033."""
import importlib.util
from pathlib import Path
import json
import subprocess
import sys
import pytest

SCRIPT = Path(__file__).resolve().parents[1] / "pagination_patterns.py"
spec = importlib.util.spec_from_file_location("pagination_patterns", SCRIPT)
pagination = importlib.util.module_from_spec(spec)
spec.loader.exec_module(pagination)


def test_offset_pages_and_terminal():
    data = list(range(5))
    a = pagination.page({"operation": "offset", "items": data, "limit": 2})
    assert a == {"items": [0, 1], "has_more": True, "next_offset": 2}
    b = pagination.page({"operation": "offset", "items": data, "limit": 2, "offset": 4})
    assert b == {"items": [4], "has_more": False, "next_offset": None}


@pytest.mark.parametrize("mode", ["cursor", "infinite"])
def test_cursor_traversal_no_duplicate_or_missing_items(mode):
    data = [{"id": i} for i in range(7)]
    token, observed = None, []
    while True:
        request = {"operation": mode, "items": data, "limit": 3}
        if token is not None:
            request["cursor"] = token
        result = pagination.page(request)
        observed.extend(result["items"])
        if not result["has_more"]:
            assert result["next_cursor"] is None
            break
        token = result["next_cursor"]
    assert observed == data


def test_cursor_rejects_mutated_dataset():
    first = pagination.page({"operation": "cursor", "items": [1, 2, 3], "limit": 1})
    with pytest.raises(ValueError, match="dataset"):
        pagination.page({"operation": "cursor", "items": [1, 2, 4],
                         "limit": 1, "cursor": first["next_cursor"]})


@pytest.mark.parametrize("payload", [
    {"operation": "offset", "items": [], "limit": 0},
    {"operation": "offset", "items": [], "limit": True},
    {"operation": "offset", "items": [], "limit": 1, "offset": -1},
    {"operation": "cursor", "items": [1, 2], "limit": 1, "cursor": "bad"},
    {"operation": "infinite", "items": [], "limit": 1, "offset": 0},
    {"operation": "offset", "items": [], "limit": 1, "extra": True},
])
def test_invalid_contracts_fail_closed(payload):
    with pytest.raises(ValueError):
        pagination.page(payload)


def test_cli_returns_json_and_nonzero_for_bad_input():
    good = subprocess.run([sys.executable, "-I", "-S", str(SCRIPT)],
                          input=json.dumps({"operation": "offset", "items": [1], "limit": 1}),
                          text=True, capture_output=True, timeout=5)
    assert good.returncode == 0
    assert json.loads(good.stdout)["items"] == [1]
    bad = subprocess.run([sys.executable, "-I", "-S", str(SCRIPT)],
                         input='{"operation":"cursor","items":[],"limit":0}',
                         text=True, capture_output=True, timeout=5)
    assert bad.returncode == 2 and not bad.stdout
