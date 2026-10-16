"""Cross-language contract for vendored Ironmate Base64 bridge fixture."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Any

import pytest

ROOT = Path(__file__).resolve().parents[2]
FIXTURE_DIR = ROOT / "test" / "fixtures" / "base64_bridge"
CASES_PATH = FIXTURE_DIR / "base64_bridge_cases.json"
PROVENANCE_PATH = FIXTURE_DIR / "base64_bridge_cases.provenance.json"
EXPECTATIONS_PATH = FIXTURE_DIR / "flutter_expectations.json"


def _load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def test_fixture_files_exist() -> None:
    assert CASES_PATH.is_file()
    assert PROVENANCE_PATH.is_file()
    assert EXPECTATIONS_PATH.is_file()


def test_vendored_fixture_sha256_matches_provenance() -> None:
    provenance = _load_json(PROVENANCE_PATH)
    digest = hashlib.sha256(CASES_PATH.read_bytes()).hexdigest()
    assert digest == provenance["sha256"]
    assert provenance["source_repository"].endswith("/Ironmate")
    assert provenance["source_path"] == "tests/fixtures/base64_bridge_cases.json"
    assert len(provenance["source_commit"]) == 40


def test_expectations_cover_all_case_ids_without_extra_keys() -> None:
    cases_doc = _load_json(CASES_PATH)
    expectations_doc = _load_json(EXPECTATIONS_PATH)
    case_ids = [case["id"] for case in cases_doc["cases"]]
    assert len(case_ids) == len(set(case_ids))
    mapped = expectations_doc["cases"]
    assert set(mapped) == set(case_ids)


def test_expectation_shape() -> None:
    expectations_doc = _load_json(EXPECTATIONS_PATH)
    for case_id, expectation in expectations_doc["cases"].items():
        assert isinstance(case_id, str)
        assert isinstance(expectation, dict)
        accept = expectation.get("accept")
        assert isinstance(accept, bool)
        if accept:
            fmt = expectation.get("detectedFormat")
            assert fmt in {"png", "jpeg", "webp"}
        else:
            assert "detectedFormat" not in expectation


def test_ironmate_fixture_expect_field_aligns_with_flutter_accept() -> None:
    """Ironmate expect ok/reject must match Flutter accept flag (not message text)."""
    cases_doc = _load_json(CASES_PATH)
    expectations_doc = _load_json(EXPECTATIONS_PATH)
    for case in cases_doc["cases"]:
        case_id = case["id"]
        ironmate_ok = case["expect"] == "ok"
        flutter_accept = expectations_doc["cases"][case_id]["accept"]
        assert ironmate_ok == flutter_accept, case_id


def test_adversarial_legacy_accept_set_is_non_empty() -> None:
    """Document ids a no-magic-byte decoder would wrongly accept (caught by Dart adversarial test)."""
    cases_doc = _load_json(CASES_PATH)
    expectations_doc = _load_json(EXPECTATIONS_PATH)
    would_accept: list[str] = []
    for case in cases_doc["cases"]:
        case_id = case["id"]
        if expectations_doc["cases"][case_id]["accept"]:
            continue
        if case["expect"] == "reject" and case.get("result") in {
            "mismatch",
            "unsupported_format",
            "bad_data_uri",
            "bad_base64",
        }:
            would_accept.append(case_id)
    assert "data_mismatch_jpeg_label" in would_accept
    assert len(would_accept) >= 5
