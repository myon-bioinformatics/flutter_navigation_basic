"""Photo-studio geometry oracle (midpoints, circle, triangle, intersections).

Dart `StudioGeometry` mirrors these helpers so UI math and pytest stay aligned.
"""

from __future__ import annotations

import json
import math
from pathlib import Path

import pytest
from pydantic import BaseModel


FIXTURE_PATH = (
    Path(__file__).resolve().parents[1] / "fixtures" / "photo_studio_geometry_cases.json"
)


class Point(BaseModel):
    x: float
    y: float


class Bounds(BaseModel):
    left: float
    top: float
    right: float
    bottom: float


class GeometryCase(BaseModel):
    photoStudioGeometryCaseId: str
    bounds: Bounds
    expected_rect_midpoints: list[Point]
    expected_circle: dict[str, float]
    expected_triangle_vertices: list[Point]
    expected_triangle_midpoints: list[Point]
    expected_crossing: Point | None = None


def midpoint(x0: float, y0: float, x1: float, y1: float) -> Point:
    return Point(x=(x0 + x1) / 2, y=(y0 + y1) / 2)


def rectangle_edge_midpoints(b: Bounds) -> list[Point]:
    return [
        midpoint(b.left, b.top, b.right, b.top),
        midpoint(b.right, b.top, b.right, b.bottom),
        midpoint(b.left, b.bottom, b.right, b.bottom),
        midpoint(b.left, b.top, b.left, b.bottom),
    ]


def circle_from_bounds(b: Bounds) -> dict[str, float]:
    return {
        "cx": (b.left + b.right) / 2,
        "cy": (b.top + b.bottom) / 2,
        "radius": min(b.right - b.left, b.bottom - b.top) / 2,
    }


def triangle_vertices(b: Bounds) -> list[Point]:
    apex_x = (b.left + b.right) / 2
    return [
        Point(x=apex_x, y=b.top),
        Point(x=b.right, y=b.bottom),
        Point(x=b.left, y=b.bottom),
    ]


def triangle_edge_midpoints(b: Bounds) -> list[Point]:
    v = triangle_vertices(b)
    return [
        midpoint(v[0].x, v[0].y, v[1].x, v[1].y),
        midpoint(v[1].x, v[1].y, v[2].x, v[2].y),
        midpoint(v[2].x, v[2].y, v[0].x, v[0].y),
    ]


def segment_intersection(
    ax: float,
    ay: float,
    bx: float,
    by: float,
    cx: float,
    cy: float,
    dx: float,
    dy: float,
) -> Point | None:
    rx, ry = bx - ax, by - ay
    sx, sy = dx - cx, dy - cy
    denom = rx * sy - ry * sx
    if abs(denom) < 1e-12:
        return None
    t = ((cx - ax) * sy - (cy - ay) * sx) / denom
    u = ((cx - ax) * ry - (cy - ay) * rx) / denom
    if t < 0 or t > 1 or u < 0 or u > 1:
        return None
    return Point(x=ax + t * rx, y=ay + t * ry)


def load_cases() -> list[GeometryCase]:
    payload = json.loads(FIXTURE_PATH.read_text(encoding="utf-8"))
    return [GeometryCase.model_validate(item) for item in payload["cases"]]


CASES = load_cases()


@pytest.mark.parametrize("case", CASES, ids=lambda c: c.photoStudioGeometryCaseId)
def test_rectangle_midpoints(case: GeometryCase) -> None:
    got = rectangle_edge_midpoints(case.bounds)
    for actual, expected in zip(got, case.expected_rect_midpoints, strict=True):
        assert actual.x == pytest.approx(expected.x)
        assert actual.y == pytest.approx(expected.y)


@pytest.mark.parametrize("case", CASES, ids=lambda c: c.photoStudioGeometryCaseId)
def test_circle_from_bounds(case: GeometryCase) -> None:
    got = circle_from_bounds(case.bounds)
    for key, value in case.expected_circle.items():
        assert got[key] == pytest.approx(value)


@pytest.mark.parametrize("case", CASES, ids=lambda c: c.photoStudioGeometryCaseId)
def test_triangle_geometry(case: GeometryCase) -> None:
    verts = triangle_vertices(case.bounds)
    mids = triangle_edge_midpoints(case.bounds)
    for actual, expected in zip(verts, case.expected_triangle_vertices, strict=True):
        assert actual.x == pytest.approx(expected.x)
        assert actual.y == pytest.approx(expected.y)
    for actual, expected in zip(mids, case.expected_triangle_midpoints, strict=True):
        assert actual.x == pytest.approx(expected.x)
        assert actual.y == pytest.approx(expected.y)


@pytest.mark.parametrize("case", CASES, ids=lambda c: c.photoStudioGeometryCaseId)
def test_fixture_expected_crossing(case: GeometryCase) -> None:
    """When present, expected_crossing must match the bounds' diagonal intersection."""
    if case.expected_crossing is None:
        return
    b = case.bounds
    hit = segment_intersection(
        b.left,
        b.top,
        b.right,
        b.bottom,
        b.left,
        b.bottom,
        b.right,
        b.top,
    )
    assert hit is not None
    assert hit.x == pytest.approx(case.expected_crossing.x)
    assert hit.y == pytest.approx(case.expected_crossing.y)


def test_crossing_diagonals_intersect_at_center() -> None:
    hit = segment_intersection(0, 0, 1, 1, 0, 1, 1, 0)
    assert hit is not None
    assert hit.x == pytest.approx(0.5)
    assert hit.y == pytest.approx(0.5)


def test_parallel_segments_have_no_intersection() -> None:
    assert segment_intersection(0, 0, 1, 0, 0, 1, 1, 1) is None


def test_fixture_ids_are_unique() -> None:
    ids = [case.photoStudioGeometryCaseId for case in CASES]
    assert len(ids) == len(set(ids))
    assert not any(math.isnan(case.bounds.left) for case in CASES)
