"""Contracts for data conversion patterns 103-105, 107, 109-110."""
import importlib.util
from pathlib import Path
import pytest

p = Path(__file__).resolve().parents[1] / "conversion_patterns.py"
spec = importlib.util.spec_from_file_location("conversion_patterns", p)
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)


def test_normalize_and_case():
    assert m.run({"operation":"normalize","value":" Ａbc ","case":"lower"}) == {"value":"abc"}


@pytest.mark.parametrize(("target","value","expected"), [
    ("int","-12",-12), ("float","1.5",1.5), ("bool","true",True), ("bool","0",False)])
def test_safe_coercion(target,value,expected):
    assert m.run({"operation":"coerce","target":target,"value":value}) == {"value":expected}


def test_date_conversion_checks_calendar():
    assert m.run({"operation":"date","source":"compact","target":"iso","value":"20240229"}) == {"value":"2024-02-29"}
    with pytest.raises(ValueError):
        m.run({"operation":"date","source":"iso","value":"2023-02-29"})


def test_unit_conversion_rejects_dimensions():
    assert m.run({"operation":"unit","from":"km","to":"m","value":1.2}) == {"value":1200.0}
    with pytest.raises(ValueError):
        m.run({"operation":"unit","from":"kg","to":"m","value":1})


def test_encoding_round_trip_and_invalid_data():
    encoded = m.run({"operation":"encoding","mode":"utf8_to_base64","value":"日本語"})["value"]
    assert m.run({"operation":"encoding","mode":"base64_to_utf8","value":encoded}) == {"value":"日本語"}
    with pytest.raises(ValueError):
        m.run({"operation":"encoding","mode":"base64_to_utf8","value":"%%%"})


def test_masking_keeps_requested_suffix():
    assert m.run({"operation":"mask","value":"1234567890","keep_last":4}) == {"value":"******7890"}


@pytest.mark.parametrize("payload", [
    {"operation":"coerce","target":"int","value":"1.2"},
    {"operation":"coerce","target":"float","value":"nan"},
    {"operation":"normalize","value":1},
    {"operation":"mask","value":"secret","keep_last":-1},
])
def test_invalid_requests_fail_closed(payload):
    with pytest.raises(ValueError):
        m.run(payload)
