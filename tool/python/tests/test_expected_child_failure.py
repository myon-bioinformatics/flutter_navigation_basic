import json
from pathlib import Path
import subprocess
import sys

PYTHON_DIR = Path(__file__).resolve().parents[1]
RUNNER = PYTHON_DIR / "expected_child_failure.py"


def _run(tmp_path, expected, child_code):
    return subprocess.run(
        [
            sys.executable,
            str(RUNNER),
            "--output-dir",
            str(tmp_path / "evidence"),
            "--expect-exit",
            str(expected),
            "--",
            sys.executable,
            "-c",
            child_code,
        ],
        capture_output=True,
        text=True,
    )


def test_expected_failure_is_recorded_without_failing_outer_test(tmp_path):
    result = _run(
        tmp_path,
        7,
        "import sys; print('intentional stdout'); print('intentional stderr', file=sys.stderr); raise SystemExit(7)",
    )
    assert result.returncode == 0
    evidence = tmp_path / "evidence"
    receipt = json.loads((evidence / "receipt.json").read_text(encoding="utf-8"))
    assert receipt["schema"] == "expected-child-failure/1"
    assert receipt["exit_code"] == 7
    assert receipt["expected_exit_codes"] == [7]
    assert receipt["matched_expectation"] is True
    assert receipt["command_executable"]
    assert receipt["argument_count"] == 2
    assert (evidence / "stdout.bin").read_bytes() == b"intentional stdout\n"
    assert (evidence / "stderr.bin").read_bytes() == b"intentional stderr\n"


def test_unexpected_child_result_fails_outer_contract(tmp_path):
    result = _run(tmp_path, 7, "raise SystemExit(3)")
    assert result.returncode == 1
    receipt = json.loads(
        (tmp_path / "evidence/receipt.json").read_text(encoding="utf-8")
    )
    assert receipt["exit_code"] == 3
    assert receipt["matched_expectation"] is False
