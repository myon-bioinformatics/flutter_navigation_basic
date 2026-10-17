"""No native SDK is needed to test orchestration; real captures are opt-in CI."""
import json
from pathlib import Path
import shutil
import subprocess
import sys

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import capture_native_errors as cli


def test_real_python_and_node_controls_without_native_install(tmp_path):
    root = Path(__file__).resolve().parents[2]
    targets = [("python", [sys.executable, "-S", str(root / "tools/native_error_corpus/array_length.py")]),
               ("node", ["node", str(root / "tools/native_error_corpus/array_length.mjs")])]
    for language, command in targets:
        for case in cli.case_manifest(root, "replay:1")["cases"]:
            record = cli.invoke(command, root, tmp_path, language + case["name"],
                                payload=json.dumps(case["input"]).encode(), timeout=10)
            assert cli.classify(record, case, language) == case["expected"]
            assert (tmp_path / (language + case["name"] + ".stderr.log")).is_file()


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


def kotlin_xml(full=False):
    data = '''<testsuite><testcase name="empty" classname="com.example.flutter_application_1.ArrayLengthProbeTest"/>
    <testcase name="three" classname="com.example.flutter_application_1.ArrayLengthProbeTest"/>
    <testcase name="negative" classname="com.example.flutter_application_1.ArrayLengthProbeTest">
    <failure type="java.lang.NegativeArraySizeException">-1</failure></testcase>
    <system-out>XPROBE_LENGTH_RESULT=0:0\nXPROBE_LENGTH_RESULT=3:3</system-out></testsuite>'''
    if full:
        extra = "".join('<testcase classname="com.example.flutter_application_1.ArrayLengthProbeTest" name="' + name + '"><failure type="' + kind + '">observed</failure></testcase>'
            for name, kind in (("bounds", "java.lang.ArrayIndexOutOfBoundsException"), ("null_assert", "java.lang.NullPointerException"),
                               ("bad_cast", "java.lang.ClassCastException"), ("invalid_integer", "java.lang.NumberFormatException"),
                               ("divide_zero", "java.lang.ArithmeticException")))
        extra += '<testcase classname="com.example.flutter_application_1.ArrayLengthProbeTest" name="invalid_json"><skipped/></testcase>'
        data = data.replace("</testsuite>", extra + "</testsuite>")
    return data


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
    result = cli.capture(Path(__file__).resolve().parents[2], tmp_path, "dart",
                         baseline_receipt=tmp_path / "historical.json")
    assert result["context"]["healthy_build_executed_current_run"] is True
    assert "reuse disabled" in result["context"]["baseline_reuse_rejected"]
    assert not result["passed"]
    assert len(result["results"]) == 27
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
            xml.write_text(manifest_kotlin_xml(cli.case_manifest(root, "replay:1")["cases"]), encoding="utf-8")
            return {"returncode": 1, "error_type": None, "stdout": "", "stderr": "expected native test failure"}
        if command[0] in (sys.executable, "node"):
            return original(command, *args, **kwargs)
        return {"returncode": 0, "error_type": None, "stdout": "", "stderr": ""}
    monkeypatch.setattr(cli, "invoke", invoke)
    result = cli.capture(root, tmp_path / "out", "kotlin", seed="replay:1")
    assert result["passed"]
    assert not destination.exists()
    assert (tmp_path / "out/kotlin-original-junit.xml").is_file()
    assert result["context"]["unobserved"][0]["case"] == "invalid_json"


@pytest.mark.parametrize("metadata", [
    {},
    {"platform": "different", "architecture": "different"},
    {"6": {"stdout": "Gradle changed", "stderr": ""}},
    {"android_sdk": "changed", "android_ndk": "changed"},
])
def test_historical_build_reuse_fails_closed_without_complete_identity(tmp_path, metadata):
    with pytest.raises(ValueError, match="reuse disabled"):
        cli.reuse_baseline(tmp_path, tmp_path, "kotlin", tmp_path / "prior.json", metadata)



def manifest_kotlin_xml(cases):
    import xml.etree.ElementTree as ET
    root = ET.Element("testsuite")
    output = []
    for case in cases:
        test = ET.SubElement(root, "testcase", name=case["name"],
                             classname="com.example.flutter_application_1.ArrayLengthProbeTest")
        if "kotlin_unobserved" in case:
            ET.SubElement(test, "skipped")
        elif "error" in case["expected"]:
            ET.SubElement(test, "failure", type=case["kotlin_types"][0])
        else:
            output.append("XPROBE_CASE_RESULT=" + case["name"] + ":" + str(case["expected"]["length"]))
    ET.SubElement(root, "system-out").text = "\n".join(output)
    return ET.tostring(root, encoding="unicode")


