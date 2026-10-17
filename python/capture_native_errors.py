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


def classify(record, count, language):
    """Independent explicit oracle: nonnegative length or a native negative error."""
    if record["error_type"] is not None:
        return {"unavailable_or_supervision_error": record["error_type"]}
    if count < 0:
        if record["returncode"] != 0 and all(marker in record["stderr"] for marker in MARKERS[language]):
            return {"error": "invalid_array_length"}
        return {"unexpected_exit": record["returncode"], "expected_error_missing": True}
    if record["returncode"] != 0:
        return {"unexpected_exit": record["returncode"]}
    try:
        return json.loads(record["stdout"])
    except ValueError:
        return {"invalid_json_output": True}


def kotlin_result(xml_path):
    """Read the actual Gradle JUnit, including observed lengths, not fixture answers."""
    root = ET.parse(xml_path).getroot()
    cases = root.findall("testcase")
    if len(cases) != 3 or {case.get("name") for case in cases} != {name for name, _ in CASES}:
        raise ValueError("Kotlin probe did not execute all three expected tests")
    if any(case.get("classname") != "com.example.flutter_application_1.ArrayLengthProbeTest" for case in cases):
        raise ValueError("unexpected native JUnit producer")
    observed = {}
    output = "\n".join(root.itertext())
    lengths = re.findall(r"XPROBE_LENGTH_RESULT=(-?\d+):(\d+)", output)
    for case in cases:
        name = case.get("name")
        error = case.find("failure")
        if case.find("error") is not None or case.find("skipped") is not None:
            raise ValueError("Kotlin native test errored or skipped")
        if name == "negative":
            if error is None or error.get("type") != "java.lang.NegativeArraySizeException":
                raise ValueError("expected actual Kotlin NegativeArraySizeException")
            observed[name] = {"error": "invalid_array_length"}
        else:
            count = dict(CASES)[name]
            matches = [int(size) for item, size in lengths if int(item) == count]
            if error is not None or len(matches) != 1:
                raise ValueError("missing successful Kotlin output")
            observed[name] = {"length": matches[0]}
    return observed


def capture(root, out, language, *, timeout=1500):
    root, out = Path(root).resolve(), Path(out).resolve()
    out.mkdir(parents=True, exist_ok=True)
    fixtures = root / "tools/native_error_corpus"
    rows = []
    context = {"language": language, "scope": "one-shot-flutter-build-and-array-length-controls",
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

    baseline = invoke(BUILDS[language], root, out, "flutter-baseline", timeout=timeout)
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
                    actual = kotlin_result(xml)
                except (OSError, ValueError, ET.ParseError) as error:
                    actual = {"invalid_native_junit": str(error)}
                expected = {name: {"error": "invalid_array_length"} if count < 0 else {"length": count} for name, count in CASES}
                if record["error_type"] is not None or record["returncode"] == 0:
                    actual = {"missing_native_failure": record["returncode"]}
                add("array-length-native-suite", language, actual, expected, record, dict(CASES))
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
                for name, count in CASES:
                    record = invoke(native, root, out, language + "-" + name,
                                    payload=json.dumps({"count": count}).encode(), timeout=30)
                    expected = {"error": "invalid_array_length"} if count < 0 else {"length": count}
                    add(name, language, classify(record, count, language), expected, record, {"count": count})
    for target, command in (("python", [sys.executable, "-S", str(fixtures / "array_length.py")]),
                             ("node", ["node", str(fixtures / "array_length.mjs")])):
        for name, count in CASES:
            record = invoke(command, root, out, target + "-" + name,
                            payload=json.dumps({"count": count}).encode(), timeout=30)
            expected = {"error": "invalid_array_length"} if count < 0 else {"length": count}
            add(name, target, classify(record, count, target), expected, record, {"count": count})
    return {"schema": "portable-io-results/1", "scope": context["scope"],
            "passed": all(row["passed"] for row in rows), "results": rows, "context": context,
            "collector_environment": {"python": sys.version, "platform": sys.platform},
            "contract_sha256": hashlib.sha256(json.dumps(CASES).encode()).hexdigest(),
            "targets": [{"language": language, "healthy_build": BUILDS[language]}],
            "native_equivalence_verified": False}


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--language", choices=tuple(BUILDS), required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--probe-tools", type=Path, required=True)
    args = parser.parse_args(argv)
    sys.path.insert(0, str(args.probe_tools.resolve()))
    from contract_probe import write_junit
    result = capture(Path(__file__).resolve().parents[1], args.output, args.language)
    (args.output / "receipt.json").write_text(json.dumps(result, ensure_ascii=True, indent=2), encoding="utf-8")
    write_junit(result, args.output / "acceptance.xml")
    write_junit(result, args.output / "observed-failures.xml", observations=True)
    print(json.dumps({"passed": result["passed"], "executions": len(result["results"])}))
    return 0 if result["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
