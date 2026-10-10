"""Contract tests for independent collection query operations."""
import importlib.util
from pathlib import Path
import pytest

p = Path(__file__).resolve().parents[1] / "collection_query_patterns.py"
spec = importlib.util.spec_from_file_location("collection_query_patterns", p)
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)


def test_stable_sort_preserves_tie_order():
    items = [{"rank": 2, "id": "a"}, {"rank": 1, "id": "b"}, {"rank": 2, "id": "c"}]
    assert [x["id"] for x in m.run({"operation": "stable_sort", "items": items, "key": "rank"})] == ["b", "a", "c"]
    assert [x["id"] for x in m.run({"operation": "custom_sort", "items": items, "key": "rank", "comparator": "descending"})] == ["a", "c", "b"]


def test_grouping_and_filters():
    items = [{"group": "a", "tags": ["x"], "score": 2},
             {"group": "b", "tags": ["y"], "score": 4},
             {"group": "a", "tags": ["x", "y"], "score": 6}]
    groups = m.run({"operation": "group_by", "items": items, "key": "group"})
    assert [len(g["items"]) for g in groups] == [2, 1]
    assert len(m.run({"operation": "facet", "items": items, "key": "group", "selected": ["a"]})) == 2
    assert len(m.run({"operation": "tag", "items": items, "key": "tags", "selected": ["y"]})) == 2
    assert len(m.run({"operation": "range", "items": items, "key": "score", "minimum": 3, "maximum": 5})) == 1


def test_geo_haversine():
    items = [{"latitude": 35.0, "longitude": 139.0},
             {"latitude": 40.0, "longitude": 139.0}]
    assert m.run({"operation": "geo", "items": items, "latitude": 35.0,
                  "longitude": 139.0, "radius_km": 10}) == items[:1]


@pytest.mark.parametrize("payload", [
    {"operation": "stable_sort", "items": [{"x": 1}, {"x": "2"}], "key": "x"},
    {"operation": "custom_sort", "items": [], "key": "x", "comparator": "eval"},
    {"operation": "range", "items": [], "key": "x", "minimum": 5, "maximum": 1},
    {"operation": "geo", "items": [], "latitude": 91, "longitude": 0, "radius_km": 1},
    {"operation": "tag", "items": [{"tags": "x"}], "key": "tags", "selected": ["x"]},
])
def test_invalid_inputs_fail_closed(payload):
    with pytest.raises(ValueError):
        m.run(payload)
