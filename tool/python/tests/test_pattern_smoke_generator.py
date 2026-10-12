"""The generated Dart pattern smoke test covers every api/navigation/ui_theme pattern."""
from __future__ import annotations

import sys
import subprocess
from pathlib import Path

import pytest
import yaml

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import generate_pattern_smoke_test as gen  # noqa: E402


def test_committed_file_is_current():
    assert gen.main(["--check"]) == 0


def test_every_pattern_is_covered_once():
    found = gen.patterns()
    text = gen.OUT.read_text(encoding="utf-8")
    assert len(found) == len({(f, n) for f, _, n, _ in found}) == 594
    for family, _, number, dedicated in found:
        assert f"_Pattern('{family}/pattern_{number}'" in text
    dedicated = sorted(f"{f}/{n}" for f, _, n, d in found if d)
    assert dedicated == ["api_patterns/001", "api_patterns/002"]
    assert text.count(", null),") == 2


def test_no_per_pattern_template_tests_remain():
    for family in gen.FAMILIES:
        tests = sorted((gen.ROOT / "test" / "features" / family).rglob("*_test.dart"))
        expected = 2 if family == "api_patterns" else 0
        assert len(tests) == expected, tests


@pytest.mark.parametrize("path", [
    "tool/python/generate_pattern_smoke_test.py",
    "tool/python/check_pattern_smoke_mutations.py",
    "tool/python/tests/test_pattern_smoke_generator.py",
    "test/features/catalogue_smoke_patterns/pattern_catalogue_smoke_test.dart",
    "test/features/api_patterns/pattern_001_to_099/pattern_001_test.dart",
    "lib/features/navigation_patterns/pattern_100_to_198/pattern_198/service.dart",
    "tool/ci/flutter_pattern_test_paths.txt",
    ".github/workflows/dart.yml",
])
def test_smoke_changes_select_flutter_and_pattern_shards(path):
    workflow = yaml.safe_load((gen.ROOT / ".github/workflows/dart.yml").read_text())
    script = workflow["jobs"]["changes"]["steps"][1]["run"]
    # Execute the real classifier, supplying one changed path without GitHub/git.
    classifier = script[script.index("flutter=false"):].split("\n{", 1)[0]
    result = subprocess.run(
        ["bash", "-c", 'files=("$1")\n' + classifier +
         '\n[[ "$flutter" == true && "$patterns" == true ]]', "classifier", path],
        capture_output=True, text=True,
    )
    assert result.returncode == 0, result.stderr


def test_ci_keeps_smoke_dedicated_tests_and_independent_contracts():
    paths = (gen.ROOT / "tool/ci/flutter_pattern_test_paths.txt").read_text().splitlines()
    assert "test/features/catalogue_smoke_patterns" in paths
    assert "test/features/api_patterns" in paths
    workflow = yaml.safe_load((gen.ROOT / ".github/workflows/dart.yml").read_text())
    jobs = workflow["jobs"]
    assert jobs["unit-tests-patterns"]["strategy"]["matrix"]["shard"] == [0, 1, 2, 3]
    assert any("check_pattern_smoke_mutations.py" in step.get("run", "")
               for step in jobs["unit-tests-patterns"]["steps"])
    assert any("tool/export_pattern_contracts.dart" in step.get("run", "")
               for step in jobs["gate"]["steps"])
    assert "unit-tests-patterns" in jobs["junit-identity"]["needs"]
