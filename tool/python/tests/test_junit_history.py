"""Regression tests for read-only JUnit failure history comparison."""
import importlib.util
import json
from pathlib import Path
import subprocess
import sys

SCRIPT = Path(__file__).resolve().parents[1] / "junit_history.py"
spec = importlib.util.spec_from_file_location("junit_history", SCRIPT)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

SHA = "a" * 40


def sample(test="test_one", kind="failure", report="run-specific"):
    return {"category": "test_failure",
            "context": {"repository": "myon-bioinformatics/flutter_navigation_basic",
                        "report_id": report, "commit_sha": None},
            "value": {"class": "test_oracle", "test": test, "kind": kind}}


def test_stable_fingerprint_ignores_run_specific_context(tmp_path):
    a, b = tmp_path / "a.jsonl", tmp_path / "b.jsonl"
    a.write_text(json.dumps(sample(report="first")) + "\n", encoding="utf-8")
    b.write_text(json.dumps(sample(report="second")) + "\n", encoding="utf-8")
    assert module.load(a)[0]["fingerprint"] == module.load(b)[0]["fingerprint"]


def test_new_recurring_resolved_and_counts(tmp_path):
    def rows(name, count):
        path = tmp_path / (name + ".jsonl")
        path.write_text("".join(json.dumps(sample(name)) + "\n" for _ in range(count)),
                        encoding="utf-8")
        return module.load(path)
    old = rows("old", 1) + rows("same", 1)
    now = rows("same", 2) + rows("new", 1)
    report = module.compare(now, old, commit_sha=SHA, run_id="42",
                            previous_commit_sha="b" * 40, previous_run_id="41")
    assert report["summary"] == {"new": 1, "recurring": 1, "resolved": 1}
    recurring = next(x for x in report["findings"] if x["status"] == "recurring")
    assert (recurring["previous_count"], recurring["current_count"]) == (1, 2)


def test_error_and_failure_have_distinct_fingerprints(tmp_path):
    path = tmp_path / "failure.jsonl"
    path.write_text("\n".join(json.dumps(sample(kind=k))
                              for k in ("failure", "error")) + "\n", encoding="utf-8")
    assert len({x["fingerprint"] for x in module.load(path)}) == 2


def test_cli_and_invalid_commit(tmp_path):
    source, output = tmp_path / "input.jsonl", tmp_path / "output.json"
    source.write_text(json.dumps(sample()) + "\n", encoding="utf-8")
    cmd = [sys.executable, "-I", "-S", str(SCRIPT), "--current", str(source),
           "--commit-sha", SHA, "--run-id", "42", "--output", str(output)]
    good = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
    assert good.returncode == 0, good.stderr
    assert json.loads(output.read_text(encoding="utf-8"))["summary"]["new"] == 1
    bad = subprocess.run(cmd[:-4] + ["--commit-sha", "invalid",
                                      "--run-id", "42", "--output", str(output)],
                         capture_output=True, text=True, timeout=5)
    assert bad.returncode == 2
