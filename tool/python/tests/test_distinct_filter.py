"""DistinctFilter shares the existing stdlib JSON producer and UI boundary."""
import json
from pathlib import Path
import subprocess
import sys

import pytest

PYTHON_DIR = Path(__file__).resolve().parents[1]
ROOT = PYTHON_DIR.parents[1]
CLI = PYTHON_DIR / "filter_basic.py"
INPUT = PYTHON_DIR / "fixtures/distinct_filter_input.json"
ASSET = ROOT / "assets/data_processing/distinct_filter.json"


def _run(payload="", *args):
    return subprocess.run(
        [sys.executable, "-S", str(CLI), *map(str, args)], input=payload,
        capture_output=True, text=True, encoding="utf-8", timeout=5,
    )


@pytest.mark.parametrize("values,expected", [
    ([3, 1, 3, 2, 1], [3, 1, 2]),
    ([], []),
    (["猫", "犬", "猫", None, None], ["猫", "犬", None]),
    ([True, 1, 1.0, False, 0, 0.0, True], [True, 1, 1.0, False, 0, 0.0]),
    ([{"a": 1, "b": 2}, {"b": 2, "a": 1}], [{"a": 1, "b": 2}]),
    ([[1, 2], [2, 1], [1, 2]], [[1, 2], [2, 1]]),
    ([{"a": [True]}, {"a": [1]}, {"a": [True]}], [{"a": [True]}, {"a": [1]}]),
])
def test_distinct_keeps_first_values_with_typed_json_identity(values, expected):
    result = _run(json.dumps({"operation": "distinct", "values": values}))
    assert result.returncode == 0, result.stderr
    actual = json.loads(result.stdout)["values"]
    # Narrow consumed-value comparison, retaining bool/int/float distinctions.
    assert json.dumps(actual, sort_keys=True) == json.dumps(expected, sort_keys=True)
    assert not result.stderr


@pytest.mark.parametrize("payload", [
    {"operation": "distinct", "values": None},
    {"operation": "distinct"},
    {"operation": "unknown", "values": [], "equals": 1},
    {"operation": "distinct", "values": [], "equals": 1},
    {"operation": "distinct", "values": [], "conditions": []},
    {"operation": "distinct", "values": [], "match": "all"},
    {"operation": "distinct", "values": [], "key_path": ["id"]},
])
def test_distinct_rejects_invalid_or_ambiguous_contract(payload):
    result = _run(json.dumps(payload))
    assert result.returncode == 2
    assert not result.stdout
    assert "filter-basic:" in result.stderr


@pytest.mark.parametrize("payload", [
    '{"values":[1e999],"equals":0}',
    '{"values":[],"equals":-1e999}',
    '{"operation":"distinct","values":[{"score":1e999}]}',
])
def test_nonfinite_exponents_are_rejected_before_processing(payload):
    result = _run(payload)
    assert result.returncode == 2
    assert not result.stdout


def test_distinct_asset_generation_and_nondestructive_drift(tmp_path):
    target = tmp_path / "result.json"
    result = _run("", "--input", INPUT, "--output", target)
    assert result.returncode == 0, result.stderr
    assert not result.stdout
    values = json.loads(target.read_text(encoding="utf-8"))["values"]
    assert values == ["猫", "犬", None]
    target.write_text(json.dumps({"values": values, "note": "not consumed"}), encoding="utf-8")
    assert _run("", "--input", INPUT, "--output", target, "--check").returncode == 0
    target.write_text('{"values":[]}', encoding="utf-8")
    before = target.read_bytes()
    stale = _run("", "--input", INPUT, "--output", target, "--check")
    assert stale.returncode == 1 and "stale" in stale.stderr
    assert target.read_bytes() == before


def test_distinct_checked_in_asset_is_current():
    result = _run("", "--input", INPUT, "--output", ASSET, "--check")
    assert result.returncode == 0, result.stderr


def test_distinct_asset_and_shared_flutter_test_are_enrolled():
    assert "assets/data_processing/distinct_filter.json" in (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
    suite = ROOT / "test/features/data_processing_patterns/pattern_001_to_099/filter_conditions_test.dart"
    assert "Pattern030Service" in suite.read_text(encoding="utf-8")
    paths = (ROOT / "tool/ci/flutter_pattern_test_paths.txt").read_text(encoding="utf-8").splitlines()
    assert "test/features/data_processing_patterns" in paths
    pattern = ROOT / "lib/features/data_processing_patterns/pattern_001_to_099/pattern_030"
    assert not (pattern / "model.dart").exists()
    assert not (pattern / "controller.dart").exists()
    for name in ("service.dart", "view.dart"):
        assert "package:get/" not in (pattern / name).read_text(encoding="utf-8")
