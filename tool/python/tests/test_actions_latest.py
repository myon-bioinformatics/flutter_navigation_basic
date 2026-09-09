"""Optional verification against the latest GitHub Actions run."""

from __future__ import annotations

import pytest


@pytest.mark.actions_latest
def test_latest_actions_run_is_green(actions_summary) -> None:
    assert actions_summary.get("run_id") is not None, "No Actions run found for branch/workflow"
    conclusion = actions_summary.get("conclusion")
    assert conclusion == "success", (
        f"Latest Actions conclusion is {conclusion!r}: {actions_summary.get('url')}"
    )
    failed = actions_summary.get("failed") or []
    assert not failed, f"Failed jobs: {failed}"
