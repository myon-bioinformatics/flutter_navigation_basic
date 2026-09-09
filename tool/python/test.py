#!/usr/bin/env python3
"""Dev entrypoint for Python oracles + GitHub Actions latest status.

Examples:
  python3 tool/python/test.py
  python3 tool/python/test.py --actions-latest
  python3 tool/python/test.py --actions-latest --json
  python3 tool/python/test.py --actions-latest --download-artifact python-oracle-summary
  python3 tool/python/test.py --pytest -k zoom
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PYTHON_DIR = Path(__file__).resolve().parent


def _run_pytest(extra: list[str]) -> int:
    cmd = [
        sys.executable,
        "-m",
        "pytest",
        "-c",
        str(PYTHON_DIR / "pytest.ini"),
        *extra,
    ]
    # Run with tool/python as cwd so inifile rootdir/testpaths resolve cleanly.
    return subprocess.run(cmd, cwd=PYTHON_DIR).returncode


def _run_actions_latest(argv: list[str]) -> int:
    # Keep this as an importable module for pytest/conftest too.
    from actions_latest import main as actions_main

    return actions_main(argv)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Run allowlisted Python oracles and/or fetch the latest GitHub Actions "
            "status for this branch."
        )
    )
    parser.add_argument(
        "--actions-latest",
        action="store_true",
        help="Fetch and print the latest Actions run/jobs for the current branch",
    )
    parser.add_argument(
        "--pytest",
        action="store_true",
        help="Run pytest oracles (default when no mode flags are set)",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="With --actions-latest, emit JSON",
    )
    parser.add_argument("--branch", help="Branch override for --actions-latest")
    parser.add_argument(
        "--workflow",
        default="Flutter",
        help='Workflow name for --actions-latest (default: "Flutter")',
    )
    parser.add_argument(
        "--write",
        type=Path,
        help="Write Actions summary JSON to this path",
    )
    parser.add_argument(
        "--download-artifact",
        metavar="NAME",
        help="Download artifact from the selected Actions run",
    )
    parser.add_argument(
        "--artifact-dir",
        type=Path,
        default=None,
        help="Destination for --download-artifact",
    )
    parser.add_argument(
        "--allow-stale",
        action="store_true",
        help="With --actions-latest, allow a green run whose SHA differs from HEAD",
    )
    parser.add_argument(
        "pytest_args",
        nargs=argparse.REMAINDER,
        help="Args passed through to pytest after --",
    )
    args = parser.parse_args(argv)

    # Allow `test.py -- -k zoom` style remainder.
    pytest_extra = list(args.pytest_args)
    if pytest_extra and pytest_extra[0] == "--":
        pytest_extra = pytest_extra[1:]

    ran_something = False
    exit_code = 0

    if args.actions_latest:
        ran_something = True
        actions_argv: list[str] = []
        if args.branch:
            actions_argv.extend(["--branch", args.branch])
        if args.workflow is not None:
            actions_argv.extend(["--workflow", args.workflow])
        if args.json:
            actions_argv.append("--json")
        if args.write:
            actions_argv.extend(["--write", str(args.write)])
        if args.download_artifact:
            actions_argv.extend(["--download-artifact", args.download_artifact])
        if args.artifact_dir is not None:
            actions_argv.extend(["--artifact-dir", str(args.artifact_dir)])
        if args.allow_stale:
            actions_argv.append("--allow-stale")
        code = _run_actions_latest(actions_argv)
        exit_code = code if exit_code == 0 else exit_code

    # Default to pytest when neither flag is set, or when --pytest is explicit.
    if args.pytest or not args.actions_latest:
        ran_something = True
        # When both modes run, force local oracle mode unless caller overrode.
        if args.actions_latest and "--actions-latest" not in pytest_extra:
            pytest_extra = ["--oracle-mode=local", *pytest_extra]
        code = _run_pytest(pytest_extra)
        if code != 0:
            exit_code = code

    if not ran_something:
        parser.print_help()
        return 64

    # Convenience: also dump a tiny JSON receipt for agent logs.
    if args.actions_latest and args.write:
        try:
            summary = json.loads(args.write.read_text(encoding="utf-8"))
            print(
                f"actions_receipt: conclusion={summary.get('conclusion')} "
                f"run_id={summary.get('run_id')}",
                file=sys.stderr,
            )
        except OSError:
            pass

    return exit_code


if __name__ == "__main__":
    # Ensure tool/python is importable when invoked as a script path.
    sys.path.insert(0, str(PYTHON_DIR))
    raise SystemExit(main())
