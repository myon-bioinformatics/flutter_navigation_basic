"""Exercise the oracle wrapper and outcomes receipt with an expected failing child."""
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import pytest

PYTHON_DIR = Path(__file__).resolve().parents[1]
ROOT = PYTHON_DIR.parents[1]


def test_oracle_wrapper_junit_preserves_failure_and_outcomes(tmp_path):
    importer = ROOT / ".junit-tools" / "xprobe.py"
    if not importer.is_file() and os.environ.get("GITHUB_ACTIONS") != "true" and not os.environ.get("FLUTTER_FAILURE_EVIDENCE"):
        pytest.skip("optional local JUnit regression: fetch the pinned importer (docs/junit-evidence.md)")
    assert importer.is_file(), "CI must provision the pinned test-only JUnit importer"
    evidence = Path(os.environ.get("FLUTTER_FAILURE_EVIDENCE", tmp_path / "evidence")).resolve()
    evidence.mkdir(parents=True, exist_ok=True)
    fixture = tmp_path / "test_oracle.py"
    fixture.write_text('''
import pytest
from outcomes import summarize_counts

def test_outcomes_success():
    assert summarize_counts({"passed": 1}, source="child")["ok"] is True

@pytest.mark.parametrize("label", ["PARAMETER_SENTINEL"], ids=["PARAMETER_SENTINEL"])
def test_wrong_outcomes_expectation(label):
    print("STDOUT_SENTINEL")
    assert summarize_counts({"failed": 1}, source=label)["ok"] is True, "ASSERTION_SENTINEL"

@pytest.fixture
def broken_oracle():
    raise RuntimeError("SETUP_SENTINEL")

def test_oracle_setup_error(broken_oracle):
    pass

def test_skip():
    pytest.skip("synthetic skipped oracle")
''', encoding="utf-8")
    env = dict(os.environ, PYTHONPATH=str(PYTHON_DIR),
               PYTEST_DISABLE_PLUGIN_AUTOLOAD="1", PYTEST_ADDOPTS="")
    command = [sys.executable, str(PYTHON_DIR / "test.py"), "--pytest", "--",
               str(fixture), "-c", os.devnull, "--rootdir", str(tmp_path),
               "--confcutdir", str(tmp_path), "-p", "conftest", "--oracle-mode=local", "-q"]
    plain_path = tmp_path / "plain-outcomes.json"
    plain = subprocess.run(command + ["--outcomes-json", str(plain_path)],
                           env=env, capture_output=True, text=True, timeout=60)
    reported = subprocess.run(command + ["--outcomes-json", str(evidence / "outcomes.json"),
                              "--junitxml", str(evidence / "junit.xml"), "-o", "junit_logging=all"],
                              env=env, capture_output=True, text=True, timeout=60)
    (evidence / "exit.json").write_text(json.dumps({"without_junit": plain.returncode,
                                                "with_junit": reported.returncode}), encoding="utf-8")
    # JUnit is evidence, never an exit-code normalizer: the failing native child
    # must remain failing with and without the report enabled.
    assert plain.returncode == reported.returncode == 1, plain.stdout + plain.stderr + reported.stdout + reported.stderr
    outcomes = json.loads((evidence / "outcomes.json").read_text(encoding="utf-8"))
    assert outcomes == json.loads(plain_path.read_text(encoding="utf-8"))
    assert outcomes["exitstatus"] == 1 and outcomes["ok"] is False
    assert outcomes["counts"] == {"passed": 1, "failed": 1, "skipped": 1,
                                  "xfailed": 0, "xpassed": 0, "error": 1}
    data = importer.read_bytes()
    assert hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest() == "dbc5b7d55005d6288c072a7612584d6170c216f4"
    spec = importlib.util.spec_from_file_location("oracle_junit_xprobe", importer)
    xprobe = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(xprobe)
    raw = (evidence / "junit.xml").read_text(encoding="utf-8")
    imported = xprobe.cases_from_junit(raw, repository="myon-bioinformatics/flutter_navigation_basic",
                                      report_id="controlled-oracle")
    assert imported["truncated"] is False
    cases = imported["cases"]
    assert {(c["value"]["test"], c["value"]["kind"]) for c in cases} == {
        ("test_wrong_outcomes_expectation", "failure"), ("test_oracle_setup_error", "error")}
    compact = xprobe.corpus_to_json(cases, jsonl=True)
    (evidence / "failure-identity.jsonl").write_text(compact, encoding="utf-8")
    assert all(c["context"]["commit_sha"] is None for c in cases)
    for sentinel in ("PARAMETER_SENTINEL", "STDOUT_SENTINEL", "ASSERTION_SENTINEL", "SETUP_SENTINEL"):
        assert sentinel in raw and sentinel not in compact



