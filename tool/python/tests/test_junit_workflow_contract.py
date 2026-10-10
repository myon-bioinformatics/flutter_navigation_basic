"""Guard the real workflow's failure/evidence contract, using test-only PyYAML."""
from copy import deepcopy
import json
import os
from pathlib import Path
import subprocess
import tempfile

import pytest
import yaml

ROOT = Path(__file__).resolve().parents[3]
WORKFLOW = ROOT / ".github/workflows/non-dart.yml"
REFACTOR = ROOT / ".github/workflows/structure-refactor-validation.yml"
COLLECTOR = (
    "myon-bioinformatics/myon-bioinformatics/.github/workflows/"
    "reusable-junit-identity.yml@4dfda95d6573250477f991a0421fa6acb9bc0258"
)
COMMAND = (
    'python tool/python/test.py --pytest -- --oracle-mode=local --outcomes-json '
    '"$GITHUB_WORKSPACE/build/diagnostics/python-oracle/pytest_outcomes.json" '
    '--junitxml="$GITHUB_WORKSPACE/build/test-results/python-3.12.xml"'
)


def _step(job, name):
    matches = [step for step in job["steps"] if step.get("name") == name]
    assert len(matches) == 1, name
    return matches[0]


def _upload(job, name):
    matches = [step for step in job["steps"]
               if step.get("uses", "").startswith("actions/upload-artifact@")
               and step.get("with", {}).get("name") == name]
    assert len(matches) == 1, name
    return matches[0]


PYTHON_REPORTS = [
    "junit-python-3.12/python-3.12.xml",
    "junit-controlled-python-3.12/junit.xml",
]
PLAYWRIGHT_REPORTS = [
    "junit-playwright-e2e/playwright-portable.xml",
    "junit-playwright-e2e/playwright-interaction-portable.xml",
    "junit-playwright-e2e/playwright-interaction-gesture.xml",
]


def _plan(workflow, *, python, playwright):
    """Run the real planning step the way Actions would, minus ${{ }} expressions."""
    step = next(item for item in workflow["jobs"]["junit-plan"]["steps"]
                if item.get("id") == "plan")
    with tempfile.TemporaryDirectory() as directory:
        output = Path(directory) / "outputs"
        output.write_text("", encoding="utf-8")
        subprocess.run(
            ["bash", "-c", step["run"]], check=True, capture_output=True, text=True,
            env={**os.environ, "GITHUB_OUTPUT": str(output),
                 "PYTHON": str(python).lower(), "PLAYWRIGHT": str(playwright).lower()},
            timeout=10,
        )
        values = dict(line.split("=", 1) for line in output.read_text(encoding="utf-8").splitlines())
    return values["run"], json.loads(values["reports"])


def _assert_playwright_producer(workflow):
    producer = workflow["jobs"]["playwright"]
    run = _step(producer, "Serve web build and run Playwright")
    assert producer.get("continue-on-error", False) is False
    assert run.get("continue-on-error", False) is False
    # Each invocation must own one expected file; a shared path would overwrite.
    for report in PLAYWRIGHT_REPORTS:
        assert run["run"].count("PLAYWRIGHT_JUNIT_OUTPUT_FILE=\"$junit_dir/" + report.split("/")[1] + "\"") == 1, report
    upload = _upload(producer, "junit-playwright-e2e")
    assert producer["steps"].index(run) < producer["steps"].index(upload)
    assert upload.get("if") == "always()"
    assert upload.get("continue-on-error", False) is False
    assert upload["with"]["path"].strip() == "build/test-results/playwright-*.xml"
    assert upload["with"]["if-no-files-found"] == "error"
    assert upload["with"]["retention-days"] == 14


