"""Structural checks for shared coordinate-area golden JSON.

Formula / zoom / span assertions live in Dart `test/coordinate_tool/`.
This module only validates fixture shape with the standard library.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

FIXTURE_PATH = Path(__file__).resolve().parents[1] / "fixtures" / "coordinate_area_cases.json"

REQUIRED_KEYS = {
    "coordinateAreaCaseId",
    "latitude",
    "longitude",
    "radius_m",
    "expected_zoom",
    "expect_antimeridian",
    "expect_full_longitude",
    "expect_apple_spn",
}


def _load_payload() -> dict[str, Any]:
    return json.loads(FIXTURE_PATH.read_text(encoding="utf-8"))


def test_fixture_exists_and_is_object() -> None:
    assert FIXTURE_PATH.is_file()
    payload = _load_payload()
    assert isinstance(payload, dict)
    assert isinstance(payload.get("schema_version"), int)
    cases = payload.get("cases")
    assert isinstance(cases, list)
    assert len(cases) > 0


def test_case_ids_unique_and_non_empty() -> None:
    cases = _load_payload()["cases"]
    ids: list[str] = []
    for case in cases:
        assert isinstance(case, dict)
        case_id = case.get("coordinateAreaCaseId")
        assert isinstance(case_id, str)
        assert case_id.strip()
        ids.append(case_id)
    assert len(ids) == len(set(ids))


def test_cases_have_required_keys_and_types() -> None:
    for case in _load_payload()["cases"]:
        assert REQUIRED_KEYS.issubset(case.keys())
        assert isinstance(case["coordinateAreaCaseId"], str)
        assert isinstance(case["latitude"], (int, float))
        assert isinstance(case["longitude"], (int, float))
        assert isinstance(case["radius_m"], (int, float))
        assert case["radius_m"] > 0
        assert isinstance(case["expected_zoom"], int)
        assert isinstance(case["expect_antimeridian"], bool)
        assert isinstance(case["expect_full_longitude"], bool)
        assert isinstance(case["expect_apple_spn"], bool)
