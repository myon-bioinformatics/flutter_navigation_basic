"""Pattern 113 reports deduplication validation without duplicating Dart logic."""
import json
from pathlib import Path
import subprocess
import sys

import pytest

PYTHON_DIR = Path(__file__).resolve().parents[1]
ROOT = PYTHON_DIR.parents[1]
CLI = PYTHON_DIR / "list_selection.py"
INPUT = PYTHON_DIR / "fixtures/deduplicate_report_input.json"
ASSET = ROOT / "assets/data_processing/deduplicate_report.json"


def _run(payload="", *args):
    return subprocess.run(
        [sys.executable, "-S", str(CLI), *map(str, args)], input=payload,
        capture_output=True, text=True, encoding="utf-8", timeout=5,
    )


@pytest.mark.parametrize(
    "values,expected",
    [
        ([3, 1, 3, 2, 1], (5, 3, 2, True)),
        ([], (0, 0, 0, False)),
        ([True, 1, 1.0], (3, 3, 0, False)),
        ([{"a": 1, "b": 2}, {"b": 2, "a": 1}], (2, 1, 1, True)),
    ],
)
def test_deduplicate_report_counts_canonical_duplicates(values, expected):
    result = _run(json.dumps({"operation": "deduplicate_report", "values": values}))
    assert result.returncode == 0, result.stderr
    [report] = json.loads(result.stdout)["values"]
    assert (
        report["input_count"],
        report["unique_count"],
        report["duplicate_count"],
        report["has_duplicates"],
    ) == expected
    assert not result.stderr


@pytest.mark.parametrize(
    "payload",
    [
        {"operation": "deduplicate_report"},
        {"operation": "deduplicate_report", "values": None},
        {"operation": "deduplicate_report", "values": [], "equals": 1},
        {"operation": "deduplicate_report", "values": [], "conditions": []},
    ],
)
def test_deduplicate_report_rejects_ambiguous_contract(payload):
    result = _run(json.dumps(payload))
    assert result.returncode == 2
    assert not result.stdout
    assert "list-selection:" in result.stderr


def test_deduplicate_report_asset_is_current():
    result = _run("", "--input", INPUT, "--output", ASSET, "--check")
    assert result.returncode == 0, result.stderr


def test_pattern_113_uses_report_asset_without_getx_scaffolding():
    assert "assets/data_processing/deduplicate_report.json" in (
        ROOT / "pubspec.yaml"
    ).read_text(encoding="utf-8")
    pattern = ROOT / "lib/features/data_processing_patterns/pattern_100_to_198/pattern_113"
    assert not (pattern / "model.dart").exists()
    assert not (pattern / "controller.dart").exists()
    service = (pattern / "service.dart").read_text(encoding="utf-8")
    view = (pattern / "view.dart").read_text(encoding="utf-8")
    assert "assets/data_processing/deduplicate_report.json" in service
    assert "package:get/" not in service
    assert "package:get/" not in view
