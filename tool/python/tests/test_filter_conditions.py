"""Multiple/nested conditions share the FilterBasic CLI and Flutter boundary."""
import json
from pathlib import Path
import subprocess
import sys

import pytest

PYTHON_DIR = Path(__file__).resolve().parents[1]
ROOT = PYTHON_DIR.parents[1]
CLI = PYTHON_DIR / "filter_basic.py"


def _run(payload="", *args):
    return subprocess.run([sys.executable, "-S", str(CLI), *map(str, args)],
                          input=payload, capture_output=True, text=True,
                          encoding="utf-8", timeout=5)


@pytest.mark.parametrize("match,expected", [
    ("all", ["A", "A"]), ("any", ["A", "B", "C", "A"]),
])
def test_filter_conditions_combine_without_reordering(match, expected):
    values = [{"name": "A", "kind": "pet", "active": True},
              {"name": "B", "kind": "pet", "active": False},
              {"name": "C", "kind": "wild", "active": True},
              {"name": "A", "kind": "pet", "active": True}]
    result = _run(json.dumps({"values": values, "match": match, "conditions": [
        {"path": ["kind"], "equals": "pet"}, {"path": ["active"], "equals": True},
    ]}))
    assert result.returncode == 0, result.stderr
    assert [v["name"] for v in json.loads(result.stdout)["values"]] == expected
    assert not result.stderr


def test_filter_conditions_nested_indices_and_literal_keys():
    values = [{"profile": {"a.b": ["猫"]}}, {"profile": {"a.b": []}},
              {"profile": {"a.b": ["犬"]}}, {}, {"profile": None}]
    result = _run(json.dumps({"values": values, "conditions": [
        {"path": ["profile", "a.b", 0], "equals": "猫"},
    ]}))
    assert result.returncode == 0, result.stderr
    assert json.loads(result.stdout)["values"] == [values[0]]


def test_filter_conditions_missing_is_not_explicit_null():
    result = _run(json.dumps({"values": [{}, {"key": None}, {"key": False}],
                             "conditions": [{"path": ["key"], "equals": None}]}))
    assert result.returncode == 0, result.stderr
    assert json.loads(result.stdout)["values"] == [{"key": None}]


@pytest.mark.parametrize("condition", [{"equals": None}, {"path": [], "equals": None}])
def test_filter_conditions_can_match_whole_value(condition):
    result = _run(json.dumps({"values": [None, "猫", None], "conditions": [condition]}))
    assert result.returncode == 0, result.stderr
    assert json.loads(result.stdout)["values"] == [None, None]


@pytest.mark.parametrize("extra", [
    {"conditions": []}, {"conditions": {}}, {"conditions": [None]},
    {"conditions": [{}]}, {"conditions": [{"equals": 1, "path": "a.b"}]},
    {"conditions": [{"equals": 1, "path": [-1]}]},
    {"conditions": [{"equals": 1, "path": [True]}]},
    {"conditions": [{"equals": 1, "path": [1.0]}]},
    {"conditions": [{"equals": 1, "path": [None]}]},
    {"conditions": [{"equals": 1, "operator": "eval"}]},
    {"conditions": [{"equals": 1}], "match": "xor"},
    {"conditions": [{"equals": 1}], "equals": 1},
    {"equals": 1, "match": "any"},
])
def test_filter_conditions_reject_bad_contract_even_for_empty_input(extra):
    result = _run(json.dumps({"values": [], **extra}))
    assert result.returncode == 2
    assert result.stdout == ""
    assert "filter-basic:" in result.stderr
    assert "Traceback" not in result.stderr


@pytest.mark.parametrize("stem", ["filter_multiple", "filter_nested"])
def test_filter_conditions_assets_generation_drift_and_enrolment(stem, tmp_path):
    source = PYTHON_DIR / "fixtures" / (stem + "_input.json")
    asset = ROOT / "assets/data_processing" / (stem + ".json")
    check = _run("", "--input", source, "--output", asset, "--check")
    assert check.returncode == 0, check.stderr
    target = tmp_path / "result.json"
    generated = _run("", "--input", source, "--output", target)
    assert generated.returncode == 0 and generated.stdout == ""
    payload = json.loads(target.read_text(encoding="utf-8"))
    assert payload["values"]
    payload["unrelated_metadata"] = {"anything": True}
    target.write_text(json.dumps(payload), encoding="utf-8")
    assert _run("", "--input", source, "--output", target, "--check").returncode == 0
    payload["values"] = []
    target.write_text(json.dumps(payload), encoding="utf-8")
    before = target.read_bytes()
    assert _run("", "--input", source, "--output", target, "--check").returncode == 1
    assert target.read_bytes() == before
    assert f"assets/data_processing/{stem}.json" in (ROOT / "pubspec.yaml").read_text()
    paths = (ROOT / "tool/ci/flutter_pattern_test_paths.txt").read_text().splitlines()
    assert "test/features/data_processing_patterns" in paths
    assert (ROOT / "test/features/data_processing_patterns/pattern_001_to_099/filter_conditions_test.dart").is_file()
