#!/usr/bin/env python3
"""Generate Flutter's canonical repository record using the pinned Ironmate producer.

Only this adapter owns output placement and the optional Pages gated-SHA check.
Git identity/normalization stays in vendor/repository_metadata_generator.py.
"""
from __future__ import annotations

import argparse
import os
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent / "vendor"))
from repository_metadata_generator import record_from_checkout, write_metadata


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path("."))
    parser.add_argument("--repository", default=os.environ.get("GITHUB_REPOSITORY")
                        or "myon-bioinformatics/flutter_navigation_basic")
    parser.add_argument("--output-dir", type=Path, default=Path("build/diagnostics/repository"))
    parser.add_argument("--expected-sha", help="Pages gated checkout SHA; fail before writing on mismatch")
    args = parser.parse_args(argv)
    record = record_from_checkout(args.root.resolve(), args.repository)
    if args.expected_sha is not None and record["head"]["sha"] != args.expected_sha:
        parser.error("canonical metadata SHA does not match the gated checkout SHA")
    write_metadata(record, args.output_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
