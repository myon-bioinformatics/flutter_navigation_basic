import importlib.util
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[3]
SCRIPT = ROOT / "tool/python/list_ordering.py"

spec = importlib.util.spec_from_file_location("list_ordering", SCRIPT)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)


def test_basic_and_reverse_ordering():
    assert module.order_values("basic", [9, 2, 5, 1, 3]) == [1, 2, 3, 5, 9]
    assert module.order_values("reverse", [9, 2, 5, 1, 3]) == [9, 5, 3, 2, 1]


def test_multi_key_ordering_is_group_ascending_score_descending():
    values = module.payload("multi")["values"]
    assert [(v["group"], v["score"]) for v in values] == [
        ("a", 3), ("a", 1), ("b", 2), ("b", 1),
    ]


def test_invalid_shapes_fail_closed():
    import pytest
    with pytest.raises(ValueError):
        module.order_values("basic", [True, 1])
    with pytest.raises(ValueError):
        module.order_values("multi", [{"group": "a", "score": True}])


def test_checked_in_assets_are_exact_cli_outputs(tmp_path):
    mapping = {
        "basic": "sort_basic.json",
        "multi": "sort_multi_key.json",
        "reverse": "sort_reverse.json",
    }
    for mode, name in mapping.items():
        expected = ROOT / "assets/data_processing" / name
        result = subprocess.run(
            [sys.executable, "-I", "-S", str(SCRIPT), "--mode", mode,
             "--output", str(expected), "--check"],
            capture_output=True, text=True, timeout=5,
        )
        assert result.returncode == 0, (mode, result.stdout, result.stderr)
        data = json.loads(expected.read_text(encoding="utf-8"))
        assert data["schema"] == "list-ordering/1"
        assert data["mode"] == mode


def test_three_sort_patterns_use_shared_asset_boundary_without_getx():
    for pattern, asset in [("009", "sort_basic.json"), ("010", "sort_multi_key.json"),
                           ("013", "sort_reverse.json")]:
        folder = ROOT / "lib/features/data_processing_patterns/pattern_001_to_099" / f"pattern_{pattern}"
        service = (folder / "service.dart").read_text(encoding="utf-8")
        view = (folder / "view.dart").read_text(encoding="utf-8")
        assert asset in service
        assert "JsonListAsset" in service
        assert "ProcessedListExample" in view
        assert "get/get.dart" not in view
        assert not (folder / "model.dart").exists()
        assert not (folder / "controller.dart").exists()
