"""Unit coverage for Actions summary helpers (no network required)."""

from __future__ import annotations

import sys
from pathlib import Path

_HERE = Path(__file__).resolve().parents[1]
if str(_HERE) not in sys.path:
    sys.path.insert(0, str(_HERE))

from actions_latest import (
    ActionsSummary,
    CheckRow,
    evaluate_summary,
    summary_to_dict,
    write_local_summary,
)


def _summary(**kwargs) -> ActionsSummary:
    base = dict(
        branch="cursor/example",
        workflow="Flutter",
        run_id=123,
        head_sha="abc123",
        conclusion="success",
        url="https://example.test/run/123",
        checks=[
            CheckRow("gate", "completed", "success", None),
            CheckRow("shard 0", "completed", "failure", "https://example.test/job/1"),
            CheckRow("shard 1", "in_progress", None, None),
        ],
        source="test",
    )
    base.update(kwargs)
    return ActionsSummary(**base)


def test_summary_to_dict_classifies_failed_and_pending(tmp_path: Path) -> None:
    summary = _summary()
    data = summary_to_dict(summary, allow_stale=True, expected_sha="abc123")
    assert data["failed"][0]["name"] == "shard 0"
    assert data["pending"][0]["name"] == "shard 1"

    out = tmp_path / "summary.json"
    write_local_summary(out, summary)
    assert out.is_file()
    assert "cursor/example" in out.read_text(encoding="utf-8")


def test_evaluate_summary_rejects_stale_sha_by_default() -> None:
    summary = _summary(head_sha="oldsha", conclusion="success")
    code, reasons = evaluate_summary(summary, expected_sha="newsha")
    assert code == 3
    assert any("stale run" in reason for reason in reasons)


def test_evaluate_summary_allow_stale_overrides_sha_mismatch() -> None:
    summary = _summary(head_sha="oldsha", conclusion="success")
    code, reasons = evaluate_summary(
        summary,
        allow_stale=True,
        expected_sha="newsha",
    )
    assert code == 0
    assert any("stale run" in reason for reason in reasons)


def test_evaluate_summary_rejects_cancelled_conclusion() -> None:
    summary = _summary(conclusion="cancelled")
    code, reasons = evaluate_summary(summary, expected_sha="abc123")
    assert code == 1
    assert any("cancelled" in reason for reason in reasons)


def test_evaluate_summary_rejects_timed_out_conclusion() -> None:
    summary = _summary(conclusion="timed_out")
    code, _reasons = evaluate_summary(summary, expected_sha="abc123")
    assert code == 1


def test_evaluate_summary_success_and_fresh_is_zero() -> None:
    summary = _summary(head_sha="abc123", conclusion="success", checks=[])
    code, reasons = evaluate_summary(summary, expected_sha="abc123")
    assert code == 0
    assert reasons == []