def _assert_contract(workflow):
    producer = workflow["jobs"]["python-pytest"]
    run = _step(producer, "Run pytest")
    assert producer.get("continue-on-error", False) is False
    assert run.get("continue-on-error", False) is False
    assert run.get("if") is None
    # The exact normalized command rejects || true, set +e and trailing exit 0.
    assert " ".join(run["run"].split()) == COMMAND
    assert run["env"]["FLUTTER_FAILURE_EVIDENCE"] == (
        "${{ github.workspace }}/build/controlled-failure"
    )
    for name, path in (
        ("junit-python-3.12", "build/test-results/python-3.12.xml"),
        ("junit-controlled-python-3.12", "build/controlled-failure/"),
    ):
        upload = _upload(producer, name)
        assert producer["steps"].index(run) < producer["steps"].index(upload)
        assert upload.get("if") == "always()"
        assert upload.get("continue-on-error", False) is False
        assert upload["with"]["path"].strip() == path
        assert upload["with"]["if-no-files-found"] == "error"
        assert upload["with"]["retention-days"] == 14
    _assert_playwright_producer(workflow)
    plan = workflow["jobs"]["junit-plan"]
    assert plan["needs"] == "changes"
    plan_step = next(item for item in plan["steps"] if item.get("id") == "plan")
    assert plan_step["env"] == {
        "PYTHON": "${{ needs.changes.outputs.python == 'true' || needs.changes.outputs.workflow == 'true' }}",
        "PLAYWRIGHT": "${{ needs.changes.outputs.playwright == 'true' }}",
    }
    # The plan must mirror the producers' own `if:` so that a skipped lane is not
    # reported as a missing report, and a selected lane can never go unchecked.
    assert workflow["jobs"]["python-pytest"]["if"] == (
        "needs.changes.outputs.python == 'true' || needs.changes.outputs.workflow == 'true'"
    )
    assert workflow["jobs"]["playwright"]["if"] == "needs.changes.outputs.playwright == 'true'"
    assert _plan(workflow, python=True, playwright=False) == ("true", PYTHON_REPORTS)
    assert _plan(workflow, python=False, playwright=True) == ("true", PLAYWRIGHT_REPORTS)
    assert _plan(workflow, python=True, playwright=True) == ("true", PYTHON_REPORTS + PLAYWRIGHT_REPORTS)
    assert _plan(workflow, python=False, playwright=False) == ("false", [])
    collector = workflow["jobs"]["junit-identity"]
    assert collector["needs"] == ["changes", "junit-plan", "python-pytest", "playwright"]
    assert collector["if"] == "always() && needs.junit-plan.outputs.run == 'true'"
    assert collector.get("continue-on-error", False) is False
    assert collector["uses"] == COLLECTOR
    assert collector["with"]["expected-reports"] == "${{ needs.junit-plan.outputs.reports }}"


def test_failure_evidence_workflow_contract():
    _assert_contract(yaml.safe_load(WORKFLOW.read_text(encoding="utf-8")))


@pytest.mark.parametrize("event", ["pull_request", "push"])
@pytest.mark.parametrize("asset", ["window_034.json", "structure_045.json", "command_051.json"])
def test_collection_asset_only_changes_select_python_junit_without_browser(
    event, asset, classify_workflow_asset,
):
    # BaseLoader keeps `on` as a key instead of YAML 1.1's boolean True.
    workflow = yaml.load(WORKFLOW.read_text(encoding="utf-8"), Loader=yaml.BaseLoader)
    assert "assets/data_processing/**" in workflow["on"][event]["paths"]
    outputs = classify_workflow_asset(workflow, f"assets/data_processing/{asset}", event)
    assert outputs["python"] == "true"
    assert outputs["workflow"] == "false"
    assert outputs["playwright"] == "false"
    assert outputs["e2e"] == "false"
    assert workflow["jobs"]["python-pytest"]["if"] == (
        "needs.changes.outputs.python == 'true' || needs.changes.outputs.workflow == 'true'"
    )
    # The existing contract verifies that this selected producer emits JUnit
    # and that the collector still runs even when a drift assertion fails.
    _assert_contract(yaml.safe_load(WORKFLOW.read_text(encoding="utf-8")))


