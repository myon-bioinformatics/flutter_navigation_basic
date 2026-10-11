#!/usr/bin/env python3
"""Generate Flutter's repository record (schema v1) with the vendored gh_identity.

Only this adapter owns output placement and the optional Pages gated-SHA check.
Git identity, v1 validation and serialization live in vendor/gh_identity.py
(repository_metadata_v1); the bytes match the former Ironmate producer.
"""
from __future__ import annotations

import argparse
import os
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent / "vendor"))
import gh_identity as ghi

TOOL_COMMANDS = ("git", "gh", "node", "npm", "npx")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path("."))
    parser.add_argument("--repository", default=os.environ.get("GITHUB_REPOSITORY")
                        or "myon-bioinformatics/flutter_navigation_basic")
    parser.add_argument("--output-dir", type=Path, default=Path("build/diagnostics/repository"))
    parser.add_argument("--expected-sha", help="Pages gated checkout SHA; fail before writing on mismatch")
    args = parser.parse_args(argv)
    try:
        record = ghi.repository_metadata_v1(
            args.root.resolve(), repository=args.repository, expected_sha=args.expected_sha,
            tooling=ghi.tool_versions(TOOL_COMMANDS, include_python=True),
        )
    except ValueError as error:
        if "expected_sha" in str(error):
            parser.error("canonical metadata SHA does not match the gated checkout SHA")
        raise
    ghi.write_repository_metadata(record, args.output_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
