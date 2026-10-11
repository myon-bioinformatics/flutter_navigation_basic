"""Regression tests for allowlisted multi-runner commands and immutable failures."""
import json
import shutil
import sys
from pathlib import Path
from types import SimpleNamespace
import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from multi_test_runner import command_for, run_suite, summarize_junit, run_node_retries


def test_runner_commands(tmp_path):
    (tmp_path / "e2e").mkdir()
    for file in ("e2e/test.spec.ts", "test.ts", "test_pw.py"):
        (tmp_path / file).write_text("test")
    report = tmp_path / "report.xml"
    deno, cwd, env = command_for("deno", root=tmp_path, files=["test.ts"], report=report)
    assert deno[:3] == ["deno", "test", "--junit-path"]
    assert cwd == tmp_path and not env
    node, cwd, env = command_for("playwright-node", root=tmp_path,
                                  files=["e2e/test.spec.ts"], report=report)
    assert node[:4] == ["npx", "--no-install", "playwright", "test"]
    assert cwd == tmp_path / "e2e"
    assert env["PLAYWRIGHT_JUNIT_OUTPUT_FILE"] == str(report)
    py, _, _ = command_for("playwright-python", root=tmp_path,
                           files=["test_pw.py"], report=report)
    assert py[:3] == [sys.executable, "-m", "pytest"]


@pytest.mark.parametrize("files", [[], ["../escape.py"], ["not-found.ts"]])
def test_unsafe_paths_rejected(tmp_path, files):
    with pytest.raises(ValueError):
        command_for("deno", root=tmp_path, files=files, report=tmp_path / "r.xml")


def test_node_playwright_cannot_escape_e2e(tmp_path):
    (tmp_path / "outside.spec.ts").write_text("test")
    with pytest.raises(ValueError):
        command_for("playwright-node", root=tmp_path, files=["outside.spec.ts"],
                    report=tmp_path / "r.xml")


def test_retry_retains_initial_failure_and_hashes_message(tmp_path):
    (tmp_path / "test_pw.py").write_text("test")
    report = tmp_path / "r.xml"
    history = tmp_path / "history.json"
    calls = []
    def invoke(cmd, **kwargs):
        calls.append(cmd)
        output = Path(next(a.split("=", 1)[1] for a in cmd if a.startswith("--junitxml=")))
        if len(calls) == 1:
            output.write_text('<testsuites><testsuite><testcase name="bad"><failure message="SECRET_TOKEN"/></testcase></testsuite></testsuites>')
            return SimpleNamespace(returncode=1)
        output.write_text('<testsuites><testsuite><testcase name="ok"/></testsuite></testsuites>')
        return SimpleNamespace(returncode=0)
    assert run_suite("playwright-python", root=tmp_path, files=["test_pw.py"],
                     report=report, history=history, retry_failed=True, invoke=invoke) == 1
    data = json.loads(history.read_text())
    assert len(calls) == 2 and len(data["attempts"]) == 2
    assert data["initial_failed"] and data["flaky_recovered"]
    assert "SECRET_TOKEN" not in history.read_text()


@pytest.mark.parametrize("xml", [None, '<testsuites><testsuite><testcase name="skip"><skipped/></testcase></testsuite></testsuites>'])
def test_missing_or_all_skipped_junit_fails_closed(tmp_path, xml):
    (tmp_path / "test_pw.py").write_text("test")
    def invoke(cmd, **kwargs):
        if xml:
            (tmp_path / "r.xml").write_text(xml)
        return SimpleNamespace(returncode=0)
    assert run_suite("playwright-python", root=tmp_path, files=["test_pw.py"],
                     report=tmp_path / "r.xml", history=tmp_path / "h.json", invoke=invoke) == 1


@pytest.mark.skipif(shutil.which("node") is None, reason="Node unavailable")
def test_real_node_retry_never_masks_first_failure(tmp_path):
    js = tmp_path / "flaky.test.mjs"
    js.write_text("import test from 'node:test'; import fs from 'node:fs'; "
                  "test('flaky', () => {if (!fs.existsSync('marker')) {"
                  "fs.writeFileSync('marker','1'); throw Error('first attempt');}});")
    history = tmp_path / "history.json"
    assert run_node_retries(root=tmp_path, files=[js.name], report=tmp_path / "node.xml",
                            history=history, retry_failed=True) != 0
    data = json.loads(history.read_text())
    assert data["initial_failed"] and data["flaky_recovered"]
    assert len(data["attempts"]) == 2


def test_failure_ledger_accumulates_and_rejects_corruption(tmp_path):
    from multi_test_runner import update_failure_ledger
    path = tmp_path / "patterns.json"
    failure = {"kind": "failure", "message_sha256": "a" * 64}
    attempts = [{"failures": [failure]}]
    update_failure_ledger(path, "node", attempts)
    update_failure_ledger(path, "node", attempts)
    data = json.loads(path.read_text())
    assert data["schema"] == "failure-patterns/1"
    assert next(iter(data["patterns"].values()))["occurrences"] == 2
    path.write_text("{broken")
    with pytest.raises(ValueError):
        update_failure_ledger(path, "node", attempts)
    assert path.read_text() == "{broken"
