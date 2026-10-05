#!/usr/bin/env python3
"""Validate screenshot evidence by project identity, not by file count.

Each successful test attempt writes a metadata JSON file next to its PNG::

    {"runtime": "node", "project": "mobile-webkit", "stage": "complete", "artifact": "evidence.png"}

``artifact`` is a file name relative to the metadata file. This script reads
every metadata file under DIR that matches ``--pattern`` and fails unless each
``--expect`` project (exact name) has at least one ``complete`` record whose
artifact is a valid PNG. Every ``complete`` record found is validated,
including retry attempts (``SUCCESS_COUNT_VS_RETRY_ARTIFACTS``). A missing
project is named even when the evidence of other projects exists. When the
metadata records ``width``/``height``, they must match the PNG header.

Stdlib only; runs under ``python -S``.

Exit codes: 0 = every expected project has valid evidence; 1 = missing or
invalid evidence; 2 = usage error.
"""
from __future__ import annotations

import argparse
import importlib.util
import json
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location("check_png", Path(__file__).with_name("check_png.py"))
check_png = importlib.util.module_from_spec(_spec)
assert _spec.loader
_spec.loader.exec_module(check_png)


def check(directory: Path, pattern: str, expected: list[str]) -> tuple[list[str], list[str], list[str]]:
    """Return ``(ok, notes, problems)`` lines; the evidence is valid when ``problems`` is empty."""
    ok: list[str] = []
    notes: list[str] = []
    problems: list[str] = []
    counts: dict[str, int] = {}
    if not directory.is_dir():
        problems.append(f"{directory}: no such directory")
    for meta in sorted(directory.glob(pattern)) if directory.is_dir() else []:
        if not meta.is_file():
            continue
        try:
            data = json.loads(meta.read_text(encoding="utf-8"))
        except (OSError, UnicodeDecodeError, json.JSONDecodeError) as exc:
            problems.append(f"{meta}: unreadable metadata: {exc}")
            continue
        project = data.get("project") if isinstance(data, dict) else None
        if not isinstance(project, str) or not project:
            problems.append(f'{meta}: metadata has no "project"')
            continue
        if data.get("stage") != "complete":
            notes.append(f"{meta}: {project} attempt ended at stage {data.get('stage')!r}; not counted")
            continue
        artifact = data.get("artifact")
        if not isinstance(artifact, str) or not artifact:
            problems.append(f'{meta}: complete record for {project} has no "artifact"')
            continue
        png = meta.parent / artifact
        try:
            width, height = check_png.dimensions(png.read_bytes())
        except (OSError, ValueError) as exc:
            problems.append(f"{meta}: artifact {png} for {project}: {exc}")
            continue
        if width < 1 or height < 1:
            problems.append(f"{png}: invalid dimensions {width}x{height}")
            continue
        recorded = (data.get("width"), data.get("height"))
        if recorded != (None, None) and recorded != (width, height):
            problems.append(f"{png}: metadata says {recorded[0]}x{recorded[1]}, PNG header says {width}x{height}")
            continue
        counts[project] = counts.get(project, 0) + 1
        ok.append(f"ok {project}: {png} png {width}x{height}")
    missing = [project for project in expected if project not in counts]
    if missing:
        problems.append(f"missing complete evidence for project(s): {', '.join(missing)}")
    unexpected = sorted(set(counts) - set(expected))
    if unexpected:
        notes.append(f"evidence for project(s) not in --expect: {', '.join(unexpected)}")
    return ok, notes, problems


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Validate screenshot evidence by exact project identity.")
    parser.add_argument("directory", type=Path, help="directory that holds the evidence")
    parser.add_argument("--pattern", default="**/evidence.json", help="metadata glob under DIR (default: %(default)s)")
    parser.add_argument("--expect", required=True, help="comma-separated project names that must have evidence")
    args = parser.parse_args(argv)
    expected = [name.strip() for name in args.expect.split(",") if name.strip()]
    if not expected:
        parser.error("--expect needs at least one project name")
    ok, notes, problems = check(args.directory, args.pattern, expected)
    for line in ok:
        print(line)
    for line in notes:
        print(f"note: {line}", file=sys.stderr)
    for line in problems:
        print(f"error: {line}", file=sys.stderr)
    return 1 if problems else 0


if __name__ == "__main__":
    raise SystemExit(main())
