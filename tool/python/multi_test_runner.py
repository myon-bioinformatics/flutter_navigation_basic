"""Allowlisted Deno/Playwright adapters, native JUnit evidence and bounded retries.

No shell or arbitrary commands. Retry repeats the *selected files*, not a
guessed testcase ID. A retry success never masks the original failure.
"""
from __future__ import annotations
import hashlib
import json
import os
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

RUNNERS = ("deno", "playwright-node", "playwright-python")


def command_for(runner: str, *, root: Path, files: list[str], report: Path):
    if runner not in RUNNERS or not files:
        raise ValueError("unsupported runner or empty file selection")
    base = root.resolve()
    paths = []
    for file in files:
        candidate = (base / file).resolve()
        if not candidate.is_file() or not candidate.is_relative_to(base):
            raise ValueError("test file must exist inside repository")
        paths.append(str(candidate))
    report = report.resolve()
    if runner == "deno":
        return ["deno", "test", "--junit-path", str(report), *paths], base, {}
    if runner == "playwright-node":
        e2e = base / "e2e"
        if not all(Path(p).is_relative_to(e2e) for p in paths):
            raise ValueError("Node Playwright test files must be under e2e")
        return ["npx", "--no-install", "playwright", "test", "--reporter=junit",
                *[str(Path(p).relative_to(e2e)) for p in paths]], e2e, {
            "PLAYWRIGHT_JUNIT_OUTPUT_FILE": str(report)}
    return [sys.executable, "-m", "pytest", "--junitxml=" + str(report), *paths], base, {}


def summarize_junit(path: Path) -> dict:
    try:
        root = ET.parse(path).getroot()
    except (OSError, ET.ParseError) as exc:
        raise ValueError("missing or malformed JUnit evidence") from exc
    if root.tag not in ("testsuite", "testsuites"):
        raise ValueError("unexpected JUnit root")
    cases = root.findall(".//testcase")
    if not cases:
        raise ValueError("JUnit contains zero testcases")
    result = {"total": len(cases), "passed": 0, "failed": 0, "skipped": 0, "failures": []}
    for case in cases:
        problem = case.find("failure")
        if problem is None:
            problem = case.find("error")
        if problem is not None:
            result["failed"] += 1
            message = (problem.get("message") or problem.text or "").strip()
            result["failures"].append({
                "name": (case.get("name") or "")[:200],
                "class": (case.get("classname") or "")[:200],
                "message_sha256": hashlib.sha256(message.encode()).hexdigest(),
                "kind": problem.tag})
        elif case.find("skipped") is not None:
            result["skipped"] += 1
        else:
            result["passed"] += 1
    return result


