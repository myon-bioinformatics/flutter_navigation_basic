"""Pytest switches for local oracles vs Actions-latest verification.

Uses stdlib + allowlisted pytest only. Prefer
`python3 tool/python/test.py --actions-latest` for day-to-day CI status;
use `--oracle-mode=actions` when you want that assertion inside pytest.

Also writes a pytest-like outcomes receipt (passed/failed/skipped/xfailed/
xpassed/error) when `--outcomes-json` is set or when running under CI.
"""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path

import pytest

_HERE = Path(__file__).resolve().parent
if str(_HERE) not in sys.path:
    sys.path.insert(0, str(_HERE))

from outcomes import (  # noqa: E402
    counts_from_pytest_stats,
    format_counts_line,
    summarize_counts,
    write_outcomes_json,
)

_REPO_ROOT = _HERE.parents[1]
_DEFAULT_OUTCOMES = _REPO_ROOT / "build" / "diagnostics" / "python-oracle" / "pytest_outcomes.json"


def pytest_addoption(parser: pytest.Parser) -> None:
    group = parser.getgroup("repository oracles")
    group.addoption(
        "--oracle-mode",
        action="store",
        default="local",
        choices=("local", "actions", "both"),
        help=(
            "local: calculation oracles only (default). "
            "actions: assert latest GitHub Actions run is green. "
            "both: local oracles + Actions assertion."
        ),
    )
    group.addoption(
        "--actions-branch",
        action="store",
        default=None,
        help="Branch for --oracle-mode=actions (default: current git branch)",
    )
    group.addoption(
        "--actions-workflow",
        action="store",
        default="Flutter",
        help='Workflow name for Actions mode (default: "Flutter")',
    )
    group.addoption(
        "--actions-summary",
        action="store",
        default=None,
        help="Optional archived Actions summary JSON (offline mode)",
    )
    group.addoption(
        "--outcomes-json",
        action="store",
        default=None,
        help=(
            "Write passed/failed/skipped/xfailed/xpassed/error counts JSON. "
            "Defaults to build/diagnostics/python-oracle/pytest_outcomes.json "
            "when GITHUB_ACTIONS=true."
        ),
    )


def pytest_configure(config: pytest.Config) -> None:
    config.addinivalue_line(
        "markers",
        "known(reason): known limitation; prefer pytest.mark.xfail(reason='known: …')",
    )


def pytest_collection_modifyitems(config: pytest.Config, items: list[pytest.Item]) -> None:
    mode = config.getoption("--oracle-mode")
    skip_local = pytest.mark.skip(reason="skipped by --oracle-mode=actions")
    skip_actions = pytest.mark.skip(reason="skipped by --oracle-mode=local")
    for item in items:
        if "actions_latest" in item.keywords and mode == "local":
            item.add_marker(skip_actions)
        if "actions_latest" not in item.keywords and mode == "actions":
            item.add_marker(skip_local)


@pytest.fixture(scope="session")
def actions_summary(pytestconfig: pytest.Config):
    """Load Actions summary from artifact file or live gh/API lookup."""
    summary_path = pytestconfig.getoption("--actions-summary")
    if summary_path:
        path = Path(summary_path)
        return json.loads(path.read_text(encoding="utf-8"))

    mode = pytestconfig.getoption("--oracle-mode")
    if mode == "local":
        pytest.skip("Actions summary not requested in local mode")

    from actions_latest import fetch_latest_summary, summary_to_dict

    summary = fetch_latest_summary(
        branch=pytestconfig.getoption("--actions-branch"),
        workflow=pytestconfig.getoption("--actions-workflow") or None,
    )
    return summary_to_dict(summary, allow_stale=False)


def _outcomes_path(config: pytest.Config) -> Path | None:
    explicit = config.getoption("--outcomes-json")
    if explicit:
        return Path(explicit)
    if os.environ.get("GITHUB_ACTIONS") == "true":
        return _DEFAULT_OUTCOMES
    return None


@pytest.hookimpl(trylast=True)
def pytest_terminal_summary(
    terminalreporter: pytest.TerminalReporter,
    exitstatus: int,
    config: pytest.Config,
) -> None:
    path = _outcomes_path(config)
    if path is None:
        return
    counts = counts_from_pytest_stats(terminalreporter.stats)
    payload = summarize_counts(counts, source="pytest")
    payload["exitstatus"] = int(exitstatus)
    write_outcomes_json(path, payload)
    terminalreporter.write_line(f"outcomes_json: {path}")
    terminalreporter.write_line(f"outcomes: {format_counts_line(counts)}")
