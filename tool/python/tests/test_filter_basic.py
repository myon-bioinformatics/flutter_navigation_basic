import json
from pathlib import Path
import subprocess
import sys

PYTHON_DIR = Path(__file__).resolve().parents[1]
CLI = PYTHON_DIR / "filter_basic.py"


def _run(payload: str):
    return subprocess.run(
        [sys.executable, "-S", str(CLI)],
        input=payload,
        capture_output=True,
        text=True,
        timeout=5,
    )


def test_filter_basic_keeps_equal_values_in_order():
    result = _run(json.dumps({"values": [1, 2, 1, 3], "equals": 1}))
    assert result.returncode == 0
    assert json.loads(result.stdout) == {"values": [1, 1]}


def test_filter_basic_handles_unicode_and_null():
    result = _run(json.dumps({"values": ["猫", None, "犬", "猫"], "equals": "猫"}))
    assert result.returncode == 0
    assert json.loads(result.stdout) == {"values": ["猫", "猫"]}


def test_filter_basic_rejects_invalid_contract():
    result = _run('{"values":"not-a-list","equals":1}')
    assert result.returncode == 2
    assert result.stdout == ""
    assert "values must be a JSON list" in result.stderr
