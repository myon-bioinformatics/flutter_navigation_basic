"""Unit coverage for Actions summary helpers (no network required)."""

from __future__ import annotations

import sys
from pathlib import Path

_HERE = Path(__file__).resolve().parents[1]
if str(_HERE) not in sys.path:
    sys.path.insert(0, str(_HERE))

from actions_latest import ActionsSummary, CheckRow, summary_to_dict, write_local_summary


def test_summary_to_dict_classifies_failed_and_pending(tmp_path: Path) -> None:
    summary = ActionsSummary(
        branch="cursor/example",
        workflow="Flutter",
        run_id=123,
        head_sha="abc",
        conclusion="failure",
        url="https://example.test/run/123",
        checks=[
            CheckRow("gate", "completed", "success", None),
            CheckRow("shard 0", "completed", "failure", "https://example.test/job/1"),
            CheckRow("shard 1", "in_progress", None, None),
        ],
        source="test",
    )
    data = summary_to_dict(summary)
    assert data["failed"][0]["name"] == "shard 0"
    assert data["pending"][0]["name"] == "shard 1"

    out = tmp_path / "summary.json"
    write_local_summary(out, summary)
    assert out.is_file()
    assert "cursor/example" in out.read_text(encoding="utf-8")
