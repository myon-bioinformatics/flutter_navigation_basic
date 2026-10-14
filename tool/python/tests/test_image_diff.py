"""image_diff: pixel comparison of screenshots (files and zip members), clip scaling, exit codes."""
import importlib.util
from pathlib import Path
import subprocess
import sys
import zipfile

import pytest

Image = pytest.importorskip("PIL.Image")

SCRIPT = Path(__file__).resolve().parents[1] / "image_diff.py"
spec = importlib.util.spec_from_file_location("image_diff", SCRIPT)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


def pair(tmp_path, size=(200, 100), scale=1):
    a = Image.new("RGB", size, "white")
    b = a.copy()
    for x in range(20 * scale, 30 * scale):
        for y in range(10 * scale, 15 * scale):
            b.putpixel((x, y), (255, 0, 0))
    a.save(tmp_path / "a.png")
    b.save(tmp_path / "b.png")
    return tmp_path / "a.png", tmp_path / "b.png"


def test_reports_changed_pixels_and_bbox(tmp_path):
    a, b = pair(tmp_path)
    result = module.compare(module.load(str(a)), module.load(str(b)))
    assert result["changed"] == 50 and result["bbox"] == (20, 10, 30, 15) and result["differs"]


def test_clip_outside_the_change_is_identical_and_scales_with_dpr(tmp_path):
    a, b = pair(tmp_path, size=(400, 200), scale=2)  # taken at devicePixelRatio 2, viewport 200 css px wide
    ia, ib = module.load(str(a)), module.load(str(b))
    outside = module.compare(ia, ib, clip=(0, 0, 10, 10), viewport_width=200)
    inside = module.compare(ia, ib, clip=(15, 5, 20, 15), viewport_width=200)
    assert not outside["differs"] and outside["size"] == (20, 20)
    assert inside["differs"] and inside["changed"] == 200


def test_tolerance_and_size_mismatch(tmp_path):
    a, b = pair(tmp_path)
    assert not module.compare(module.load(str(a)), module.load(str(b)), tolerance=255)["differs"]
    small = Image.new("RGB", (10, 10), "white")
    small.save(tmp_path / "s.png")
    assert module.compare(module.load(str(a)), module.load(str(tmp_path / "s.png")))["same_size"] is False


def test_cli_zip_member_and_exit_codes(tmp_path):
    a, b = pair(tmp_path)
    with zipfile.ZipFile(tmp_path / "e.zip", "w") as z:
        z.write(b, "t/b.png")
    run = lambda *args: subprocess.run([sys.executable, str(SCRIPT), *args], capture_output=True, text=True)
    assert run(str(a), f"{tmp_path / 'e.zip'}::t/b.png").returncode == 1
    assert run(str(a), str(a)).returncode == 0
    missing = run(str(a), str(tmp_path / "nope.png"))
    assert missing.returncode == 2 and "nope.png" in missing.stderr
