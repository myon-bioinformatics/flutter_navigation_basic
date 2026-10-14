"""Optional verification against the latest GitHub Actions run."""

from __future__ import annotations

import pytest


@pytest.mark.actions_latest
def test_latest_actions_run_is_green_and_fresh(actions_summary) -> None:
    assert actions_summary.get("run_id") is not None, "No Actions run found for branch/workflow"
    assert actions_summary.get("conclusion") == "success", (
        f"Latest Actions conclusion is {actions_summary.get('conclusion')!r}: "
        f"{actions_summary.get('url')}"
    )
    assert actions_summary.get("fresh") is True, (
        "Actions run SHA is stale versus current HEAD; "
        f"run={actions_summary.get('head_sha')} expected={actions_summary.get('expected_sha')}"
    )
    assert actions_summary.get("evaluation_exit_code") == 0
    failed = actions_summary.get("failed") or []
    assert not failed, f"Failed jobs: {failed}"
