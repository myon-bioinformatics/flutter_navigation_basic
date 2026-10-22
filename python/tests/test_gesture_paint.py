from __future__ import annotations

import importlib.util
from pathlib import Path
import sys

import pytest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "python"))
from gesture_paint import check_swap  # noqa: E402

spec = importlib.util.spec_from_file_location(
    "gesture_pillow_min", ROOT / "python/vendor/pillow_min/pillow_min.py")
backend = importlib.util.module_from_spec(spec)
spec.loader.exec_module(backend)


def example(scale=1):
    before = backend.Image.new("RGBA", (80 * scale, 40 * scale), (250, 250, 250, 255))
    after = before.copy()
    for x in range(10 * scale, 30 * scale):
        for y in range(10 * scale, 30 * scale):
            before.putpixel((x, y), (20, 30, 40, 255))
            before.putpixel((x + 40 * scale, y), (100, 110, 120, 255))
            after.putpixel((x, y), (100, 110, 120, 255))
            after.putpixel((x + 40 * scale, y), (20, 30, 40, 255))
    geometry = {"device_scale_factor": scale, "viewport": {"width": 80, "height": 40},
                "slots": [{"x": x, "y": 0, "width": 40, "height": 40} for x in (0, 40)]}
    return before, after, geometry


@pytest.mark.parametrize("scale", [1, 3])
def test_exact_swap_uses_saved_pixels_at_recorded_scale(scale):
    before, after, geometry = example(scale)
    result = check_swap(before, after, geometry)
    assert result["matches"]
    assert all(item["changed"] == 0 for item in result["comparisons"])


def test_stable_but_stale_capture_is_rejected():
    before, _, geometry = example()
    assert not check_swap(before, before.copy(), geometry)["matches"]


def test_drag_feedback_or_single_changed_pixel_is_rejected():
    before, after, geometry = example()
    after.putpixel((20, 20), (101, 110, 120, 255))
    result = check_swap(before, after, geometry)
    assert not result["matches"]
    assert result["comparisons"][0]["changed"] == 1


def test_blank_reference_cannot_validate_a_blank_result():
    _, _, geometry = example()
    blank = backend.Image.new("RGBA", (80, 40), (250, 250, 250, 255))
    with pytest.raises(ValueError, match="identical"):
        check_swap(blank, blank, geometry)


@pytest.mark.parametrize("scale", [0, -1, float("nan"), float("inf")])
def test_invalid_scale_is_rejected(scale):
    before, after, geometry = example()
    geometry["device_scale_factor"] = scale
    with pytest.raises(ValueError, match="scale"):
        check_swap(before, after, geometry)


def test_capture_or_viewport_size_changes_are_rejected():
    before, after, geometry = example()
    with pytest.raises(ValueError, match="dimensions changed"):
        check_swap(before, after.crop((0, 0, 70, 40)), geometry)
    geometry["viewport"]["width"] = 60
    with pytest.raises(ValueError, match="viewport"):
        check_swap(before, after, geometry)


@pytest.mark.parametrize("change, message", [
    ({"x": -20}, "outside"), ({"width": 15}, "too small"),
    ({"y": float("nan")}, "invalid card"), ({"width": 39}, "different pixel"),
])
def test_invalid_crops_are_rejected(change, message):
    before, after, geometry = example()
    geometry["slots"][0].update(change)
    with pytest.raises(ValueError, match=message):
        check_swap(before, after, geometry)
