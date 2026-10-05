"""The list-selection CLI is a portable stdlib runtime boundary."""
import json
from pathlib import Path
import subprocess
import sys

import pytest

PYTHON_DIR = Path(__file__).resolve().parents[1]
CLI = PYTHON_DIR / "list_selection.py"


@pytest.mark.parametrize(
    "payload,exit_code,expected",
    [
        ('{"values":[1,2,1],"equals":1}', 0, [1, 1]),
        ('{"operation":"distinct","values":["猫","犬","猫"]}', 0, ["猫", "犬"]),
        ('{"values":"invalid","equals":1}', 2, None),
        ('{"values":[1e999],"equals":0}', 2, None),
    ],
)
def test_list_selection_runs_from_isolated_single_file(tmp_path, payload, exit_code, expected):
    isolated = tmp_path / "list_selection.py"
    isolated.write_bytes(CLI.read_bytes())
    result = subprocess.run(
        [sys.executable, "-I", "-S", str(isolated)],
        input=payload,
        capture_output=True,
        text=True,
        encoding="utf-8",
        timeout=5,
        cwd=tmp_path,
    )
    assert result.returncode == exit_code
    if expected is None:
        assert result.stdout == ""
        assert "list-selection:" in result.stderr
    else:
        assert json.loads(result.stdout)["values"] == expected
        assert result.stderr == ""


def test_deeply_nested_json_is_invalid_input_not_stale(tmp_path):
    depth = 1200
    payload = "[" * depth + "0" + "]" * depth
    result = subprocess.run(
        [sys.executable, "-S", str(CLI)],
        input='{"values":' + payload + ',"equals":0}',
        capture_output=True,
        text=True,
        timeout=5,
    )
    assert result.returncode == 2
    assert "list-selection:" in result.stderr
