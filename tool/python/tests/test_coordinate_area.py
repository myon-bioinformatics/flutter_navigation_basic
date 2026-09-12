import json
import math
from pathlib import Path

import pytest
from pydantic import BaseModel, Field


EARTH_RADIUS_METERS = 6371008.8
FIXTURE_PATH = Path(__file__).resolve().parents[1] / "fixtures" / "coordinate_area_cases.json"


class CoordinateCase(BaseModel):
    coordinateAreaCaseId: str
    latitude: float
    longitude: float
    radius_m: float = Field(gt=0)
    expected_zoom: int
    expect_antimeridian: bool = False
    expect_full_longitude: bool = False
    expect_apple_spn: bool = True


def load_cases() -> list[CoordinateCase]:
    payload = json.loads(FIXTURE_PATH.read_text(encoding="utf-8"))
    return [CoordinateCase.model_validate(case) for case in payload["cases"]]


CASES = load_cases()


def _to_radians(degrees: float) -> float:
    return degrees * math.pi / 180


def _to_degrees(radians: float) -> float:
    return radians * 180 / math.pi


def _normalize_longitude(longitude: float) -> float:
    value = longitude
    while value < -180:
        value += 360
    while value > 180:
        value -= 360
    return value


def tolerance_bounds(latitude: float, longitude: float, radius_m: float) -> dict:
    angular = radius_m / EARTH_RADIUS_METERS
    latitude_delta = _to_degrees(angular)
    south = max(-90.0, latitude - latitude_delta)
    north = min(90.0, latitude + latitude_delta)
    latitude_cosine = abs(math.cos(_to_radians(latitude)))

    if south <= -90 or north >= 90 or latitude_cosine < 1e-12:
        longitude_delta = 180.0
    else:
        longitude_delta = min(180.0, _to_degrees(angular / latitude_cosine))

    raw_west = longitude - longitude_delta
    raw_east = longitude + longitude_delta
    full_range = longitude_delta >= 180
    west = -180.0 if full_range else _normalize_longitude(raw_west)
    east = 180.0 if full_range else _normalize_longitude(raw_east)
    wraps = (not full_range) and (raw_west < -180 or raw_east > 180)
    return {
        "south": south,
        "west": west,
        "north": north,
        "east": east,
        "wraps_antimeridian": wraps,
        "spans_full_longitude": west == -180 and east == 180,
    }


def zoom_for_radius(radius_m: float, latitude: float = 0.0) -> int:
    cos_lat = max(1e-6, min(1.0, abs(math.cos(math.radians(latitude)))))
    circumference = 40075016.686 * cos_lat
    zoom = math.floor(math.log(circumference / (radius_m * 4)) / math.log(2))
    return max(3, min(20, zoom))


@pytest.mark.parametrize("case", CASES, ids=lambda case: case.coordinateAreaCaseId)
def test_tolerance_bounds_and_zoom(case: CoordinateCase) -> None:
    bounds = tolerance_bounds(case.latitude, case.longitude, case.radius_m)
    assert bounds["wraps_antimeridian"] is case.expect_antimeridian
    assert bounds["spans_full_longitude"] is case.expect_full_longitude
    assert zoom_for_radius(case.radius_m, case.latitude) == case.expected_zoom
    if case.expect_apple_spn:
        assert not bounds["wraps_antimeridian"]
        assert not bounds["spans_full_longitude"]
    else:
        assert bounds["wraps_antimeridian"] or bounds["spans_full_longitude"]


def test_google_area_url_shape_uses_latitude_aware_zoom() -> None:
    lat, lon, radius = 35.681236, 139.767125, 100
    zoom = zoom_for_radius(radius, lat)
    url = f"https://www.google.com/maps/@{lat:.6f},{lon:.6f},{zoom}z"
    assert url == "https://www.google.com/maps/@35.681236,139.767125,16z"


def test_high_latitude_zoom_is_lower_than_equator() -> None:
    radius = 100
    assert zoom_for_radius(radius, 80) < zoom_for_radius(radius, 0)