def _save_history(history: Path, runner: str, files: list[str], attempts: list[dict],
                  scope: str = "same-selected-files"):
    record = {"schema": "test-attempts/1", "runner": runner, "files": files,
              "retry_scope": scope, "attempts": attempts,
              "initial_failed": attempts[0]["exit_code"] != 0,
              "flaky_recovered": len(attempts) == 2 and attempts[0]["exit_code"] != 0
                                 and attempts[1]["exit_code"] == 0}
    history.write_text(json.dumps(record, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def update_failure_ledger(path: Path, runner: str, attempts: list[dict]) -> None:
    """Accumulate fingerprints across runs without retaining raw error text."""
    path = path.resolve()
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, ValueError) as exc:
            raise ValueError("invalid existing failure ledger; refusing overwrite") from exc
        if data.get("schema") != "failure-patterns/1" or not isinstance(data.get("patterns"), dict):
            raise ValueError("invalid failure ledger schema")
    else:
        data = {"schema": "failure-patterns/1", "patterns": {}}
    for attempt in attempts:
        for failure in attempt["failures"]:
            key = runner + ":" + failure["kind"] + ":" + failure["message_sha256"]
            pattern = data["patterns"].setdefault(key, {
                "runner": runner, "kind": failure["kind"],
                "message_sha256": failure["message_sha256"], "occurrences": 0})
            pattern["occurrences"] += 1
    if len(data["patterns"]) > 500:
        raise ValueError("failure ledger reached 500 distinct patterns; archive it first")
    temp = path.with_name(path.name + ".tmp")
    temp.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    temp.replace(path)


def run_suite(runner: str, *, root: Path, files: list[str], report: Path,
              history: Path, retry_failed: bool = False, timeout: int = 300,
              ledger: Path | None = None,
              invoke=None) -> int:
    if timeout <= 0:
        raise ValueError("timeout must be positive")
    cmd, cwd, extra_env = command_for(runner, root=root, files=files, report=report)
    report = report.resolve()
    history = history.resolve()
    report.parent.mkdir(parents=True, exist_ok=True)
    history.parent.mkdir(parents=True, exist_ok=True)
    history.unlink(missing_ok=True)
    # Invalidate both report slots before attempting the first run. A prior
    # retry must not masquerade as evidence for a fresh first-attempt success.
    report.unlink(missing_ok=True)
    report.with_name(report.stem + ".retry" + report.suffix).unlink(missing_ok=True)
    invoke = invoke or subprocess.run
    attempts = []
    for number in (1, 2) if retry_failed else (1,):
        output = report if number == 1 else report.with_name(report.stem + ".retry" + report.suffix)
        output.unlink(missing_ok=True)
        this_cmd = [arg.replace(str(report), str(output)) for arg in cmd]
        env = {**os.environ, **{k: v.replace(str(report), str(output)) for k, v in extra_env.items()}}
        try:
            code = invoke(this_cmd, cwd=cwd, env=env, timeout=timeout, check=False).returncode
        except FileNotFoundError:
            code = 127
        except subprocess.TimeoutExpired:
            code = 124
        try:
            result = summarize_junit(output)
        except ValueError as exc:
            result = {"total": 0, "passed": 0, "failed": 0, "skipped": 0,
                      "failures": [], "evidence_error": str(exc)}
            if code == 0:
                code = 1
        if code == 0 and (result["failed"] or result["passed"] == 0):
            code = 1
        attempts.append({"attempt": number, "exit_code": code, "junit": str(output), **result})
        print(f'{runner}: attempt={number} exit={code} passed={result["passed"]} failed={result["failed"]}')
        if code == 0:
            break
    _save_history(history, runner, files, attempts)
    if ledger is not None:
        update_failure_ledger(ledger, runner, attempts)
    return attempts[0]["exit_code"]


def run_node_retries(*, root: Path, files: list[str], report: Path, history: Path,
                     name_pattern: str | None = None, timeout: int = 300,
                     retry_failed: bool = False, ledger: Path | None = None) -> int:
    from node_test_runner import run_node
    report = report.resolve()
    history = history.resolve()
    history.parent.mkdir(parents=True, exist_ok=True)
    history.unlink(missing_ok=True)
    report.parent.mkdir(parents=True, exist_ok=True)
    report.unlink(missing_ok=True)
    report.with_name(report.stem + ".retry" + report.suffix).unlink(missing_ok=True)
    attempts = []
    for number in (1, 2) if retry_failed else (1,):
        output = report if number == 1 else report.with_name(report.stem + ".retry" + report.suffix)
        code = run_node(root=root, files=files, report=output,
                        name_pattern=name_pattern, timeout=timeout)
        try:
            result = summarize_junit(output)
        except ValueError as exc:
            result = {"total": 0, "passed": 0, "failed": 0, "skipped": 0,
                      "failures": [], "evidence_error": str(exc)}
        if code == 0 and (result["passed"] == 0 or result["failed"]):
            code = 1
        attempts.append({"attempt": number, "exit_code": code,
                         "junit": str(output), **result})
        if code == 0:
            break
    _save_history(history, "node", files, attempts, "same-selected-files-and-filter")
    if ledger is not None:
        update_failure_ledger(ledger, "node", attempts)
    return attempts[0]["exit_code"]
