#!/usr/bin/env python3
"""Run an allowlisted child command and retain its expected failure evidence."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import subprocess
import sys


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument(
        "--expect-exit",
        type=int,
        action="append",
        required=True,
        help="accepted child exit code; repeat for multiple expected codes",
    )
    parser.add_argument("command", nargs=argparse.REMAINDER)
    args = parser.parse_args(argv)
    command = list(args.command)
    if command and command[0] == "--":
        command = command[1:]
    if not command:
        parser.error("child command is required after --")

    out = args.output_dir.resolve()
    out.mkdir(parents=True, exist_ok=True)
    result = subprocess.run(command, capture_output=True, text=False, shell=False)
    (out / "stdout.bin").write_bytes(result.stdout)
    (out / "stderr.bin").write_bytes(result.stderr)
    receipt = {
        "schema": "expected-child-failure/1",
        "exit_code": result.returncode,
        "expected_exit_codes": sorted(set(args.expect_exit)),
        "matched_expectation": result.returncode in args.expect_exit,
        "command_executable": Path(command[0]).name,
        "argument_count": len(command) - 1,
    }
    (out / "receipt.json").write_text(
        json.dumps(receipt, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(receipt, ensure_ascii=False))
    return 0 if receipt["matched_expectation"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
