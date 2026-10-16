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


def _convert(tmp_path, events):
    src, dst = tmp_path / "events.jsonl", tmp_path / "result.xml"
    src.write_text("\n".join(json.dumps(e) for e in events), encoding="utf-8")
    module.convert(src, dst)
    return ET.parse(dst).getroot().findall("testcase")


def _suite(sid, path):
    return {"type": "suite", "suite": {"id": sid, "path": path}}


def _case(tid, sid, name, result="success", **done):
    return [{"type": "testStart", "test": {"id": tid, "suiteID": sid, "name": name}},
            {"type": "testDone", "testID": tid, "result": result, **done}]


def test_protocol_skip_hidden_and_suite_identity(tmp_path):
    events = [_suite(0, "test/a_test.dart"), _suite(1, "test/b_test.dart"),
              *_case(1, 0, "loading test/a_test.dart", hidden=True),
              *_case(2, 0, "same name"), *_case(3, 1, "same name"),
              {"type": "testStart", "test": {"id": 4, "suiteID": 1, "name": "skip me",
                                             "metadata": {"skipReason": "known: gap"}}},
              {"type": "testDone", "testID": 4, "result": "success", "skipped": True},
              {"type": "done", "success": True}]
    cases = _convert(tmp_path, events)
    assert [(c.get("classname"), c.get("name")) for c in cases] == [
        ("test/a_test.dart", "same name"), ("test/b_test.dart", "same name"),
        ("test/b_test.dart", "skip me")]
    assert cases[2].find("skipped").get("message") == "known: gap"
    assert all(c.find("skipped") is None for c in cases[:2])


def test_failed_load_stays_visible(tmp_path):
    events = [_suite(0, "test/broken_test.dart"),
              {"type": "testStart", "test": {"id": 1, "suiteID": 0,
                                             "name": "loading test/broken_test.dart"}},
              {"type": "error", "testID": 1, "error": "Compilation failed"},
              {"type": "testDone", "testID": 1, "result": "error", "hidden": False},
              {"type": "done", "success": False}]
    cases = _convert(tmp_path, events)
    assert len(cases) == 1 and "Compilation failed" in cases[0].find("error").text


def test_only_hidden_tests_rejected(tmp_path):
    src = tmp_path / "events.jsonl"
    events = [*_case(1, 0, "loading x", hidden=True), {"type": "done", "success": True}]
    src.write_text("\n".join(json.dumps(e) for e in events), encoding="utf-8")
    with pytest.raises(ValueError):
        module.convert(src, tmp_path / "result.xml")


def test_incomplete_flutter_events_rejected(tmp_path):
    src = tmp_path / "events.jsonl"
    src.write_text(json.dumps({"type": "testStart", "test": {"id": 1, "name": "x"}}),
                   encoding="utf-8")
    with pytest.raises(ValueError):
        module.convert(src, tmp_path / "result.xml")
