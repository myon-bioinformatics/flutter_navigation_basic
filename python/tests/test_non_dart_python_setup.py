"""Static contract: locked vendor checks use the declared Python, not the runner."""
from copy import deepcopy
from pathlib import Path
import re

import pytest
import yaml

ROOT = Path(__file__).resolve().parents[2]
WORKFLOW = ROOT / ".github/workflows/non-dart.yml"
SETUP = "astral-sh/setup-uv@68559e99cc807c1eb7e9238fd43a15bba460eec2"


def _assert_vendor_python_setup(job):
    steps = job["steps"]
    setups = [step for step in steps if step.get("uses", "").startswith("astral-sh/setup-uv@")]
    assert len(setups) == 1
    setup = setups[0]
    assert setup["uses"] == SETUP
    assert setup["with"] == {
        "version": "0.13.3",
        "python-version": "3.15",
        "activate-environment": True,
        "enable-cache": False,
    }
    assert setup.get("if") is None
    assert setup.get("continue-on-error", False) is False
    consumers = [step for step in steps
                 if re.search(r"(?m)^\s*python(?:3)?(?:\s|$)", step.get("run", ""))]
    assert consumers
    assert all(steps.index(setup) < steps.index(step) for step in consumers)


def test_locked_vendor_python_setup_precedes_every_plain_python_command():
    workflow = yaml.safe_load(WORKFLOW.read_text(encoding="utf-8"))
    _assert_vendor_python_setup(workflow["jobs"]["python-vendor-locked"])


@pytest.mark.parametrize("mutation", ["late", "inactive", "conditional", "ignored-failure"])
def test_vendor_setup_contract_rejects_runner_python_fallback(mutation):
    workflow = yaml.safe_load(WORKFLOW.read_text(encoding="utf-8"))
    job = deepcopy(workflow["jobs"]["python-vendor-locked"])
    setup = next(step for step in job["steps"] if step.get("uses") == SETUP)
    if mutation == "late":
        job["steps"].remove(setup)
        job["steps"].append(setup)
    elif mutation == "inactive":
        setup["with"]["activate-environment"] = False
    elif mutation == "conditional":
        setup["if"] = "false"
    else:
        setup["continue-on-error"] = True
    with pytest.raises(AssertionError):
        _assert_vendor_python_setup(job)
