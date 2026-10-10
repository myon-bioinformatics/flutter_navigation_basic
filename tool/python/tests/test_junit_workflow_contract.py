"""Guard the real workflow's failure/evidence contract, using test-only PyYAML."""
from copy import deepcopy
import json
from pathlib import Path

import pytest
import yaml

ROOT = Path(__file__).resolve().parents[3]
WORKFLOW = ROOT / ".github/workflows/non-dart.yml"
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
    collector = workflow["jobs"]["junit-identity"]
    assert collector["needs"] == ["changes", "python-pytest"]
    assert collector["if"] == (
        "always() && (needs.changes.outputs.python == 'true' "
        "|| needs.changes.outputs.workflow == 'true')"
    )
    assert collector.get("continue-on-error", False) is False
    assert collector["uses"] == COLLECTOR
    reports = json.loads(collector["with"]["expected-reports"])
    assert isinstance(reports, list) and len(reports) == 2
    assert set(reports) == {
        "junit-python-3.12/python-3.12.xml",
        "junit-controlled-python-3.12/junit.xml",
    }


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
         json.dumps(["junit-python-3.12/python-3.12.xml",
                     "junit-controlled-python-3.12/junit.xml", "unexpected/report.xml"])),
    ]
    for name in ("junit-python-3.12", "junit-controlled-python-3.12"):
        index = producer["steps"].index(_upload(producer, name))
        path = job_path + ("steps", index)
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
