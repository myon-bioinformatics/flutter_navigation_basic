import tempfile
from pathlib import Path

from pattern_stub_audit import audit


PLACEHOLDER = """// TODO: 実装を追加してください
await Future.delayed(const Duration(milliseconds: 100));
return Pattern001Result(message: 'HttpGet executed successfully');
"""


def _service(root: Path, pattern: str) -> Path:
    path = root / "lib/features/api_patterns/pattern_001_to_099" / pattern / "service.dart"
    path.parent.mkdir(parents=True, exist_ok=True)
    return path


def test_detects_only_full_placeholder_signature():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        _service(root, "pattern_001").write_text(PLACEHOLDER, encoding="utf-8")
        _service(root, "pattern_002").write_text(
            "return Pattern002Result(message: 'implemented');\n",
            encoding="utf-8",
        )
        result = audit(root)
    assert result["api_patterns"] == [
        "lib/features/api_patterns/pattern_001_to_099/pattern_001/service.dart"
    ]


def test_partial_markers_are_not_reported():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        _service(root, "pattern_001").write_text(
            "// TODO: 実装を追加してください\n"
            "return Pattern001Result(message: 'executed successfully');\n",
            encoding="utf-8",
        )
        assert audit(root)["api_patterns"] == []


def test_non_utf8_service_does_not_abort_audit():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        _service(root, "pattern_001").write_bytes(b"\xff\xfe\x00")
        _service(root, "pattern_002").write_text(PLACEHOLDER, encoding="utf-8")
        result = audit(root)
    assert result["api_patterns"] == [
        "lib/features/api_patterns/pattern_001_to_099/pattern_002/service.dart"
    ]
