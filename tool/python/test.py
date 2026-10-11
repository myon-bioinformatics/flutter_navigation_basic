#!/usr/bin/env python3
"""Dev entrypoint for Python oracles + GitHub Actions latest status.

Examples:
  python3 tool/python/test.py
  python3 tool/python/test.py --actions-latest
  python3 tool/python/test.py --actions-latest --json
  python3 tool/python/test.py --actions-latest --download-artifact python-oracle-summary
  python3 tool/python/test.py --pytest -k zoom
  python3 tool/python/test.py --flutter-outcomes build/diagnostics/flutter-test.json
  python3 tool/python/test.py --node --node-receipt build/test-results/node-summary.json
  python3 tool/python/test.py --python -x
  python3 tool/python/test.py --python --node -x
  python3 tool/python/test.py --print-message "CI check started"
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


def _run_node_tests(args) -> int:
    from node_test_runner import run_node

    files = args.node_test_file or [
        path.relative_to(ROOT).as_posix()
        for path in sorted((ROOT / "tool/javascript/tests").glob("*.test.mjs"))
    ]
    return run_node(
        root=ROOT, files=files,
        report=ROOT / args.node_report,
        receipt=ROOT / args.node_receipt if args.node_receipt else None,
        name_pattern=args.node_name_pattern,
        timeout=args.node_timeout,
    )


def _run_external_tests(args) -> int:
    from multi_test_runner import run_suite

    runner = args.external_runner
    if not args.test_file:
        print("external runner requires --test-file", file=sys.stderr)
        return 2
    try:
        return run_suite(
            runner, root=ROOT, files=args.test_file,
            report=ROOT / args.test_report,
            history=ROOT / args.test_history,
            retry_failed=args.retry_failed,
            timeout=args.test_timeout,
        )
    except (ValueError, OSError) as exc:
        print(f"external runner: {exc}", file=sys.stderr)
        return 2


def _run_actions_latest(argv: list[str]) -> int:
    # Keep this as an importable module for pytest/conftest too.
    from actions_latest import main as actions_main

    return actions_main(argv)


def _run_flutter_outcomes(path: Path, write: Path | None, as_json: bool) -> int:
    from outcomes import format_counts_line, load_flutter_json_file, summarize_counts, write_outcomes_json

    counts = load_flutter_json_file(path)
    payload = summarize_counts(counts, source="flutter-json")
    payload["input"] = str(path)
    if write is not None:
        write_outcomes_json(write, payload)
    if as_json:
        print(json.dumps(payload, indent=2))
    else:
        print(format_counts_line(counts))
        print(f"total={payload['total']} ok={payload['ok']}")
    return 0 if payload["ok"] else 1


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
        "--pytest", "--python", "--py",
        dest="pytest", action="store_true",
        help="Run Python pytest only (default when no test runner is selected)",
    )
    parser.add_argument("-x", "--exitfirst", action="store_true",
                        help="Pass -x to pytest: stop after the first failure (Node unaffected)")
    parser.add_argument("--print-message", action="append", default=[], metavar="TEXT",
                        help="Print literal agent/CI message (repeatable; alone runs no tests; never evaluate code)")
    parser.add_argument("--node", action="store_true",
                        help="Run Node's native tests with JUnit evidence")
    parser.add_argument("--node-test-file", action="append", default=None,
                        help="Explicit Node test file (repeatable); default: tool/javascript/tests/*.test.mjs")
    parser.add_argument("--node-name-pattern", help="Node test-name regex")
    parser.add_argument("--node-report", type=Path,
                        default=Path("build/test-results/node.xml"),
                        help="Native Node JUnit output path")
    parser.add_argument("--node-receipt", type=Path,
                        help="Optional JSON summary of Node JUnit")
    parser.add_argument("--node-timeout", type=int, default=300,
                        help="Node subprocess timeout in seconds")

    parser.add_argument("--external-runner",
                        choices=("deno", "playwright-node", "playwright-python"),
                        help="Run an allowlisted Deno/Playwright suite")
    parser.add_argument("--test-file", action="append", default=[],
                        help="Selected test file for external runner (repeatable)")
    parser.add_argument("--test-report", type=Path,
                        default=Path("build/test-results/external.xml"),
                        help="External runner JUnit output")
    parser.add_argument("--test-history", type=Path,
                        default=Path("build/test-results/test-attempts.json"),
                        help="JSON record of initial and retry attempts")
    parser.add_argument("--test-timeout", type=int, default=300,
                        help="Per-attempt subprocess timeout in seconds")
    parser.add_argument("--retry-failed", action="store_true",
                        help="Retry selected files once after failure; preserve original failure")

    parser.add_argument(
        "--flutter-outcomes",
        type=Path,
        metavar="JSON",
        help=(
            "Tally Flutter --file-reporter=json outcomes "
            "(passed/failed/skipped; known:/xfail: skips → xfailed)"
        ),
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="With --actions-latest or --flutter-outcomes, emit JSON",
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
        help="Write Actions / Flutter outcomes JSON to this path",
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

    # Runner selection is explicit: --node only, --python only, or both.
    # Keep the historical no-flag default as pytest for Python-only callers.
    explicit_runner = args.pytest or args.node or bool(args.external_runner)
    run_python = args.pytest or (not explicit_runner and not args.actions_latest
                                  and args.flutter_outcomes is None
                                  and not args.print_message)
    if args.exitfirst and not run_python:
        parser.error("-x/--exitfirst requires the Python pytest runner")
    if pytest_extra and not run_python:
        parser.error("pytest arguments require --python/--pytest")

    if args.retry_failed and not (args.node or args.external_runner):
        parser.error("--retry-failed requires --node or --external-runner")
    if args.test_timeout <= 0:
        parser.error("--test-timeout must be positive")
    if args.external_runner and args.node:
        parser.error("choose --node or --external-runner, not both")
    if args.external_runner and args.pytest:
        parser.error("run external and Python separately to retain distinct evidence")

    ran_something = False
    exit_code = 0
    for message in args.print_message:
        print(message)
        ran_something = True

    if args.flutter_outcomes is not None:
        ran_something = True
        code = _run_flutter_outcomes(args.flutter_outcomes, args.write, args.json)
        if code != 0:
            exit_code = code

    if args.actions_latest:
        ran_something = True
        actions_argv: list[str] = []
        if args.branch:
            actions_argv.extend(["--branch", args.branch])
        if args.workflow is not None:
            actions_argv.extend(["--workflow", args.workflow])
        if args.json:
            actions_argv.append("--json")
        if args.write and args.flutter_outcomes is None:
            actions_argv.extend(["--write", str(args.write)])
        if args.download_artifact:
            actions_argv.extend(["--download-artifact", args.download_artifact])
        if args.artifact_dir is not None:
            actions_argv.extend(["--artifact-dir", str(args.artifact_dir)])
        if args.allow_stale:
            actions_argv.append("--allow-stale")
        code = _run_actions_latest(actions_argv)
        exit_code = code if exit_code == 0 else exit_code

    if args.node:
        ran_something = True
        if args.node_timeout <= 0:
            parser.error("--node-timeout must be positive")
        if args.retry_failed:
            from multi_test_runner import run_node_retries
            files = args.node_test_file or [
                path.relative_to(ROOT).as_posix()
                for path in sorted((ROOT / "tool/javascript/tests").glob("*.test.mjs"))
            ]
            code = run_node_retries(
                root=ROOT, files=files, report=ROOT / args.node_report,
                history=ROOT / args.test_history, name_pattern=args.node_name_pattern,
                timeout=args.node_timeout, retry_failed=True)
        else:
            code = _run_node_tests(args)
        if code != 0:
            exit_code = code if exit_code == 0 else exit_code

    if args.external_runner:
        ran_something = True
        code = _run_external_tests(args)
        if code != 0 and exit_code == 0:
            exit_code = code

    if run_python:
        ran_something = True
        # When both modes run, force local oracle mode unless caller overrode.
        if args.actions_latest and "--oracle-mode" not in " ".join(pytest_extra):
            pytest_extra = ["--oracle-mode=local", *pytest_extra]
        code = _run_pytest((["-x"] if args.exitfirst else []) + pytest_extra)
        if code != 0 and exit_code == 0:
            exit_code = code

    if not ran_something:
        parser.print_help()
        return 64

    # Convenience: also dump a tiny JSON receipt for agent logs.
    if args.actions_latest and args.write and args.flutter_outcomes is None:
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
