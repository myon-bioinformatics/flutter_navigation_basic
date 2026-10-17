"""No native SDK is needed to test orchestration; real captures are opt-in CI."""
import json
from pathlib import Path
import shutil
import sys

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import capture_native_errors as cli


def test_real_python_and_node_controls_without_native_install(tmp_path):
    root = Path(__file__).resolve().parents[2]
    targets = [("python", [sys.executable, "-S", str(root / "tools/native_error_corpus/array_length.py")]),
               ("node", ["node", str(root / "tools/native_error_corpus/array_length.mjs")])]
    for language, command in targets:
        for name, count in cli.CASES:
            record = cli.invoke(command, root, tmp_path, language + name,
                                payload=json.dumps({"count": count}).encode(), timeout=10)
            expected = {"error": "invalid_array_length"} if count < 0 else {"length": count}
            assert cli.classify(record, count, language) == expected
            assert (tmp_path / (language + name + ".stderr.log")).is_file()


def test_missing_tool_and_wrong_error_do_not_become_native_observations(tmp_path):
    record = cli.invoke(["no-such-capture-native-test-command"], tmp_path, tmp_path, "missing")
    assert "unavailable_or_supervision_error" in cli.classify(record, -1, "dart")
    record = {"returncode": 1, "error_type": None, "stdout": "", "stderr": "download failed"}
    assert "expected_error_missing" in cli.classify(record, -1, "dart")


def test_supervision_timeout_is_not_an_expected_language_error(tmp_path):
    record = cli.invoke([sys.executable, "-c", "import time; time.sleep(10)"],
                        tmp_path, tmp_path, "timeout", timeout=0.2)
    assert record["error_type"] == "TimeoutExpired"
    assert "unavailable_or_supervision_error" in cli.classify(record, -1, "swift")


def kotlin_xml():
    return '''<testsuite><testcase name="empty" classname="com.example.flutter_application_1.ArrayLengthProbeTest"/>
    <testcase name="three" classname="com.example.flutter_application_1.ArrayLengthProbeTest"/>
    <testcase name="negative" classname="com.example.flutter_application_1.ArrayLengthProbeTest">
    <failure type="java.lang.NegativeArraySizeException">-1</failure></testcase>
    <system-out>XPROBE_LENGTH_RESULT=0:0\nXPROBE_LENGTH_RESULT=3:3</system-out></testsuite>'''


def test_kotlin_reads_actual_lengths_and_actual_failure_type(tmp_path):
    path = tmp_path / "junit.xml"
    path.write_text(kotlin_xml(), encoding="utf-8")
    assert cli.kotlin_result(path) == {"empty": {"length": 0}, "three": {"length": 3},
                                       "negative": {"error": "invalid_array_length"}}
    path.write_text(kotlin_xml().replace("3:3", "3:2"), encoding="utf-8")
    assert cli.kotlin_result(path)["three"] == {"length": 2}  # no expected-answer substitution


@pytest.mark.parametrize("change", [
    lambda s: s.replace("java.lang.NegativeArraySizeException", "java.lang.AssertionError"),
    lambda s: s.replace("XPROBE_LENGTH_RESULT=3:3", ""),
    lambda s: s.replace('name="three"', 'name="different"'),
    lambda s: s.replace('name="empty" classname=', 'name="empty"><skipped/></testcase><testcase name="extra" classname='),
])
def test_kotlin_incomplete_or_wrong_failures_are_rejected(tmp_path, change):
    path = tmp_path / "junit.xml"
    path.write_text(change(kotlin_xml()), encoding="utf-8")
    with pytest.raises(ValueError):
        cli.kotlin_result(path)


def test_native_baseline_failure_still_measures_companions(monkeypatch, tmp_path):
    original = cli.invoke
    def invoke(command, *args, **kwargs):
        if command[0] in ("flutter", "git"):
            return {"returncode": 7, "error_type": None, "stdout": "", "stderr": "baseline unavailable"}
        return original(command, *args, **kwargs)
    monkeypatch.setattr(cli, "invoke", invoke)
    result = cli.capture(Path(__file__).resolve().parents[2], tmp_path, "dart")
    assert not result["passed"]
    assert len(result["results"]) == 7
    assert all(row["passed"] for row in result["results"][1:])


def test_kotlin_capture_uses_native_junit_and_restores_temporary_source(monkeypatch, tmp_path):
    root = tmp_path / "checkout"
    fixtures = root / "tools/native_error_corpus"
    shutil.copytree(Path(__file__).resolve().parents[2] / "tools/native_error_corpus", fixtures)
    destination = root / "android/app/src/test/java/com/example/flutter_application_1/ArrayLengthProbeTest.kt"
    destination.parent.mkdir(parents=True)
    original = cli.invoke
    def invoke(command, *args, **kwargs):
        if ":app:testDebugUnitTest" in command:
            assert destination.is_file()
            xml = root / "build/app/test-results/testDebugUnitTest/TEST-com.example.flutter_application_1.ArrayLengthProbeTest.xml"
            xml.parent.mkdir(parents=True)
            xml.write_text(kotlin_xml(), encoding="utf-8")
            return {"returncode": 1, "error_type": None, "stdout": "", "stderr": "expected native test failure"}
        if command[0] in (sys.executable, "node"):
            return original(command, *args, **kwargs)
        return {"returncode": 0, "error_type": None, "stdout": "", "stderr": ""}
    monkeypatch.setattr(cli, "invoke", invoke)
    result = cli.capture(root, tmp_path / "out", "kotlin")
    assert result["passed"]
    assert not destination.exists()
    assert (tmp_path / "out/kotlin-original-junit.xml").is_file()
