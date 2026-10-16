"""Outcome tally helpers (pytest-like status mix)."""

from __future__ import annotations

import json
from pathlib import Path

from outcomes import (
    counts_from_flutter_json_lines,
    counts_from_pytest_stats,
    format_counts_line,
    summarize_counts,
    write_outcomes_json,
)


def test_counts_from_pytest_stats_includes_xfail_family() -> None:
    stats = {
        "passed": [object(), object()],
        "failed": [object()],
        "skipped": [object(), object(), object()],
        "xfailed": [object()],
        "xpassed": [],
        "error": [],
    }
    counts = counts_from_pytest_stats(stats)
    assert counts == {
        "passed": 2,
        "failed": 1,
        "skipped": 3,
        "xfailed": 1,
        "xpassed": 0,
        "error": 0,
    }
    assert "xfailed=1" in format_counts_line(counts)


def test_flutter_json_maps_known_skip_to_xfailed() -> None:
    ndjson = "\n".join(
        [
            json.dumps(
                {
                    "type": "testStart",
                    "test": {
                        "id": 1,
                        "name": "loading suite",
                        "metadata": {"skip": False, "skipReason": None},
                    },
                }
            ),
            json.dumps(
                {
                    "type": "testDone",
                    "testID": 1,
                    "result": "success",
                    "skipped": False,
                    "hidden": True,
                }
            ),
            json.dumps(
                {
                    "type": "testStart",
                    "test": {
                        "id": 2,
                        "name": "works",
                        "metadata": {"skip": False, "skipReason": None},
                    },
                }
            ),
            json.dumps(
                {
                    "type": "testDone",
                    "testID": 2,
                    "result": "success",
                    "skipped": False,
                    "hidden": False,
                }
            ),
            json.dumps(
                {
                    "type": "testStart",
                    "test": {
                        "id": 3,
                        "name": "known gap",
                        "metadata": {
                            "skip": True,
                            "skipReason": "known: pattern catalogue not on latest-stable",
                        },
                    },
                }
            ),
            json.dumps(
                {
                    "type": "testDone",
                    "testID": 3,
                    "result": "success",
                    "skipped": True,
                    "hidden": False,
                }
            ),
            json.dumps(
                {
                    "type": "testStart",
                    "test": {
                        "id": 4,
                        "name": "plain skip",
                        "metadata": {"skip": True, "skipReason": "not in this env"},
                    },
                }
            ),
            json.dumps(
                {
                    "type": "testDone",
                    "testID": 4,
                    "result": "success",
                    "skipped": True,
                    "hidden": False,
                }
            ),
        ]
    )
    counts = counts_from_flutter_json_lines(ndjson)
    assert counts["passed"] == 1
    assert counts["xfailed"] == 1
    assert counts["skipped"] == 1
    assert counts["failed"] == 0


def test_flutter_json_malformed_lines_count_as_error() -> None:
    ndjson = "\n".join(
        [
            json.dumps(
                {
                    "type": "testStart",
                    "test": {
                        "id": 1,
                        "name": "works",
                        "metadata": {"skip": False, "skipReason": None},
                    },
                }
            ),
            json.dumps(
                {
                    "type": "testDone",
                    "testID": 1,
                    "result": "success",
                    "skipped": False,
                    "hidden": False,
                }
            ),
            "{not-json",
            "42",
            "",
        ]
    )
    counts = counts_from_flutter_json_lines(ndjson)
    assert counts["passed"] == 1
    assert counts["error"] == 2  # decode failure + non-object JSON
    summary = summarize_counts(counts, source="flutter-json")
    assert summary["ok"] is False


def test_flutter_json_only_garbage_is_not_ok() -> None:
    counts = counts_from_flutter_json_lines("truncated...\n{broken")
    assert counts == {
        "passed": 0,
        "failed": 0,
        "skipped": 0,
        "xfailed": 0,
        "xpassed": 0,
        "error": 2,
    }
    assert summarize_counts(counts, source="flutter-json")["ok"] is False


def test_write_outcomes_json_round_trip(tmp_path: Path) -> None:
    path = tmp_path / "outcomes.json"
    payload = summarize_counts(
        {"passed": 1, "failed": 0, "skipped": 2, "xfailed": 1, "xpassed": 0, "error": 0},
        source="pytest",
    )
    write_outcomes_json(path, payload)
    loaded = json.loads(path.read_text(encoding="utf-8"))
    assert loaded["ok"] is True
    assert loaded["counts"]["xfailed"] == 1
    assert loaded["total"] == 4
