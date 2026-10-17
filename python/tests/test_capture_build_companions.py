"""Actual Python/Node execution, with an explicit fake build instead of an SDK."""
import json
from pathlib import Path
import subprocess
import sys

import pytest
import yaml

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import capture_build_companions as cli

ROOT = Path(__file__).resolve().parents[2]


@pytest.mark.parametrize("build_exit", [0, 7])
def test_current_build_exit_and_fresh_companions_are_independent(tmp_path, build_exit):
    command = [sys.executable, "-S", "-c", f"import sys; print('actual build fixture'); sys.exit({build_exit})"]
    result = cli.capture(ROOT, tmp_path, "ios", command)
    assert result["passed"] is (build_exit == 0)
    assert result["results"][0]["returncode"] == build_exit
    assert result["results"][0]["command"] == command
    assert (tmp_path / "build.stdout.log").read_bytes() == b"actual build fixture\n"
    controls = result["results"][1:]
    assert len(controls) == 26 and all(row["passed"] for row in controls)
    assert {row["target"] for row in controls} == {"python", "node"}
    assert all(row["input"] is not None and "stderr_sha256" in row for row in controls)
    assert result["context"]["build_target"] == "ios"  # target does not impersonate host
    assert result["collector_environment"]["platform"] == sys.platform
    assert result["context"]["native_app_runtime_verified"] is False
    assert result["native_equivalence_verified"] is False


def test_build_timeout_still_collects_companions(tmp_path):
    result = cli.capture(ROOT, tmp_path, "web",
                         [sys.executable, "-S", "-c", "import time; time.sleep(10)"], timeout=0.1)
    assert not result["passed"]
    assert result["results"][0]["error_type"] == "TimeoutExpired"
    assert all(row["passed"] for row in result["results"][1:])


def test_json_only_cli_keeps_build_failure_and_exact_command(tmp_path):
    command = [sys.executable, "-S", "-c", "import sys; sys.exit(23)"]
    process = subprocess.run([sys.executable, "-S", str(ROOT / "python/capture_build_companions.py"),
        "--target", "web", "--output", str(tmp_path), "--build-command", json.dumps(command)],
        capture_output=True, text=True, timeout=30)
    assert process.returncode == 23
    receipt = json.loads((tmp_path / "receipt.json").read_text())
    assert receipt["junit_written"] is False and receipt["passed"] is False
    assert receipt["results"][0]["command"] == command
    assert len(receipt["context"]["source_sha256"]) == 5


def test_missing_companion_is_not_accepted(monkeypatch, tmp_path):
    import capture_native_errors as native
    original = native.invoke
    def missing_node(command, root, out, name, **kwargs):
        if command[0] == "node":
            command = ["missing-node-for-companion-test"]
        return original(command, root, out, name, **kwargs)
    monkeypatch.setattr(native, "invoke", missing_node)
    result = cli.capture(ROOT, tmp_path, "web", [sys.executable, "-S", "-c", "pass"])
    assert not result["passed"]
    assert all(not row["passed"] and row["error_type"] for row in result["results"][1:] if row["target"] == "node")


def test_existing_workflow_builds_use_companions_and_keep_native_scope():
    expected = {"dart.yml": 2, "flutter-pages.yml": 1, "ios-native.yml": 2,
                "diagnostics-evidence.yml": 1, "structure-refactor-validation.yml": 1,
                "non-dart.yml": 1}
    for name, count in expected.items():
        workflow = yaml.safe_load((ROOT / ".github/workflows" / name).read_text())
        steps = [step for job in workflow["jobs"].values() for step in job.get("steps", [])]
        builders = [step for step in steps if step.get("uses") == "./.github/actions/build-companions"]
        assert len(builders) == count, name
        assert not any("flutter build " in step.get("run", "") for step in steps), name
        for step in builders:
            assert json.loads(step["with"]["command"])[:2] == ["flutter", "build"]
    action = yaml.safe_load((ROOT / ".github/actions/build-companions/action.yml").read_text())
    assert action["runs"]["steps"][-1]["if"] == "always()"
    assert "observed-failures.xml" in (ROOT / "python/capture_build_companions.py").read_text()
