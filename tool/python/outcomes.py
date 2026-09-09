"""Pytest / Flutter test outcome tallies (passed, failed, skipped, xfail, …).

Stdlib-only helpers so CI receipts and local runs can surface a pytest-like
status mix without extra reporters.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Mapping

# Stable keys aligned with pytest terminalreporter.stats + Flutter JSON reporter.
OUTCOME_KEYS = (
    "passed",
    "failed",
    "skipped",
    "xfailed",
    "xpassed",
    "error",
)


def empty_counts() -> dict[str, int]:
    return {key: 0 for key in OUTCOME_KEYS}


def counts_from_pytest_stats(stats: Mapping[str, Any]) -> dict[str, int]:
    """Tally outcomes from pytest TerminalReporter.stats."""
    counts = empty_counts()
    for key in OUTCOME_KEYS:
        entries = stats.get(key) or []
        counts[key] = len(entries)
    return counts


def counts_from_flutter_json_lines(lines: list[str] | str) -> dict[str, int]:
    """Tally Flutter/`package:test` JSON reporter events.

    Flutter has success / failure / error / skip. There is no native xfail;
    skip reasons that start with ``known:`` or ``xfail:`` are counted as
    ``xfailed`` so catalogues can mark known gaps without failing CI.
    """
    if isinstance(lines, str):
        raw_lines = lines.splitlines()
    else:
        raw_lines = lines

    starts: dict[int, dict[str, Any]] = {}
    counts = empty_counts()

    for line in raw_lines:
        line = line.strip()
        if not line:
            continue
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        kind = event.get("type")
        if kind == "testStart":
            test = event.get("test") or {}
            tid = test.get("id")
            if isinstance(tid, int):
                starts[tid] = test
        elif kind == "testDone":
            if event.get("hidden"):
                continue
            tid = event.get("testID")
            meta = starts.get(tid) if isinstance(tid, int) else None
            name = (meta or {}).get("name") or ""
            if isinstance(name, str) and name.startswith("loading "):
                continue
            result = event.get("result")
            skipped = bool(event.get("skipped"))
            skip_reason = ""
            if meta:
                skip_reason = str((meta.get("metadata") or {}).get("skipReason") or "")
            reason_l = skip_reason.lower()
            known = reason_l.startswith("known:") or reason_l.startswith("xfail:")
            if skipped or result == "skipped":
                if known:
                    counts["xfailed"] += 1
                else:
                    counts["skipped"] += 1
            elif result == "success":
                counts["passed"] += 1
            elif result == "error":
                counts["error"] += 1
            else:
                # failure / unexpected
                counts["failed"] += 1
    return counts


def load_flutter_json_file(path: Path) -> dict[str, int]:
    text = path.read_text(encoding="utf-8")
    # file-reporter may be NDJSON or a single JSON stream of lines
    return counts_from_flutter_json_lines(text)


def summarize_counts(counts: Mapping[str, int], *, source: str) -> dict[str, Any]:
    total = sum(int(counts.get(k, 0)) for k in OUTCOME_KEYS)
    return {
        "source": source,
        "counts": {k: int(counts.get(k, 0)) for k in OUTCOME_KEYS},
        "total": total,
        "ok": int(counts.get("failed", 0)) == 0 and int(counts.get("error", 0)) == 0,
    }


def write_outcomes_json(path: Path, payload: Mapping[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def format_counts_line(counts: Mapping[str, int]) -> str:
    parts = [f"{k}={counts.get(k, 0)}" for k in OUTCOME_KEYS]
    return " ".join(parts)
