"""One-shot Flutter build + actual native/Python/Node negative controls.

Run in a disposable CI checkout. No SDK installation, deployment or permanent
source mutation here. The workflow supplies the toolchains and pinned xprobe.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import xml.etree.ElementTree as ET

CASES = (("empty", 0), ("three", 3), ("negative", -1))
BUILDS = {
    "dart": ["flutter", "build", "web", "--debug", "--no-pub"],
    "kotlin": ["flutter", "build", "apk", "--debug", "--no-pub", "--target-platform", "android-arm64"],
    "swift": ["flutter", "build", "ios", "--simulator", "--debug", "--no-codesign", "--no-pub"],
}
MARKERS = {"dart": ("RangeError",), "swift": ("count < 0",),
           "python": ("ValueError", "negative array length"), "node": ("RangeError",)}


def invoke(command, root, out, name, *, payload=None, timeout=1500):
    """Retain actual bytes beside decoded diagnostics; no shell or guessed exits."""
    record = {"command": command, "returncode": None, "error_type": None}
    try:
        with subprocess.Popen(command, cwd=root, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                              stderr=subprocess.PIPE, start_new_session=os.name == "posix",
                              env={**os.environ, "PYTHONIOENCODING": "utf-8"}) as process:
            try:
                stdout, stderr = process.communicate(payload, timeout=timeout)
            except subprocess.TimeoutExpired as error:
                if os.name == "posix":
                    try:
                        os.killpg(process.pid, signal.SIGKILL)
                    except ProcessLookupError:
                        pass
                else:
                    process.kill()
                stdout, stderr = process.communicate()
                error.stdout, error.stderr = stdout, stderr
                raise
            record["returncode"] = process.returncode
    except (OSError, subprocess.TimeoutExpired) as error:
        stdout, stderr = getattr(error, "stdout", b"") or b"", getattr(error, "stderr", b"") or b""
        record.update(error_type=type(error).__name__, error=str(error))
    for stream, data in (("stdout", stdout), ("stderr", stderr)):
        path = out / (name + "." + stream + ".log")
        path.write_bytes(data)
        record[stream] = data.decode("utf-8", errors="replace")
        record[stream + "_sha256"] = hashlib.sha256(data).hexdigest()
    return record


def load_cases(root):
    document = json.loads((Path(root) / "tools/native_error_corpus/cases.json").read_text(encoding="utf-8"))
    if document.get("schema") != "native-error-sweep/1":
        raise ValueError("unsupported error sweep")
    cases = document["cases"]
    if not cases or len({case["name"] for case in cases}) != len(cases):
        raise ValueError("nonempty unique cases required")
    return cases


def classify(record, case, language):
    """Match explicit per-language diagnostics; never accept a launch/timeout error."""
    if isinstance(case, int):  # historical array-only reader
        case = {"expected": {"error": "invalid_array_length"} if case < 0 else {"length": case},
                "markers": MARKERS}
    if record["error_type"] is not None:
        return {"unavailable_or_supervision_error": record["error_type"]}
    if "error" in case["expected"]:
        markers = case["markers"][language]
        if record["returncode"] != 0 and all(marker in record["stderr"] for marker in markers):
            return case["expected"]
        return {"unexpected_exit": record["returncode"], "expected_error_missing": True}
    if record["returncode"] != 0:
        return {"unexpected_exit": record["returncode"]}
    try:
        return json.loads(record["stdout"])
    except ValueError:
        return {"invalid_json_output": True}


def kotlin_result(xml_path, cases=None):
    """Read actual printed values/failure types, with one explicit unsupported case."""
    if cases is None:  # read the first array-only capture too
        cases = [{"name": name, "input": {"count": count},
                  "kotlin_types": ["java.lang.NegativeArraySizeException"]} for name, count in CASES]
    root = ET.parse(xml_path).getroot()
    tests = root.findall("testcase")
    if len(tests) != len(cases) or {case.get("name") for case in tests} != {case["name"] for case in cases}:
        raise ValueError("Kotlin probe did not execute all expected tests")
    if any(case.get("classname") != "com.example.flutter_application_1.ArrayLengthProbeTest" for case in tests):
        raise ValueError("unexpected native JUnit producer")
    observed = {}
    output = "\n".join(root.itertext())
    lengths = re.findall(r"XPROBE_LENGTH_RESULT=(-?\d+):(\d+)", output)
    specifications = {case["name"]: case for case in cases}
    for test in tests:
        name = test.get("name")
        case = specifications[name]
        error = test.find("failure")
        if "kotlin_unobserved" in case:
            if test.find("skipped") is None or error is not None or test.find("error") is not None:
                raise ValueError("unobserved Kotlin capability was not explicitly skipped")
            observed[name] = {"unobserved": case["kotlin_unobserved"]}
            continue
        if test.find("error") is not None or test.find("skipped") is not None:
            raise ValueError("Kotlin native test errored or skipped")
        if "kotlin_types" in case and (case.get("expected", {}).get("error") or name == "negative"):
            if error is None or error.get("type") not in case["kotlin_types"]:
                raise ValueError("expected actual Kotlin failure type")
            observed[name] = case.get("expected", {"error": "invalid_array_length"})
        else:
            count = case["input"]["count"]
            matches = [int(size) for item, size in lengths if int(item) == count]
            if error is not None or len(matches) != 1:
                raise ValueError("missing successful Kotlin output")
            observed[name] = {"length": matches[0]}
    return observed


def reuse_baseline(root, out, language, receipt, metadata):
    """Fail closed: historical receipts lack a complete native build fingerprint."""
    # Platform/architecture, Gradle, Android SDK/NDK and other build inputs were
    # not fully captured by the original receipt. Do not infer equivalence from
    # matching Flutter/JDK versions. capture() falls back to a real current build.
    raise ValueError("historical build reuse disabled: incomplete environment fingerprint")


def capture(root, out, language, *, timeout=1500, baseline_receipt=None):
    root, out = Path(root).resolve(), Path(out).resolve()
    out.mkdir(parents=True, exist_ok=True)
    fixtures = root / "tools/native_error_corpus"
    cases = load_cases(root)
    rows = []
    context = {"language": language, "scope": "one-shot-native-error-sweep",
               "native_app_runtime_verified": False,
               "run_id": os.environ.get("GITHUB_RUN_ID"), "attempt": os.environ.get("GITHUB_RUN_ATTEMPT")}
    metadata = {}
    commands = [["git", "rev-parse", "HEAD"], ["flutter", "--version", "--machine"], ["flutter", "doctor", "-v"],
                ["dart", "--version"], ["node", "--version"]]
    if language == "swift":
        commands += [["xcodebuild", "-version"], ["xcrun", "swift", "--version"]]
    if language == "kotlin":
        commands += [["java", "-version"], ["bash", "android/gradlew", "--version", "-p", "android"]]
    for index, command in enumerate(commands):
        metadata[str(index)] = invoke(command, root, out, "environment-" + str(index), timeout=120)
    hashes = {}
    for path in sorted(fixtures.iterdir()):
        if path.is_file():
            data = path.read_bytes()
            hashes[path.name] = hashlib.sha256(data).hexdigest()
            (out / ("source-" + path.name)).write_bytes(data)
    context.update(metadata=metadata, source_sha256=hashes)

    def add(name, target, actual, expected, record, payload=None):
        row = {**record, "name": name, "target": target, "input": payload,
               "value": actual, "expected": expected,
               "passed": json.dumps(actual, sort_keys=True) == json.dumps(expected, sort_keys=True),
               "case_context": None, "expectation_kind": "native-control",
               "error_origin": "target_exit" if record["returncode"] not in (0, None) else None}
        rows.append(row)

    baseline = None
    if baseline_receipt is not None:
        try:
            baseline = reuse_baseline(root, out, language, baseline_receipt, metadata)
        except (OSError, ValueError, KeyError, StopIteration) as error:
            context["baseline_reuse_rejected"] = str(error)
    if baseline is None:
        baseline = invoke(BUILDS[language], root, out, "flutter-baseline", timeout=timeout)
        baseline["executed_current_run"] = True
    context["healthy_build_executed_current_run"] = baseline["executed_current_run"]
    context["unobserved"] = [{"case": case["name"], "reason": case["kotlin_unobserved"]}
                              for case in cases if language == "kotlin" and "kotlin_unobserved" in case]
    context["healthy_flutter_build_passed"] = baseline["returncode"] == 0
    add("healthy-flutter-build", language, baseline["returncode"], 0, baseline)
    if baseline["returncode"] == 0:
        if language == "kotlin":
            destination = root / "android/app/src/test/java/com/example/flutter_application_1/ArrayLengthProbeTest.kt"
            if destination.exists():
                raise ValueError("refusing to overwrite an existing native probe")
            destination.write_bytes((fixtures / "ArrayLengthProbeTest.kt").read_bytes())
            try:
                xml = root / "build/app/test-results/testDebugUnitTest/TEST-com.example.flutter_application_1.ArrayLengthProbeTest.xml"
                if xml.exists():
                    raise ValueError("stale probe JUnit exists; use a fresh checkout")
                record = invoke(["bash", "android/gradlew", "-p", "android", ":app:testDebugUnitTest",
                    "--tests", "com.example.flutter_application_1.ArrayLengthProbeTest", "--rerun"],
                    root, out, "kotlin-native-junit", timeout=timeout)
                try:
                    data = xml.read_bytes()
                    (out / "kotlin-original-junit.xml").write_bytes(data)
                    actual = kotlin_result(xml, cases)
                except (OSError, ValueError, ET.ParseError) as error:
                    actual = {"invalid_native_junit": str(error)}
                expected = {case["name"]: {"unobserved": case["kotlin_unobserved"]} if "kotlin_unobserved" in case else case["expected"] for case in cases}
                if record["error_type"] is not None or record["returncode"] == 0:
                    actual = {"missing_native_failure": record["returncode"]}
                add("array-length-native-suite", language, actual, expected, record, {case["name"]: case["input"] for case in cases})
            finally:
                destination.unlink()
        else:
            native = ["dart", str(fixtures / "array_length.dart")]
            if language == "swift":
                binary = out / "array-length-swift"
                compile_result = invoke(["xcrun", "swiftc", str(fixtures / "array_length.swift"), "-o", str(binary)],
                                        root, out, "swift-probe-compile", timeout=timeout)
                add("swift-probe-compile", language, compile_result["returncode"], 0, compile_result)
                native = [str(binary)] if compile_result["returncode"] == 0 else None
            if native is not None:
                for case in cases:
                    record = invoke(native, root, out, language + "-" + case["name"],
                                    payload=json.dumps(case["input"]).encode(), timeout=30)
                    add(case["name"], language, classify(record, case, language), case["expected"], record, case["input"])
    for target, command in (("python", [sys.executable, "-S", str(fixtures / "array_length.py")]),
                             ("node", ["node", str(fixtures / "array_length.mjs")])):
        for case in cases:
            record = invoke(command, root, out, target + "-" + case["name"],
                            payload=json.dumps(case["input"]).encode(), timeout=30)
            add(case["name"], target, classify(record, case, target), case["expected"], record, case["input"])
    return {"schema": "portable-io-results/1", "scope": context["scope"],
            "passed": all(row["passed"] for row in rows), "results": rows, "context": context,
            "collector_environment": {"python": sys.version, "platform": sys.platform},
            "contract_sha256": hashlib.sha256(json.dumps(cases, sort_keys=True).encode()).hexdigest(),
            "targets": [{"language": language, "healthy_build": BUILDS[language]}],
            "native_equivalence_verified": False}


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--language", choices=tuple(BUILDS), required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--probe-tools", type=Path, required=True)
    parser.add_argument("--baseline-receipt", type=Path)
    args = parser.parse_args(argv)
    sys.path.insert(0, str(args.probe_tools.resolve()))
    from contract_probe import write_junit
    result = capture(Path(__file__).resolve().parents[1], args.output, args.language, baseline_receipt=args.baseline_receipt)
    (args.output / "receipt.json").write_text(json.dumps(result, ensure_ascii=True, indent=2), encoding="utf-8")
    write_junit(result, args.output / "acceptance.xml")
    write_junit(result, args.output / "observed-failures.xml", observations=True)
    print(json.dumps({"passed": result["passed"], "executions": len(result["results"])}))
    return 0 if result["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
