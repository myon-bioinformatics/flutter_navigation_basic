#!/usr/bin/env python3
"""Compare sanitized JUnit failure identities from consecutive CI runs.

Read-only stdlib tool. The fingerprint is a test-identity fingerprint, not a
root-cause fingerprint: upstream compact JSONL omits messages and tracebacks.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re


def load(path: Path | None) -> list[dict]:
    if path is None:
        return []
    result = []
    for lineno, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not line.strip():
            continue
        item = json.loads(line)
        if not isinstance(item, dict) or item.get("category") != "test_failure":
            continue
        value, context = item.get("value"), item.get("context")
        if not isinstance(value, dict) or not isinstance(context, dict):
            raise ValueError(f"invalid failure record at line {lineno}")
        identity = {"repository": context.get("repository"),
                    "class": value.get("class"),
                    "test": value.get("test"), "kind": value.get("kind")}
        if not all(isinstance(v, str) and v for v in identity.values()):
            raise ValueError(f"incomplete failure identity at line {lineno}")
        token = json.dumps(identity, sort_keys=True, ensure_ascii=False,
                           separators=(",", ":")).encode("utf-8")
        result.append({"fingerprint": "junit-basic-v1:" + hashlib.sha256(token).hexdigest(),
                       "identity": identity})
    return result


def compare(current: list[dict], previous: list[dict], *,
            commit_sha: str, run_id: str, previous_commit_sha: str | None = None,
            previous_run_id: str | None = None) -> dict:
    if not re.fullmatch(r"[0-9a-fA-F]{40}", commit_sha):
        raise ValueError("commit SHA must contain 40 hex characters")
    if previous_commit_sha is not None and not re.fullmatch(r"[0-9a-fA-F]{40}", previous_commit_sha):
        raise ValueError("previous commit SHA must contain 40 hex characters")
    if not re.fullmatch(r"[0-9]+", run_id) or (previous_run_id is not None and
                                               not re.fullmatch(r"[0-9]+", previous_run_id)):
        raise ValueError("run IDs must be decimal")
    def counts(rows: list[dict]) -> dict:
        grouped = {}
        for row in rows:
            entry = grouped.setdefault(row["fingerprint"],
                                       {"identity": row["identity"], "count": 0})
            entry["count"] += 1
        return grouped
    now, old = counts(current), counts(previous)
    findings = []
    for fingerprint in sorted(now.keys() | old.keys()):
        a, b = now.get(fingerprint), old.get(fingerprint)
        status = "new" if b is None else "resolved" if a is None else "recurring"
        findings.append({"fingerprint": fingerprint, "identity": (a or b)["identity"],
                         "status": status, "current_count": a["count"] if a else 0,
                         "previous_count": b["count"] if b else 0})
    return {"schema": "junit-history/1", "commit_sha": commit_sha,
            "run_id": run_id, "previous_commit_sha": previous_commit_sha,
            "previous_run_id": previous_run_id,
            "fingerprint_scope": "repository+class+test+kind (not root cause)",
            "summary": {s: sum(f["status"] == s for f in findings)
                        for s in ("new", "recurring", "resolved")},
            "findings": findings}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--current", type=Path, required=True)
    parser.add_argument("--previous", type=Path)
    parser.add_argument("--commit-sha", required=True)
    parser.add_argument("--run-id", required=True)
    parser.add_argument("--previous-commit-sha")
    parser.add_argument("--previous-run-id")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args(argv)
    try:
        result = compare(load(args.current), load(args.previous),
                         commit_sha=args.commit_sha, run_id=args.run_id,
                         previous_commit_sha=args.previous_commit_sha,
                         previous_run_id=args.previous_run_id)
        args.output.write_text(json.dumps(result, ensure_ascii=False,
                                           indent=2, sort_keys=True) + "\n", encoding="utf-8")
    except (ValueError, OSError, json.JSONDecodeError) as error:
        parser.exit(2, f"invalid JUnit history input: {error}\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
