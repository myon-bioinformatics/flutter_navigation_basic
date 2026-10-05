"""Focused CLI, generated-asset and CI-collection contracts for FilterBasic."""
import json
from pathlib import Path
import subprocess
import sys

import pytest

PYTHON_DIR = Path(__file__).resolve().parents[1]
ROOT = PYTHON_DIR.parents[1]
CLI = PYTHON_DIR / "filter_basic.py"
INPUT = PYTHON_DIR / "fixtures/filter_basic_input.json"
ASSET = ROOT / "assets/data_processing/filter_basic.json"


def _run(payload="", *args):
    return subprocess.run([sys.executable, "-S", str(CLI), *map(str, args)],
                          input=payload, capture_output=True, text=True,
                          encoding="utf-8", timeout=5)


@pytest.mark.parametrize("values,equals,expected", [
    ([1, 2, 1, 3], 1, [1, 1]),
    (["猫", None, "犬", "猫"], "猫", ["猫", "猫"]),
    ([None, 1, None], None, [None, None]),
    ([], "猫", []),
    ([{"name": "猫"}, {"name": "犬"}], {"name": "猫"}, [{"name": "猫"}]),
])
def test_filter_basic_contract(values, equals, expected):
    result = _run(json.dumps({"values": values, "equals": equals}))
    assert result.returncode == 0, result.stderr
    assert json.loads(result.stdout)["values"] == expected
    assert not result.stderr


@pytest.mark.parametrize("payload", [
    '{"values":"not-a-list","equals":1}', '{}', '[]',
    '{"values":[]}', 'not json', '{"values":[NaN],"equals":1}',
])
def test_filter_basic_rejects_invalid_contract(payload):
    result = _run(payload)
    assert result.returncode == 2
    assert result.stdout == ""
    assert "filter-basic:" in result.stderr


def test_filter_basic_generated_asset_is_current():
    result = _run("", "--input", INPUT, "--output", ASSET, "--check")
    assert result.returncode == 0, result.stderr
    assert result.stdout == ""


def test_filter_basic_file_output_and_drift(tmp_path):
    source = tmp_path / "input.json"
    target = tmp_path / "result.json"
    source.write_text('{"values":["猫",null,"猫"],"equals":"猫"}', encoding="utf-8")
    result = _run("", "--input", source, "--output", target)
    assert result.returncode == 0 and result.stdout == ""
    assert json.loads(target.read_text(encoding="utf-8"))["values"] == ["猫", "猫"]
    # Extra metadata is not part of the consumed values contract.
    target.write_text('{"values":["猫","猫"],"extra":"ignored"}', encoding="utf-8")
    assert _run("", "--input", source, "--output", target, "--check").returncode == 0
    target.write_text('{"values":[]}', encoding="utf-8")
    before = target.read_bytes()
    stale = _run("", "--input", source, "--output", target, "--check")
    assert stale.returncode == 1 and "stale" in stale.stderr
    assert target.read_bytes() == before


def test_filter_basic_missing_file_and_invalid_check(tmp_path):
    assert _run("", "--input", tmp_path / "missing").returncode == 2
    assert _run("", "--check").returncode == 2


def test_filter_basic_asset_and_flutter_test_are_enrolled():
    assert "assets/data_processing/filter_basic.json" in (ROOT / "pubspec.yaml").read_text()
    paths = (ROOT / "tool/ci/flutter_pattern_test_paths.txt").read_text().splitlines()
    assert "test/features/data_processing_patterns" in paths
    assert (ROOT / "test/features/data_processing_patterns/pattern_001_to_099/pattern_001_test.dart").is_file()


@pytest.mark.parametrize("values", [[True, True], [1.0, 1.0]])
def test_filter_basic_check_preserves_json_value_types(tmp_path, values):
    # Python considers True == 1 == 1.0, but Flutter renders these differently.
    target = tmp_path / "result.json"
    target.write_text(json.dumps({"values": values}), encoding="utf-8")
    result = _run("", "--input", INPUT, "--output", target, "--check")
    assert result.returncode == 1
    assert "stale" in result.stderr
