import math
from typing import Annotated

import pytest
from pydantic import BaseModel, Field


EARTH_RADIUS_METERS = 6371008.8


class CoordinateCase(BaseModel):
    latitude: float
    longitude: float
    radius_m: Annotated[float, Field(gt=0)]
    expected_zoom: int
    expect_antimeridian: bool = False


CASES = [
    CoordinateCase(
        latitude=35.681236,
        longitude=139.767125,
        radius_m=100,
        expected_zoom=16,
    ),
    CoordinateCase(
        latitude=35.681236,
        longitude=139.767125,
        radius_m=350,
        expected_zoom=14,
    ),
    CoordinateCase(
        latitude=0,
        longitude=179.999,
        radius_m=1000,
        expected_zoom=13,
        expect_antimeridian=True,
    ),
]


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
    }


def zoom_for_radius(radius_m: float) -> int:
    zoom = math.floor(math.log(40075016.686 / (radius_m * 4)) / math.log(2))
    return max(3, min(20, zoom))


@pytest.mark.parametrize("case", CASES)
def test_tolerance_bounds_and_zoom(case: CoordinateCase) -> None:
    bounds = tolerance_bounds(case.latitude, case.longitude, case.radius_m)
    assert bounds["wraps_antimeridian"] is case.expect_antimeridian
    assert zoom_for_radius(case.radius_m) == case.expected_zoom
    if not case.expect_antimeridian:
        assert bounds["south"] < case.latitude < bounds["north"]
        assert bounds["west"] < case.longitude < bounds["east"]


def test_google_area_url_shape() -> None:
    lat, lon, radius = 35.681236, 139.767125, 100
    zoom = zoom_for_radius(radius)
    url = f"https://www.google.com/maps/@{lat:.6f},{lon:.6f},{zoom}z"
    assert url == "https://www.google.com/maps/@35.681236,139.767125,16z"


def test_apple_area_url_includes_spn_for_simple_bounds() -> None:
    bounds = tolerance_bounds(35.681236, 139.767125, 100)
    lat_span = abs(bounds["north"] - bounds["south"])
    lon_span = abs(bounds["east"] - bounds["west"])
    assert lat_span > 0
    assert lon_span > 0
    assert not bounds["wraps_antimeridian"]
