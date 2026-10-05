#!/usr/bin/env python3
"""Run a child command expected to fail and retain bounded evidence."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import subprocess

DEFAULT_TIMEOUT = 30.0
MAX_STREAM_BYTES = 1024 * 1024


def _bounded(data: bytes) -> tuple[bytes, bool]:
    if len(data) <= MAX_STREAM_BYTES:
        return data, False
    return data[:MAX_STREAM_BYTES], True


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument(
        "--expect-exit",
        type=int,
        action="append",
        required=True,
        help="accepted nonzero child exit code; repeat for multiple expected codes",
    )
    parser.add_argument("--timeout", type=float, default=DEFAULT_TIMEOUT)
    parser.add_argument("command", nargs=argparse.REMAINDER)
    args = parser.parse_args(argv)
    if any(code == 0 for code in args.expect_exit):
        parser.error("--expect-exit must be nonzero; this wrapper is for intentional failures")
    if args.timeout <= 0:
        parser.error("--timeout must be greater than zero")
    command = list(args.command)
    if command and command[0] == "--":
        command = command[1:]
    if not command:
        parser.error("child command is required after --")

    out = args.output_dir.resolve()
    out.mkdir(parents=True, exist_ok=True)
    timed_out = False
    try:
        result = subprocess.run(
            command,
            capture_output=True,
            text=False,
            shell=False,
            timeout=args.timeout,
        )
        exit_code = result.returncode
        stdout, stdout_truncated = _bounded(result.stdout)
        stderr, stderr_truncated = _bounded(result.stderr)
    except subprocess.TimeoutExpired as error:
        timed_out = True
        exit_code = None
        stdout, stdout_truncated = _bounded(error.stdout or b"")
        stderr, stderr_truncated = _bounded(error.stderr or b"")

    (out / "stdout.bin").write_bytes(stdout)
    (out / "stderr.bin").write_bytes(stderr)
    matched = not timed_out and exit_code in args.expect_exit
    receipt = {
        "schema": "expected-child-failure/1",
        "exit_code": exit_code,
        "expected_exit_codes": sorted(set(args.expect_exit)),
        "matched_expectation": matched,
        "timed_out": timed_out,
        "timeout_seconds": args.timeout,
        "stdout_truncated": stdout_truncated,
        "stderr_truncated": stderr_truncated,
        "stream_limit_bytes": MAX_STREAM_BYTES,
        "command_executable": Path(command[0]).name,
        "argument_count": len(command) - 1,
    }
    (out / "receipt.json").write_text(
        json.dumps(receipt, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(receipt, ensure_ascii=False))
    return 0 if matched else 1


if __name__ == "__main__":
    raise SystemExit(main())
