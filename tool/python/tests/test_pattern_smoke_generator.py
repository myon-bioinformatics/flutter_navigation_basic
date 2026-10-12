"""The generated Dart pattern smoke test covers every api/navigation/ui_theme pattern."""
from __future__ import annotations

import sys
from pathlib import Path

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
