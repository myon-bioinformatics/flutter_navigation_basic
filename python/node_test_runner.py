"""Stdlib adapter for Node's native test runner and JUnit evidence.

Node owns JavaScript semantics. This adapter runs it without a shell and produces
a small local JSON receipt. The original JUnit remains the canonical CI artifact.
"""
from __future__ import annotations

import json
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


class NodeEvidenceError(ValueError):
    pass


def read_junit(path: Path) -> dict:
    """Reject missing, malformed or empty native JUnit evidence."""
    try:
        root = ET.parse(path).getroot()
    except (OSError, ET.ParseError) as exc:
        raise NodeEvidenceError(f"missing or invalid Node JUnit: {path}") from exc
    if root.tag not in {"testsuite", "testsuites"}:
        raise NodeEvidenceError("invalid Node JUnit root")
    cases = root.findall(".//testcase")
    if not cases:
        raise NodeEvidenceError("Node JUnit contains no test cases")
    failed = []
    names = []
    counts = {"passed": 0, "failed": 0, "skipped": 0, "total": len(cases)}
    for case in cases:
        name = case.get("name")
        if not name:
            raise NodeEvidenceError("Node JUnit testcase without name")
        names.append(name)
        problem = case.find("failure")
        if problem is None:
            problem = case.find("error")
        if problem is not None:
            counts["failed"] += 1
            failed.append({"name": name, "message": (problem.get("message") or (problem.text or "")).strip()[:2000]})
        elif case.find("skipped") is not None:
            counts["skipped"] += 1
        else:
            counts["passed"] += 1
    return {**counts, "failures": failed, "names": names}


def run_node(*, root: Path, files: list[str], report: Path,
             receipt: Path | None = None, name_pattern: str | None = None,
             timeout: int = 300, node: str = "node") -> int:
    if not files:
        print("node runner: no test files selected", file=sys.stderr)
        return 2
    # A stale successful report must never hide a failed/aborted subprocess.
    report = report.resolve()
    report.parent.mkdir(parents=True, exist_ok=True)
    report.unlink(missing_ok=True)
    if receipt is not None:
        receipt.unlink(missing_ok=True)
    cmd = [node, "--test", "--test-reporter=spec",
           "--test-reporter-destination=stdout", "--test-reporter=junit",
           f"--test-reporter-destination={report}"]
    if name_pattern is not None:
        cmd.extend(["--test-name-pattern", name_pattern])
    cmd.extend(files)
    try:
        code = subprocess.run(cmd, cwd=root, timeout=timeout, check=False).returncode
    except FileNotFoundError:
        print("node runner: Node executable not found", file=sys.stderr)
        return 127
    except subprocess.TimeoutExpired:
        print(f"node runner: timed out after {timeout}s", file=sys.stderr)
        return 124
    try:
        summary = read_junit(report)
    except NodeEvidenceError as exc:
        print(f"node runner: {exc}", file=sys.stderr)
        return code if code != 0 else 1
    if summary["passed"] + summary["failed"] == 0:
        print("node runner: no executed tests (all skipped)", file=sys.stderr)
        return code if code != 0 else 1
    # Node owns JavaScript regex semantics, including describe ancestors and
    # /pattern/flags. No-match produces synthetic file-level JUnit cases.
    # Do not re-evaluate the regex in Python.
    # Node normalizes paths in synthetic file-level cases (e.g. "./x" -> "x").
    # Normalize both sides instead of comparing the raw CLI spelling.
    file_names = {(root / name).resolve() for name in files}
    if name_pattern is not None and all(
        (root / name).resolve() in file_names for name in summary["names"]
    ):
        print("node runner: no selected tests (only file-level JUnit cases)", file=sys.stderr)
        return code if code != 0 else 1
    summary.update({"runner": "node", "exit_code": code,
                    "ok": code == 0 and summary["failed"] == 0,
                    "junit": str(report)})
    if receipt is not None:
        receipt.parent.mkdir(parents=True, exist_ok=True)
        receipt.write_text(json.dumps(summary, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"node: passed={summary['passed']} failed={summary['failed']} skipped={summary['skipped']} exit={code}")
    for failure in summary["failures"]:
        print(f"FAIL {failure['name']}: {failure['message']}", file=sys.stderr)
    return code if code != 0 else (1 if summary["failed"] else 0)