def test_failure_evidence_contract_rejects_unsafe_mutations():
    workflow = yaml.safe_load(WORKFLOW.read_text(encoding="utf-8"))
    _assert_contract(workflow)  # A broken baseline must not make all mutants pass.
    producer = workflow["jobs"]["python-pytest"]
    run_index = producer["steps"].index(_step(producer, "Run pytest"))
    job_path = ("jobs", "python-pytest")
    run_path = job_path + ("steps", run_index)
    collector_path = ("jobs", "junit-identity")
    mutations = [
        ("job masks failure", job_path + ("continue-on-error",), True),
        ("step masks failure", run_path + ("continue-on-error",), True),
        ("shell masks failure", run_path + ("run",), COMMAND + " || true"),
        ("shell disables fail-fast", run_path + ("run",), "set +e\n" + COMMAND),
        ("collector skips failed producer", collector_path + ("if",), "success()"),
        ("collector loses dependency", collector_path + ("needs",), []),
        ("collector missing report", collector_path + ("with", "expected-reports"), "[]"),
        ("collector unexpected report", collector_path + ("with", "expected-reports"),
         json.dumps(PYTHON_REPORTS + ["unexpected/report.xml"])),
        ("collector ignores the plan", collector_path + ("with", "expected-reports"),
         json.dumps(PYTHON_REPORTS + PLAYWRIGHT_REPORTS)),
        ("collector stops waiting for playwright", collector_path + ("needs",),
         ["changes", "junit-plan", "python-pytest"]),
        ("collector runs without a plan", collector_path + ("if",), "always()"),
        ("plan ignores playwright selection", ("jobs", "junit-plan", "steps", 0, "env", "PLAYWRIGHT"), "false"),
    ]
    for name in ("junit-python-3.12", "junit-controlled-python-3.12"):
        index = producer["steps"].index(_upload(producer, name))
        path = job_path + ("steps", index)
        mutations.extend([
            (name + " loses always", path + ("if",), None),
            (name + " ignores missing XML", path + ("with", "if-no-files-found"), "ignore"),
            (name + " retains raw for 90 days", path + ("with", "retention-days"), 90),
        ])
    playwright = workflow["jobs"]["playwright"]
    for name in ("junit-playwright-e2e",):
        index = playwright["steps"].index(_upload(playwright, name))
        path = ("jobs", "playwright", "steps", index)
        mutations.extend([
            (name + " loses always", path + ("if",), None),
            (name + " ignores missing XML", path + ("with", "if-no-files-found"), "ignore"),
            (name + " retains raw for 90 days", path + ("with", "retention-days"), 90),
        ])
    for label, path, value in mutations:
        mutated = deepcopy(workflow)
        target = mutated
        for key in path[:-1]:
            target = target[key]
        target[path[-1]] = value
        try:
            _assert_contract(mutated)
        except AssertionError:
            continue
        pytest.fail(f"unsafe workflow mutation escaped: {label}")


def test_refactor_smoke_collector_matches_its_producers():
    workflow = yaml.safe_load(REFACTOR.read_text(encoding="utf-8"))
    collector = workflow["jobs"]["junit-identity"]
    assert collector["uses"] == COLLECTOR
    assert collector["if"] == "always()"
    assert set(collector["needs"]) == {"python", "flutter", "node"}
    assert collector.get("continue-on-error", False) is False
    reports = json.loads(collector["with"]["expected-reports"])
    uploads = {
        step["with"]["name"]: step
        for job in workflow["jobs"].values() for step in job.get("steps", [])
        if step.get("uses", "").startswith("actions/upload-artifact@")
        and step["with"]["name"].startswith("junit-")
    }
    # Same set both ways: no expected report without a producer, no producer the
    # collector would flag as an unexpected extra.
    assert {report.split("/")[0] for report in reports} == set(uploads)
    for report in reports:
        artifact, filename = report.split("/")
        step = uploads[artifact]
        assert step.get("if") == "always()", artifact
        assert step["with"]["if-no-files-found"] == "error", artifact
        assert filename in step["with"]["path"], artifact
