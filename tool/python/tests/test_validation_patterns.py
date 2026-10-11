"""Regression contracts for 091-099 validation producers."""
import importlib.util
from pathlib import Path
import pytest

path = Path(__file__).resolve().parents[1] / "validation_patterns.py"
spec = importlib.util.spec_from_file_location("validation_patterns", path)
v = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v)


@pytest.mark.parametrize(("operation", "good", "bad"), [
    ("required", "value", "  "),
    ("email", "a@example.org", "a@@example.org"),
    ("password", "longpassword123", "short"),
    ("phone", "+819012345678", "090-1234-5678"),
    ("url", "https://example.org/path", "javascript:alert(1)"),
    ("date", "2024-02-29", "2023-02-29"),
])
def test_positive_and_negative_cases(operation, good, bad):
    assert v.run({"operation": operation, "value": good}) == {"valid": True}
    assert v.run({"operation": operation, "value": bad}) == {"valid": False}


def test_range_boundaries_and_invalid_bounds():
    request = {"operation": "range", "options": {"minimum": 1, "maximum": 3}}
    assert v.run({**request, "value": 1})["valid"]
    assert not v.run({**request, "value": 4})["valid"]
    with pytest.raises(ValueError):
        v.run({"operation": "range", "value": 2, "options": {"minimum": 4, "maximum": 1}})


def test_named_regex_and_unknown_pattern():
    assert v.run({"operation": "regex", "value": "abc_1", "options": {"pattern": "ascii_identifier"}})["valid"]
    with pytest.raises(ValueError):
        v.run({"operation": "regex", "value": "x", "options": {"pattern": "(a+)+"}})


def test_form_reports_individual_fields_and_aggregate():
    result = v.run({"operation": "form", "fields": [
        {"name": "email", "rule": "email", "value": "a@example.org"},
        {"name": "date", "rule": "date", "value": "2023-02-29"},
    ]})
    assert result == {"valid": False, "fields": [
        {"name": "email", "valid": True}, {"name": "date", "valid": False}]}


def test_invalid_request_fails_closed():
    with pytest.raises(ValueError):
        v.run({"operation": "form", "fields": []})
    with pytest.raises(ValueError):
        v.run({"operation": "missing", "value": "x"})


def test_huge_integers_are_compared_exactly_not_crashed():
    from validation_patterns import run
    bounds = {"minimum": 0, "maximum": 100}
    assert run({"operation": "range", "value": 10 ** 400, "options": bounds}) == {"valid": False}
    assert run({"operation": "range", "value": -(10 ** 400), "options": bounds}) == {"valid": False}
    assert run({"operation": "range", "value": 5, "options": {"minimum": 0, "maximum": 10 ** 400}}) == {"valid": True}
    assert run({"operation": "range", "value": True, "options": bounds}) == {"valid": False}
