"""Thin stdlib-only CLI wrapper around the repository Playwright setup."""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
E2E_DIR = ROOT / "e2e"


def _npx() -> str:
    return "npx.cmd" if os.name == "nt" else "npx"


def _run(args: list[str]) -> int:
    completed = subprocess.run(args, cwd=E2E_DIR, check=False)
    return completed.returncode


def _playwright_test_args(
    *,
    project: str | None,
    headed: bool,
    grep: str | None,
    extra: list[str],
) -> list[str]:
    args = [_npx(), "playwright", "test"]
    if project:
        args.extend(["--project", project])
    if headed:
        args.append("--headed")
    if grep:
        args.extend(["--grep", grep])
    args.extend(extra)
    return args


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Run flutter_navigation_basic Playwright commands from Python."
    )
    sub = parser.add_subparsers(dest="command", required=True)

    test = sub.add_parser("test", help="Run Playwright tests.")
    test.add_argument("--project")
    test.add_argument("--headed", action="store_true")
    test.add_argument("--grep")
    test.add_argument("extra", nargs=argparse.REMAINDER)

    list_cmd = sub.add_parser("list", help="List Playwright tests without running them.")
    list_cmd.add_argument("extra", nargs=argparse.REMAINDER)

    snapshot = sub.add_parser(
        "snapshot",
        help="Run visual snapshot tests (Chromium by default).",
    )
    snapshot.add_argument("--project", default="chromium")
    snapshot.add_argument("--headed", action="store_true")
    snapshot.add_argument("--grep")
    snapshot.add_argument(
        "--update",
        action="store_true",
        help="Update Playwright snapshot baselines.",
    )
    snapshot.add_argument("extra", nargs=argparse.REMAINDER)

    report = sub.add_parser("report", help="Open the Playwright HTML report.")
    report.add_argument("extra", nargs=argparse.REMAINDER)

    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)

    if not E2E_DIR.is_dir():
        print(f"error: missing e2e directory: {E2E_DIR}", file=sys.stderr)
        return 2

    if args.command == "test":
        return _run(
            _playwright_test_args(
                project=args.project,
                headed=args.headed,
                grep=args.grep,
                extra=args.extra,
            )
        )

    if args.command == "list":
        return _run([_npx(), "playwright", "test", "--list", *args.extra])

    if args.command == "snapshot":
        cmd = _playwright_test_args(
            project=args.project,
            headed=args.headed,
            grep=args.grep,
            extra=["tests/visual_snapshot.spec.ts", *args.extra],
        )
        if args.update:
            cmd.append("--update-snapshots")
        return _run(cmd)

    if args.command == "report":
        return _run([_npx(), "playwright", "show-report", *args.extra])

    raise AssertionError(f"unhandled command: {args.command}")


if __name__ == "__main__":
    raise SystemExit(main())
