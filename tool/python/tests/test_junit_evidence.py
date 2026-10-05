"""Real FilterBasic negative path through native pytest, JUnit and vendored xprobe."""
import json
import os
from pathlib import Path
import subprocess
import sys
import xml.etree.ElementTree as ET

from failure_identity import collect_failure_identity, xprobe

PYTHON_DIR = Path(__file__).resolve().parents[1]
ROOT = PYTHON_DIR.parents[1]
REPOSITORY = "myon-bioinformatics/flutter_navigation_basic"


def test_oracle_wrapper_junit_preserves_failure_and_outcomes(tmp_path):
    evidence = Path(os.environ.get("FLUTTER_FAILURE_EVIDENCE", tmp_path / "evidence")).resolve()
    evidence.mkdir(parents=True, exist_ok=True)
    fixture = tmp_path / "test_oracle.py"
    fixture.write_text('''
import json
import os
from pathlib import Path
import subprocess
import sys
import pytest
from outcomes import summarize_counts

def test_outcomes_success():
    assert summarize_counts({"passed": 1}, source="child")["ok"] is True

@pytest.mark.parametrize("label", ["PARAMETER_SENTINEL"], ids=["PARAMETER_SENTINEL"])
def test_filter_invalid_input_is_not_success(label):
    print("STDOUT_SENTINEL")
    result = subprocess.run(
        [sys.executable, "-S", os.environ["FILTER_BASIC_CLI"]],
        input='{"values":"not-a-list","equals":1}',
        capture_output=True, text=True, encoding="utf-8", timeout=5,
    )
    Path(os.environ["FILTER_BASIC_EXIT"]).write_text(json.dumps({"exit_code": result.returncode}))
    # Intentionally wrong: the real CLI must reject this input with native exit 2.
    assert result.returncode == 0, "ASSERTION_SENTINEL"

@pytest.fixture
def broken_oracle():
    raise RuntimeError("SETUP_SENTINEL")

def test_oracle_setup_error(broken_oracle):
    pass

def test_skip():
    pytest.skip("synthetic skipped oracle")
''', encoding="utf-8")
    env = dict(os.environ, PYTHONPATH=str(PYTHON_DIR),
               PYTEST_DISABLE_PLUGIN_AUTOLOAD="1", PYTEST_ADDOPTS="",
               FILTER_BASIC_CLI=str(PYTHON_DIR / "filter_basic.py"),
               FILTER_BASIC_EXIT=str(evidence / "filter-cli-exit.json"))
    command = [sys.executable, str(PYTHON_DIR / "test.py"), "--pytest", "--",
               str(fixture), "-c", os.devnull, "--rootdir", str(tmp_path),
               "--confcutdir", str(tmp_path), "-p", "conftest", "--oracle-mode=local", "-q"]
    plain_path = tmp_path / "plain-outcomes.json"
    plain = subprocess.run(command + ["--outcomes-json", str(plain_path)],
                           env=env, capture_output=True, text=True, timeout=60)
    wrapped = subprocess.run([
        sys.executable, str(PYTHON_DIR / "expected_child_failure.py"),
        "--output-dir", str(evidence / "native-pytest"), "--expect-exit", "1",
        "--timeout", "45", "--", *command,
        "--outcomes-json", str(evidence / "outcomes.json"),
        "--junitxml", str(evidence / "junit.xml"), "-o", "junit_logging=all",
    ], env=env, capture_output=True, text=True, timeout=60)
    receipt = json.loads((evidence / "native-pytest/receipt.json").read_text(encoding="utf-8"))
    assert plain.returncode == receipt["exit_code"] == 1
    assert wrapped.returncode == 0, wrapped.stdout + wrapped.stderr
    assert receipt["matched_expectation"] and not receipt["timed_out"]
    cli_exit = json.loads((evidence / "filter-cli-exit.json").read_text())["exit_code"]
    assert cli_exit == 2
    (evidence / "exit.json").write_text(json.dumps({
        "without_junit": plain.returncode, "with_junit": receipt["exit_code"],
        "expected_failure_wrapper": wrapped.returncode, "filter_cli": cli_exit,
    }), encoding="utf-8")
    outcomes = json.loads((evidence / "outcomes.json").read_text(encoding="utf-8"))
    assert outcomes == json.loads(plain_path.read_text(encoding="utf-8"))
    assert outcomes["exitstatus"] == 1 and outcomes["ok"] is False
    assert outcomes["counts"] == {"passed": 1, "failed": 1, "skipped": 1,
                                  "xfailed": 0, "xpassed": 0, "error": 1}
    raw = (evidence / "junit.xml").read_text(encoding="utf-8")
    imported = collect_failure_identity(raw, root=ROOT, repository=REPOSITORY,
                                        report_id="controlled-filter-basic")
    assert imported["truncated"] is False
    cases = imported["cases"]
    assert {(c["value"]["test"], c["value"]["kind"]) for c in cases} == {
        ("test_filter_invalid_input_is_not_success", "failure"), ("test_oracle_setup_error", "error")}
    compact = xprobe.corpus_to_json(cases, jsonl=True)
    (evidence / "failure-identity.jsonl").write_text(compact, encoding="utf-8")
    assert all(c["context"]["repository"] == REPOSITORY and
               len(c["context"]["commit_sha"]) == 40 for c in cases)
    assert Path(xprobe.__file__).resolve() == (PYTHON_DIR / "vendor/xprobe.py").resolve()
    # Reorder the same captured evidence instead of rerunning the native command.
    root = ET.fromstring(raw)
    for suite in root.iter("testsuite"):
        suite[:] = list(reversed(list(suite)))
    reordered = collect_failure_identity(ET.tostring(root, encoding="unicode"), root=ROOT,
                                         repository=REPOSITORY, report_id="controlled-filter-basic")
    assert {c["id"] for c in reordered["cases"]} == {c["id"] for c in cases}
    later_report = collect_failure_identity(raw, root=ROOT, repository=REPOSITORY,
                                           report_id="another-run")
    assert {c["fingerprint"] for c in later_report["cases"]} == {c["fingerprint"] for c in cases}
    for sentinel in ("PARAMETER_SENTINEL", "STDOUT_SENTINEL", "ASSERTION_SENTINEL", "SETUP_SENTINEL"):
        assert sentinel in raw and sentinel not in compact
