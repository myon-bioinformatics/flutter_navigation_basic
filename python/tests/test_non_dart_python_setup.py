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
        # The uv cache is restored on pull requests and saved only on main.
        "enable-cache": True,
        "save-cache": "${{ github.ref == 'refs/heads/main' }}",
        "prune-cache": True,
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


CACHE_JOBS = (
    ('ci.yml', 'python-oracle-fallback'),
    ('non-dart.yml', 'pattern-boundary'),
    ('non-dart.yml', 'python-vendor-locked'),
    ('non-dart.yml', 'python-pytest'),
    ('structure-refactor-validation.yml', 'python'),
)


def _assert_locked_cache_policy(job):
    steps = job['steps']
    setups = [step for step in steps if step.get('uses', '').startswith('astral-sh/setup-uv@')]
    assert len(setups) == 1
    setup = setups[0]
    assert setup['uses'] == SETUP
    assert setup['with'] == {
        'version': '0.13.3',
        'python-version': '3.15',
        'activate-environment': True,
        'enable-cache': True,
        # Main-ref saves include explicit main dispatches; PR refs restore only.
        'save-cache': "${{ github.ref == 'refs/heads/main' }}",
        'prune-cache': True,
    }
    assert setup.get('if') is None
    assert setup.get('continue-on-error', False) is False
    installs = [step for step in steps
                if step.get('run', '').strip() == 'uv sync --locked --project python']
    assert len(installs) == 1
    install = installs[0]
    assert steps.index(setup) < steps.index(install)
    assert install.get('if') is None
    assert install.get('continue-on-error', False) is False


@pytest.mark.parametrize('filename,job_name', CACHE_JOBS)
def test_all_five_locked_jobs_keep_main_save_pr_restore_policy(filename, job_name):
    workflow = yaml.safe_load((ROOT / '.github/workflows' / filename).read_text())
    _assert_locked_cache_policy(workflow['jobs'][job_name])


@pytest.mark.parametrize('filename,job_name', CACHE_JOBS)
@pytest.mark.parametrize('mutation', ['save-on-pr', 'disabled', 'no-prune', 'wrong-version', 'unlocked', 'ignored-install'])
def test_all_five_cache_contracts_reject_weakened_policy(filename, job_name, mutation):
    workflow = yaml.safe_load((ROOT / '.github/workflows' / filename).read_text())
    job = deepcopy(workflow['jobs'][job_name])
    setup = next(step for step in job['steps'] if step.get('uses') == SETUP)
    install = next(step for step in job['steps'] if step.get('run', '').strip() == 'uv sync --locked --project python')
    if mutation == 'save-on-pr': setup['with']['save-cache'] = True
    elif mutation == 'disabled': setup['with']['enable-cache'] = False
    elif mutation == 'no-prune': setup['with']['prune-cache'] = False
    elif mutation == 'wrong-version': setup['with']['version'] = 'latest'
    elif mutation == 'unlocked': install['run'] = 'uv sync --project python'
    else: install['continue-on-error'] = True
    with pytest.raises(AssertionError):
        _assert_locked_cache_policy(job)
