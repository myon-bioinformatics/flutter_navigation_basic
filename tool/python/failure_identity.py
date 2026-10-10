"""Canonical, order-independent identity for real native/JUnit failure evidence.

Use the repository's existing vendored xprobe. Never copy traceback, stdout,
assertion text or parameter values into the compact corpus.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import sys
from typing import Any

# The canonical metadata producer has sibling imports, like its existing consumer.
_VENDOR = Path(__file__).resolve().parent / "vendor"
if str(_VENDOR) not in sys.path:
    sys.path.insert(0, str(_VENDOR))
from repository_metadata_generator import record_from_checkout
from vendor import xprobe


def collect_failure_identity(
    raw: str, *, root: Path, repository: str, report_id: str
) -> dict[str, Any]:
    record = record_from_checkout(root, repository)
    commit_sha = record["head"]["sha"]
    imported = xprobe.cases_from_junit(
        raw, repository=record["repository"]["full_name"],
        commit_sha=commit_sha, report_id=report_id,
    )
    for case in imported["cases"]:
        # xprobe has already removed parameter suffixes and raw failure payloads.
        identity = {"schema": "native-failure-fingerprint/1",
                    "repository": repository, "value": case["value"]}
        fingerprint = hashlib.sha256(json.dumps(
            identity, sort_keys=True, ensure_ascii=False, separators=(",", ":"),
        ).encode("utf-8")).hexdigest()
        case["fingerprint"] = fingerprint
        # ID is scoped to checkout/report; fingerprint survives reorder/new runs.
        case["id"] = f"{repository}@{commit_sha}/{report_id}-{fingerprint}"
    # Duplicate parameterized failures intentionally share their compact identity.
    imported["cases"] = xprobe.merge_cases([], imported["cases"])
    return imported
