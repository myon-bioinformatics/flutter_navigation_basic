"""Keep the JSON shipped to Flutter in sync with its collection producers."""

import json
from pathlib import Path
import subprocess
import sys

import pytest

ROOT = Path(__file__).resolve().parents[3]
ASSETS = ROOT / "assets/data_processing"

# These recipes are independent of the saved JSON, so changing an asset's mode
# cannot silently select a different producer invocation and make the test pass.
# A command of None means that the structure producer has no --command option.
ASSET_RECIPES = {
    "window_034.json": ("collection_window.py", "load-more", "load-more"),
    "window_036.json": ("collection_window.py", "lazy-list", "next"),
    "window_037.json": ("collection_window.py", "load-more", "refresh"),
    "window_038.json": ("collection_window.py", "prefetch", "prefetch"),
    "window_039.json": ("collection_window.py", "page-indicator", "next"),
    "window_040.json": ("collection_window.py", "page-size", "page-size-3"),
    "window_041.json": ("collection_window.py", "offset-limit", "offset-6"),
    "window_042.json": ("collection_window.py", "keyset", "next"),
    "window_043.json": ("collection_window.py", "window", "next"),
    "window_044.json": ("collection_window.py", "bidirectional", "next"),
    "structure_045.json": ("collection_structure.py", "sticky", None),
    "structure_046.json": ("collection_structure.py", "section", None),
    "structure_047.json": ("collection_structure.py", "tree", None),
    "structure_048.json": ("collection_structure.py", "flat", None),
    "structure_049.json": ("collection_structure.py", "grouped", None),
    "command_051.json": ("collection_window.py", "selectable", "select"),
    "command_052.json": ("collection_window.py", "swipe-delete", "delete"),
    "command_053.json": ("collection_window.py", "reorderable", "move-first"),
    "command_054.json": ("collection_window.py", "checklist", "toggle"),
}


def test_collection_asset_recipes_cover_saved_assets():
    saved_assets = {
        asset.name
        for pattern in ("window_*.json", "structure_*.json", "command_*.json")
        for asset in ASSETS.glob(pattern)
    }
    assert set(ASSET_RECIPES) == saved_assets


def normalized_json(value):
    # Parsed dict equality conflates False/0 and True/1. JSON serialization
    # preserves value types and array order while ignoring object key order.
    return json.dumps(value, ensure_ascii=False, sort_keys=True, indent=2, allow_nan=False)


@pytest.mark.parametrize("asset_name", ASSET_RECIPES)
def test_checked_in_asset_matches_collection_cli(asset_name):
    script, mode, command = ASSET_RECIPES[asset_name]
    args = [sys.executable, "-I", "-S", str(ROOT / "tool/python" / script), "--mode", mode]
    if command is not None:
        args.extend(["--command", command])
    result = subprocess.run(
        args, capture_output=True, encoding="utf-8", timeout=5,
    )
    assert result.returncode == 0, (result.stdout, result.stderr)
    generated = json.loads(result.stdout)
    saved = json.loads((ASSETS / asset_name).read_text(encoding="utf-8"))
    assert normalized_json(saved) == normalized_json(generated)
