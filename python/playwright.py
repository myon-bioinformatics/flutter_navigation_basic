"""Thin stdlib-only CLI wrapper around the repository Playwright setup."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path
from urllib.parse import urlsplit


ROOT = Path(__file__).resolve().parents[1]
E2E_DIR = ROOT / "e2e"
PLAYWRIGHT_CLI = E2E_DIR / "node_modules" / "@playwright" / "test" / "cli.js"


def _node() -> str:
    return "node.exe" if os.name == "nt" else "node"


def _playwright_prefix() -> list[str]:
    if not PLAYWRIGHT_CLI.is_file():
        print(
            "error: Playwright is not installed. Run 'cd e2e && npm install' first.",
            file=sys.stderr,
        )
        raise SystemExit(2)
    return [_node(), str(PLAYWRIGHT_CLI)]


def _run(args: list[str], *, base_url: str | None = None, light: bool = False, routes: dict | None = None) -> int:
    env = os.environ.copy()
    if base_url is not None:
        env["FLUTTER_WEB_BASE_URL"] = base_url.rstrip("/") + "/"
    if light:
        env["FLUTTER_WEB_LIGHT"] = "1"
    if routes is not None:
        env["FLUTTER_WEB_ROUTES"] = json.dumps(routes)
    completed = subprocess.run(args, cwd=E2E_DIR, env=env, check=False)
    return completed.returncode


def _playwright_test_args(
    *,
    projects: list[str] | None,
    headed: bool,
    grep: str | None,
    extra: list[str],
) -> list[str]:
    args = [*_playwright_prefix(), "test"]
    for project in projects or []:
        # Keep every project as one --project=value token. Playwright's
        # space-separated form can greedily consume a following spec path.
        args.append(f"--project={project}")
    if headed:
        args.append("--headed")
    if grep:
        args.append(f"--grep={grep}")
    args.extend(extra)
    return args


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Run flutter_navigation_basic Playwright commands from Python."
    )
    sub = parser.add_subparsers(dest="command", required=True)

    test = sub.add_parser("test", help="Run Playwright tests.")
    test.add_argument("--project", action="append", dest="projects")
    test.add_argument("--headed", action="store_true")
    test.add_argument("--grep")
    test.add_argument("--base-url", help="Existing HTTP(S) web build; no Flutter build is started")
    test.add_argument("--light", action="store_true", help="Disable video and trace recording")
    test.add_argument("extra", nargs=argparse.REMAINDER)

    pages = sub.add_parser("pages", help="Capture every public route in an existing Web build.")
    pages.add_argument("--base-url", required=True)
    pages.add_argument("--project", action="append", dest="projects", default=None)
    pages.add_argument("--route", action="append", help="Select registered routes; default: all")
    pages.add_argument("--light", action="store_true")
    pages.add_argument("extra", nargs=argparse.REMAINDER)

    check = sub.add_parser("check-observation", help="Check saved evidence without Node/browser/SDK.")
    check.add_argument("extra", nargs=argparse.REMAINDER)

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

    evidence = sub.add_parser(
        "photo-evidence",
        help="Run the bounded Photo Studio MJS evidence runner.",
    )
    evidence.add_argument("--browser", default="chromium", choices=("chromium", "firefox", "webkit"))
    evidence.add_argument("--base-url", default="http://localhost:8080")
    evidence.add_argument("--fixture", required=True)
    evidence.add_argument("--output", default="test-results/photo-studio-evidence.png")
    evidence.add_argument("--timeout-ms", type=int, default=30000)

    interaction = sub.add_parser(
        "interaction",
        help="Drive Flutter E2E-only drag/animation/selection routes via Playwright.",
    )
    interaction.add_argument("--project", default="chromium")
    interaction.add_argument(
        "--kind",
        choices=("portable", "gesture", "all"),
        default="portable",
        help="Use portable click tests, native pointer gestures, or both.",
    )
    interaction.add_argument("--headed", action="store_true")

    report = sub.add_parser("report", help="Open the Playwright HTML report.")
    report.add_argument("extra", nargs=argparse.REMAINDER)

    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    if hasattr(args, "extra") and args.extra[:1] == ["--"]:
        args.extra = args.extra[1:]

    if args.command == "check-observation":
        from check_web_observations import main as check_main
        return check_main(args.extra)

    if not E2E_DIR.is_dir():
        print(f"error: missing e2e directory: {E2E_DIR}", file=sys.stderr)
        return 2

    if args.command in ("test", "pages"):
        if args.base_url is not None:
            try:
                url = urlsplit(args.base_url)
                valid = (url.scheme in ("http", "https") and bool(url.hostname)
                         and url.username is None and url.password is None
                         and not url.query and not url.fragment)
            except ValueError:
                valid = False
            if not valid:
                print("error: base URL must be HTTP(S), without credentials, query or fragment", file=sys.stderr)
                return 2
        routes = None
        if args.command == "pages":
            from web_page_catalogue import catalogue
            routes = catalogue()
            routes["projects"] = args.projects or ["chromium"]
            routes["selection"] = "subset" if args.route else "all-public-routes"
            if args.route:
                unknown = set(args.route) - set(routes["routes"])
                if unknown:
                    print("error: unregistered routes: " + ", ".join(sorted(unknown)), file=sys.stderr)
                    return 2
                routes["routes"] = sorted(set(args.route))
            print(f"Web observation: {len(routes['routes'])} routes; existing build, no SDK build", flush=True)
        return _run(
            _playwright_test_args(
                projects=(args.projects or ["chromium"]) if routes else args.projects,
                headed=False if routes else args.headed,
                grep=None if routes else args.grep,
                extra=["tests/page_observations.spec.ts", *args.extra] if routes else args.extra,
            ),
            base_url=args.base_url,
            light=args.light,
            routes=routes,
        )

    if args.command == "list":
        return _run([*_playwright_prefix(), "test", "--list", *args.extra])

    if args.command == "snapshot":
        cmd = _playwright_test_args(
            projects=[args.project],
            headed=args.headed,
            grep=args.grep,
            extra=["tests/visual_snapshot.spec.ts", *args.extra],
        )
        if args.update:
            cmd.append("--update-snapshots")
        return _run(cmd)

    if args.command == "photo-evidence":
        script = E2E_DIR / "scripts" / "photo_studio_evidence.mjs"
        return _run([
            _node(),
            str(script),
            f"--browser={args.browser}",
            f"--baseURL={args.base_url}",
            f"--fixture={Path(args.fixture).resolve()}",
            f"--output={args.output}",
            f"--timeout={args.timeout_ms}",
        ])

    if args.command == "interaction":
        grep = None if args.kind == "all" else f"@{args.kind}"
        return _run(
            _playwright_test_args(
                projects=[args.project],
                headed=args.headed,
                grep=grep,
                extra=["tests/pattern_interactions.spec.ts"],
            )
        )

    if args.command == "report":
        return _run([*_playwright_prefix(), "show-report", *args.extra])

    raise AssertionError(f"unhandled command: {args.command}")


if __name__ == "__main__":
    raise SystemExit(main())
