"""Flutter machine reporter conversion regressions."""
import importlib.util
import json
from pathlib import Path
import xml.etree.ElementTree as ET
import pytest

SCRIPT = Path(__file__).resolve().parents[1] / "flutter_machine_junit.py"
spec = importlib.util.spec_from_file_location("flutter_machine_junit", SCRIPT)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


def test_flutter_events_preserve_per_case_failure(tmp_path):
    src, dst = tmp_path / "events.jsonl", tmp_path / "result.xml"
    events = [
        {"type": "testStart", "test": {"id": 1, "name": "passes"}},
        {"type": "testDone", "testID": 1, "result": "success"},
        {"type": "testStart", "test": {"id": 2, "name": "fails"}},
        {"type": "error", "testID": 2, "error": "expected true"},
        {"type": "testDone", "testID": 2, "result": "failure"},
        {"type": "done", "success": False},
    ]
    src.write_text("\n".join(json.dumps(e) for e in events), encoding="utf-8")
    assert module.convert(src, dst) == 2
    cases = ET.parse(dst).getroot().findall("testcase")
    assert [c.get("name") for c in cases] == ["passes", "fails"]
    assert cases[1].find("failure") is not None


def test_incomplete_flutter_events_rejected(tmp_path):
    src = tmp_path / "events.jsonl"
    src.write_text(json.dumps({"type": "testStart", "test": {"id": 1, "name": "x"}}),
                   encoding="utf-8")
    with pytest.raises(ValueError):
        module.convert(src, tmp_path / "result.xml")
