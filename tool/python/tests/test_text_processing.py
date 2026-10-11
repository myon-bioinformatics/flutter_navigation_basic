import importlib.util
import json
from pathlib import Path
import subprocess
import sys

import pytest

ROOT = Path(__file__).resolve().parents[3]
SCRIPT = ROOT / "tool/python/text_processing.py"
spec = importlib.util.spec_from_file_location("text_processing", SCRIPT)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)


def test_tokenize_and_stop_words_are_deterministic():
    assert module.tokenize("Python, FLUTTER 2!") == ["python", "flutter", "2"]
    assert module.without_stop_words(["python", "and", "flutter"]) == ["python", "flutter"]


def test_inverted_index_and_search_share_one_index_contract():
    index = module.build_inverted_index(module.DOCUMENTS)
    assert index["portable"] == ["doc-1", "doc-2"]
    assert index["search"] == ["doc-2", "doc-3"]
    assert module.search(module.DOCUMENTS, "portable search") == ["doc-2"]
    assert module.search(module.DOCUMENTS, "the and") == []


def test_invalid_input_fails_closed():
    with pytest.raises(TypeError):
        module.tokenize(None)
    with pytest.raises(ValueError):
        module.build_inverted_index([{"id": "", "text": "x"}])


def test_checked_in_text_assets_are_exact_cli_outputs():
    mapping = {
        "search": "search_basic.json",
        "tokens": "stop_word.json",
        "text-index": "text_index.json",
        "inverted-index": "inverted_index.json",
    }
    for mode, name in mapping.items():
        path = ROOT / "assets/data_processing" / name
        result = subprocess.run(
            [sys.executable, "-I", "-S", str(SCRIPT), "--mode", mode,
             "--output", str(path), "--check"],
            capture_output=True, text=True, timeout=5,
        )
        assert result.returncode == 0, (mode, result.stdout, result.stderr)
        payload = json.loads(path.read_text(encoding="utf-8"))
        assert payload["schema"] == "text-processing/1"
        assert payload["mode"] == mode


def test_text_patterns_share_asset_boundary_without_getx():
    mapping = {
        "005": "search_basic.json",
        "019": "text_index.json",
        "020": "inverted_index.json",
        "024": "stop_word.json",
    }
    root = ROOT / "lib/features/data_processing_patterns/pattern_001_to_099"
    for pattern, asset in mapping.items():
        folder = root / f"pattern_{pattern}"
        service = (folder / "service.dart").read_text(encoding="utf-8")
        view = (folder / "view.dart").read_text(encoding="utf-8")
        assert asset in service and "JsonListAsset" in service
        assert "ProcessedListExample" in view and "get/get.dart" not in view
        assert not (folder / "model.dart").exists()
        assert not (folder / "controller.dart").exists()
