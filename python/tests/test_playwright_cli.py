"""Regression test for python/playwright.py's argv construction.

Playwright's own CLI --project flag greedily consumes subsequent
space-separated tokens as additional project names. A real `docker run`
of Dockerfile.e2e's `snapshot --update` (flutter_navigation_basic#83)
failed with:

    Error: Project(s) "tests/visual_snapshot.spec.ts" not found.
    Available projects: "chromium", "firefox", "webkit"

because _playwright_test_args() built ["--project", "chromium",
"tests/visual_snapshot.spec.ts", ...] -- two space-separated tokens, so
Playwright read the spec path as a second (invalid) --project value
instead of a test file. This means every `snapshot` invocation (default
project="chromium") was broken on main, not just under Docker.

"--project=value" is a single argv token and cannot absorb what follows,
regardless of position -- that's the fix this locks in.
"""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_HERE = Path(__file__).resolve().parent
_PYTHON_DIR = _HERE.parent
if str(_PYTHON_DIR) not in sys.path:
    sys.path.insert(0, str(_PYTHON_DIR))

import playwright  # noqa: E402


@pytest.fixture(autouse=True)
def _stub_playwright_cli(monkeypatch: pytest.MonkeyPatch) -> None:
    # _playwright_test_args() calls the real _playwright_prefix(), which exits
    # if e2e/node_modules isn't installed. The argv shape it builds doesn't
    # depend on that prefix, so stub it out.
    monkeypatch.setattr(playwright, "_playwright_prefix", lambda: ["node", "cli.js"])


def test_project_flag_is_a_single_equals_joined_token() -> None:
    args = playwright._playwright_test_args(
        projects=["chromium"],
        headed=False,
        grep=None,
        extra=["tests/visual_snapshot.spec.ts"],
    )
    assert args == [
        "node",
        "cli.js",
        "test",
        "--project=chromium",
        "tests/visual_snapshot.spec.ts",
    ]
    assert "--project" not in args


def test_grep_flag_is_a_single_equals_joined_token() -> None:
    args = playwright._playwright_test_args(
        projects=None,
        headed=False,
        grep="home page",
        extra=["tests/hub_navigation.spec.ts"],
    )
    assert args == [
        "node",
        "cli.js",
        "test",
        "--grep=home page",
        "tests/hub_navigation.spec.ts",
    ]
    assert "--grep" not in args


def test_headed_flag_unaffected() -> None:
    args = playwright._playwright_test_args(
        projects=["chromium"],
        headed=True,
        grep=None,
        extra=[],
    )
    assert args == ["node", "cli.js", "test", "--project=chromium", "--headed"]


def test_snapshot_command_builds_the_exact_argv_that_failed_under_docker() -> None:
    parsed = playwright.build_parser().parse_args(["snapshot", "--update"])
    assert parsed.project == "chromium"

    cmd = playwright._playwright_test_args(
        projects=[parsed.project],
        headed=parsed.headed,
        grep=parsed.grep,
        extra=["tests/visual_snapshot.spec.ts", *parsed.extra],
    )
    if parsed.update:
        cmd.append("--update-snapshots")

    assert cmd == [
        "node",
        "cli.js",
        "test",
        "--project=chromium",
        "tests/visual_snapshot.spec.ts",
        "--update-snapshots",
    ]


def test_multiple_project_flags_are_repeatable_equals_joined_tokens() -> None:
    parsed = playwright.build_parser().parse_args([
        "test",
        "--project", "chromium",
        "--project", "firefox",
        "--project", "webkit",
        "tests/photo_studio.spec.ts",
    ])
    args = playwright._playwright_test_args(
        projects=parsed.projects,
        headed=parsed.headed,
        grep=parsed.grep,
        extra=parsed.extra,
    )
    assert args == [
        "node", "cli.js", "test",
        "--project=chromium",
        "--project=firefox",
        "--project=webkit",
        "tests/photo_studio.spec.ts",
    ]
    assert "--project" not in args


def test_existing_web_light_mode_preserves_base_path_without_starting_flutter(monkeypatch):
    from types import SimpleNamespace
    calls = []

    def run(argv, **kwargs):
        calls.append((argv, kwargs))
        return SimpleNamespace(returncode=7)

    monkeypatch.setattr(playwright.subprocess, 'run', run)
    result = playwright.main([
        'test', '--base-url', 'https://example.test/nested/app/',
        '--light', '--project', 'chromium', '--grep', 'Clipboard image bridge',
        'tests/photo_studio_ingress.spec.ts',
    ])
    assert result == 7
    assert len(calls) == 1
    argv, kwargs = calls[0]
    assert argv[:3] == ['node', 'cli.js', 'test']
    assert '--project=chromium' in argv
    assert kwargs['env']['FLUTTER_WEB_BASE_URL'] == 'https://example.test/nested/app/'
    assert kwargs['env']['FLUTTER_WEB_LIGHT'] == '1'
    assert kwargs['cwd'] == playwright.E2E_DIR


@pytest.mark.parametrize('url', [
    'file:///tmp/build', 'javascript:alert(1)', 'https://user:password@example.test/',
    'https://example.test/#/screen1', 'http://[broken',
])
def test_invalid_base_url_fails_before_launch(monkeypatch, url):
    def run(*args, **kwargs):
        pytest.fail('invalid base URL must not launch a subprocess')

    monkeypatch.setattr(playwright.subprocess, 'run', run)
    assert playwright.main(['test', '--base-url', url]) == 2
