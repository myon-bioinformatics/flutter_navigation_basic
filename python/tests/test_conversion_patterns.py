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


def test_compact_dates_keep_four_digit_years_and_round_trip():
    assert m.run({"operation":"date","source":"iso","target":"compact","value":"0999-01-01"}) == {"value":"09990101"}
    assert m.run({"operation":"date","source":"compact","target":"compact","value":"09990101"}) == {"value":"09990101"}


@pytest.mark.parametrize("value", ["2026-W01-1", "20260101", "2026-1-01"])
def test_iso_source_accepts_only_extended_calendar_dates(value):
    with pytest.raises(ValueError):
        m.run({"operation":"date","source":"iso","value":value})


@pytest.mark.parametrize(("value", "keep"), [("1234", 4), ("12", 4), ("x", 1)])
def test_values_not_longer_than_the_suffix_are_fully_masked(value, keep):
    assert m.run({"operation":"mask","value":value,"keep_last":keep}) == {"value":"*" * len(value)}


def test_float_accepts_plain_ascii_notation():
    for value, expected in (("-1.5e3", -1500.0), (".5", 0.5), ("2.", 2.0), (3, 3.0)):
        assert m.run({"operation":"coerce","target":"float","value":value}) == {"value":expected}


@pytest.mark.parametrize("payload", [
    {"operation":"coerce","target":"float","value":"1_000"},
    {"operation":"coerce","target":"float","value":" 1.5"},
    {"operation":"coerce","target":"float","value":"\u0661\u0662"},
    {"operation":"coerce","target":"float","value":10 ** 400},
    {"operation":"coerce","target":"bool","value":1.0},
    {"operation":"coerce","target":"bool","value":0.0},
])
def test_lenient_or_overflowing_coercions_fail_closed(payload):
    with pytest.raises(ValueError):
        m.run(payload)


def test_unit_conversion_overflow_fails_closed():
    # finite input can still overflow after applying a conversion factor.
    with pytest.raises(ValueError, match="overflow"):
        m.run({"operation":"unit","from":"km","to":"cm","value":1e308})


def test_unit_conversion_rejects_integers_too_large_for_float():
    with pytest.raises(ValueError):
        m.run({"operation":"unit","from":"km","to":"m","value":10 ** 400})



# Boundary behaviour pinned as contract (review N14-N17).
@pytest.mark.parametrize(("payload", "message"), [
    ({"operation":"encoding","mode":"base64_to_utf8","value":"YQ"}, "invalid base64 utf8"),       # no padding
    ({"operation":"encoding","mode":"base64_to_utf8","value":"YQ==="}, "invalid base64 utf8"),
    ({"operation":"encoding","mode":"base64_to_utf8","value":"-_-_"}, "invalid base64 utf8"),     # urlsafe alphabet
    ({"operation":"encoding","mode":"base64_to_utf8","value":"/w=="}, "invalid base64 utf8"),     # not UTF-8
    ({"operation":"encoding","mode":"utf8_to_base64","value":"\ud800"}, "invalid utf8 input"),
    ({"operation":"coerce","target":"int","value":"0x10"}, "invalid integer"),
    ({"operation":"coerce","target":"int","value":"9" * 5000}, "invalid integer"),               # CPython digit cap
    ({"operation":"date","source":"iso","value":"2100-02-29"}, "invalid iso date"),
    ({"operation":"date","source":"iso","value":"0000-01-01"}, "invalid iso date"),
    ({"operation":"date","source":"iso","value":"2024-13-01"}, "invalid iso date"),
    ({"operation":"date","source":"compact","value":"21000229"}, "invalid compact date"),
    ({"operation":"date","source":"compact","value":"00000101"}, "invalid compact date"),
    ({"operation":"date","source":"compact","value":"20241301"}, "invalid compact date"),
    ({"operation":"unit","from":"km","to":"cm","value":-1e306}, "unit conversion overflow"),
    ({"operation":"unit","from":"cm","to":"km","value":5e-324}, "unit conversion underflow"),
])
def test_boundaries_fail_closed_with_stable_messages(payload, message):
    with pytest.raises(ValueError) as error:
        m.run(payload)
    assert str(error.value) == message


@pytest.mark.parametrize(("payload", "expected"), [
    ({"operation":"coerce","target":"int","value":"007"}, 7),
    ({"operation":"encoding","mode":"base64_to_utf8","value":"YQ=="}, "a"),
    ({"operation":"date","source":"compact","target":"compact","value":"00010101"}, "00010101"),
    ({"operation":"unit","from":"cm","to":"km","value":0}, 0.0),
    # Code-point masking: a ZWJ emoji sequence is split, and length stays visible.
    ({"operation":"mask","keep_last":2,"value":"\U0001F468\u200d\U0001F469\u200d\U0001F467x"},
     "****\U0001F467x"),
])
def test_boundaries_that_are_accepted(payload, expected):
    assert m.run(payload) == {"value": expected}


def test_cli_reports_malformed_json_with_a_fixed_message(monkeypatch, capsys):
    import io
    monkeypatch.setattr(m.sys, "stdin", io.StringIO("{bad"))
    assert m.main() == 2
    assert capsys.readouterr().err.strip() == "invalid conversion request: invalid json"
