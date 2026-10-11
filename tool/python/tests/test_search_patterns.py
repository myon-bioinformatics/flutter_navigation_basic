"""Search helper behavior and invalid input contracts."""
import importlib.util
from pathlib import Path
import pytest

path = Path(__file__).resolve().parents[1] / "search_patterns.py"
spec = importlib.util.spec_from_file_location("search_patterns", path)
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)


def test_fuzzy_ranks_matches_and_normalizes():
    assert m.run({"operation": "fuzzy", "query": "cat", "values": ["cut", "dog", "cat"], "max_distance": 1}) == ["cat", "cut"]
    assert m.run({"operation": "autocomplete", "query": "Ａ", "values": ["apple", "banana"]}) == ["apple"]


def test_history_deduplicates_most_recent():
    assert m.run({"operation": "history", "events": ["Cat", "dog", "cat"]}) == ["cat", "dog"]


def test_highlight_does_not_claim_invalid_unicode_offsets():
    assert m.run({"operation": "highlight", "query": "Ａ", "text": "a"}) == {"matched": True, "text": "a"}


def test_tokenize_and_limited_stem():
    assert m.run({"operation": "tokenize", "text": "Hello, WORLD!"}) == ["hello", "world"]
    assert m.run({"operation": "stem", "text": "playing cats"}) == ["play", "cat"]


@pytest.mark.parametrize("payload", [
    {"operation": "fuzzy", "query": "x", "values": [1]},
    {"operation": "fuzzy", "query": "x", "values": ["x"], "max_distance": -1},
    {"operation": "autocomplete", "query": "x", "values": [], "limit": True},
    {"operation": "history", "events": [None]},
    {"operation": "highlight", "query": "", "text": "abc"},
])
def test_invalid_inputs_rejected(payload):
    with pytest.raises(ValueError):
        m.run(payload)