def test_seed_replay_diversity_fixed_controls_and_ranges():
    root = Path(__file__).resolve().parents[2]
    first = cli.case_manifest(root, "run:1")
    assert first == cli.case_manifest(root, "run:1")
    other = cli.case_manifest(root, "run:2")
    assert first["cases"][9:] != other["cases"][9:]
    fixed = cli.load_cases(root)
    assert len(fixed) == 9
    for seed in ["run:1", "run:2", "", "日本語"] + [str(i) for i in range(100)]:
        manifest = cli.case_manifest(root, seed)
        assert manifest["cases"][:9] == fixed
        cases = {case["name"]: case for case in manifest["cases"]}
        assert len(cases) == 13
        assert cases["boundary_one"]["input"]["count"] == 1
        assert 2 <= cases["seeded_length"]["input"]["count"] <= 16
        assert -16 <= cases["seeded_negative"]["input"]["count"] <= -2
        assert 1 <= cases["seeded_bounds"]["input"]["index"] <= 16
        assert manifest["fixed_case_ids"] == [case["name"] for case in fixed]
        assert len(manifest["sampled_case_ids"]) == 4


def test_default_seed_run_and_attempt(monkeypatch):
    monkeypatch.setenv("GITHUB_RUN_ID", "123")
    monkeypatch.setenv("GITHUB_RUN_ATTEMPT", "2")
    assert cli.default_seed() == "123:2"


def test_rendered_kotlin_uses_manifest_and_case_ids():
    root = Path(__file__).resolve().parents[2]
    cases = cli.case_manifest(root, "replay:1")["cases"]
    source = cli.render_kotlin((root / "tools/native_error_corpus/ArrayLengthProbeTest.kt").read_text(), cases)
    assert "/* SEEDED_CASES */" not in source
    assert source.count("@Test") == 13
    for case in cases[9:12]:
        assert 'observe("' + case["name"] + '", ' + str(case["input"]["count"]) + ')' in source
    assert "IntArray(1)[" + str(cases[12]["input"]["index"]) + "]" in source
    assert "XPROBE_CASE_RESULT=" in source


def test_kotlin_duplicate_count_is_disambiguated_by_case_id(tmp_path):
    root = Path(__file__).resolve().parents[2]
    cases = cli.case_manifest(root, "replay:1")["cases"]
    # The sampled count can collide with fixed 'three'; IDs must still distinguish results.
    cases[10]["input"]["count"] = 3
    cases[10]["expected"]["length"] = 3
    path = tmp_path / "junit.xml"
    xml = manifest_kotlin_xml(cases)
    path.write_text(xml)
    actual = cli.kotlin_result(path, cases)
    assert actual["three"] == actual["seeded_length"] == {"length": 3}
    path.write_text(xml.replace("seeded_length:3", "seeded_length:2"))
    assert cli.kotlin_result(path, cases)["seeded_length"] == {"length": 2}
    for broken in (xml.replace("XPROBE_CASE_RESULT=seeded_length:3", ""),
                   xml.replace("XPROBE_CASE_RESULT=seeded_length:3", "XPROBE_CASE_RESULT=three:3"),
                   xml.replace("java.lang.NegativeArraySizeException", "java.lang.AssertionError"),
                   xml.replace("<skipped />", "")):
        path.write_text(broken)
        with pytest.raises(ValueError):
            cli.kotlin_result(path, cases)


@pytest.mark.parametrize("returncode,stdout,stderr,error_type", [
    (0, '{"length":999}', "", None),
    (0, "not JSON", "", None),
    (1, "", "wrong error", None),
    (None, "", "RangeError", "FileNotFoundError"),
    (None, "", "RangeError", "TimeoutExpired"),
])
def test_sampled_unexpected_results_fail(returncode, stdout, stderr, error_type):
    root = Path(__file__).resolve().parents[2]
    cases = cli.case_manifest(root, "replay:1")["cases"]
    record = dict(returncode=returncode, stdout=stdout, stderr=stderr, error_type=error_type)
    for case in cases[9:]:
        assert cli.classify(record, case, "dart") != case["expected"]


def test_manifest_receipt_hash_and_replay(monkeypatch, tmp_path):
    import hashlib
    root = Path(__file__).resolve().parents[2]
    original = cli.invoke
    def invoke(command, *args, **kwargs):
        if command[0] in (sys.executable, "node"):
            return original(command, *args, **kwargs)
        return {"returncode": 7, "error_type": None, "stdout": "", "stderr": "SDK unavailable"}
    monkeypatch.setattr(cli, "invoke", invoke)
    receipts = [cli.capture(root, tmp_path / str(i), "dart", seed="exact:replay") for i in range(2)]
    manifests = [(tmp_path / str(i) / "case-manifest.json").read_bytes() for i in range(2)]
    assert manifests[0] == manifests[1]
    assert receipts[0]["context"]["manifest_sha256"] == hashlib.sha256(manifests[0]).hexdigest()
    assert receipts[0]["context"]["seed"] == "exact:replay"
    assert receipts[0]["context"]["generator_version"] == cli.GENERATOR_VERSION
    assert len(receipts[0]["context"]["fixed_case_ids"]) == 9
    assert len(receipts[0]["context"]["sampled_case_ids"]) == 4
    assert not receipts[0]["passed"]
