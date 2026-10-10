"""Full inventory status report must not silently drop catalogue IDs."""
import importlib.util
from pathlib import Path
import pytest

SCRIPT = Path(__file__).resolve().parents[1] / "render_pattern_status.py"
spec = importlib.util.spec_from_file_location("render_pattern_status", SCRIPT)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


def fixture():
    rows = [
        {"id": n, "name": f"Example {n}", "status": "description_only",
         "target_owner": "python", "dart_files": ["view.dart"],
         "producer": None} for n in range(1, 199)
    ]
    return {"schema": "pattern-responsibility/1",
            "summary": {"dart_files": 198, "errors": 0},
            "patterns": rows}


def test_renders_all_198_rows_with_explicit_noncompletion():
    content = module.render(fixture(), "a" * 40)
    assert content.count("| 未実装（実機能未確認） |") == 198
    assert "| 001 |" in content and "| 198 |" in content
    assert "完全実装" in content


def test_rejects_missing_or_duplicate_id():
    data = fixture()
    data["patterns"].pop()
    with pytest.raises(ValueError):
        module.render(data, "a" * 40)
    data = fixture()
    data["patterns"][0]["id"] = 2
    with pytest.raises(ValueError):
        module.render(data, "a" * 40)
