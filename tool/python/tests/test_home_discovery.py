"""Regression for Python owned Home selections and committed Flutter asset."""
import importlib.util
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
SRC = ROOT / "tool" / "python" / "home_discovery.py"
SPEC = importlib.util.spec_from_file_location("home_discovery_generator", SRC)
module = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(module)


def test_generated_asset_is_current_and_valid():
    actual = (ROOT / "assets" / "home_discovery_draws.json").read_text(encoding="utf-8")
    assert actual == module.render(), "Run python tool/python/home_discovery.py and commit output"
    payload = json.loads(actual)
    assert payload["schema"] == 1
    assert len(payload["draws"]) == 64
    for triple in payload["draws"]:
        assert len(triple) == len(set(triple)) == 3
        assert all(6 <= screen_id <= 198 for screen_id in triple)
    assert len({tuple(triple) for triple in payload["draws"]}) == 64
    flat = [screen_id for triple in payload["draws"] for screen_id in triple]
    assert len(flat) == len(set(flat)) == 192
    assert set(flat).issubset(set(range(6, 199)))


def test_flutter_consumes_python_generated_asset():
    source = (ROOT / "lib" / "features" / "home" / "presentation" / "home_screen.dart").read_text(encoding="utf-8")
    pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
    assert "assets/home_discovery_draws.json" in source
    assert "assets/home_discovery_draws.json" in pubspec
    assert "pickHomeDiscoveryScreens(" in source
    assert "random: widget.discoveryRandom" in source
    assert "_draws = draws" in source
    assert "void _refresh()" in source
    assert "_reshuffle();" in source
