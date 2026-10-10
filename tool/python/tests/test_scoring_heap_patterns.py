"""Scoring and heap behavior regressions."""
import importlib.util
from pathlib import Path
import pytest

path = Path(__file__).resolve().parents[1] / "scoring_heap_patterns.py"
spec = importlib.util.spec_from_file_location("scoring_heap_patterns", path)
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)


def test_tfidf_downweights_common_terms():
    scores = m.run({"operation": "tfidf", "documents": ["cat cat dog", "dog bird"]})
    assert scores[0]["cat"] > scores[0]["dog"]
    assert scores[1]["bird"] > scores[1]["dog"]


def test_empty_documents_and_empty_tokens():
    assert m.tfidf([]) == []
    assert m.tfidf(["", " "]) == [{}, {}]


def test_heap_preserves_duplicates_and_does_not_mutate_input():
    data = [4, 1, 2, 1]
    result = m.run({"operation": "minheap", "values": data, "pops": 3})
    assert result == {"popped": [1, 1, 2], "remaining_sorted": [4]}
    assert data == [4, 1, 2, 1]


@pytest.mark.parametrize("payload", [
    {"operation": "tfidf", "documents": ["ok", 2]},
    {"operation": "minheap", "values": [1, float("nan")]},
    {"operation": "minheap", "values": [1], "pops": True},
    {"operation": "minheap", "values": [1], "pops": 2},
    {"operation": "minheap", "values": [], "extra": 1},
])
def test_bad_requests_fail_closed(payload):
    with pytest.raises(ValueError):
        m.run(payload)
