"""Regression guard for Playwright config/install browser parity.

PR #87 aligned the configured projects with CI/Docker. Keep that contract
explicit so a future project addition cannot silently return to the same drift.
"""

from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[3]
EXPECTED_ENGINES = {"chromium", "firefox", "webkit"}
EXPECTED_PROJECTS = EXPECTED_ENGINES | {"mobile-chromium", "mobile-webkit"}


def _configured_projects() -> set[str]:
    source = (ROOT / "e2e" / "playwright.config.ts").read_text(encoding="utf-8")
    return set(re.findall(r"name:\s*['\"]([^'\"]+)['\"]", source))


def test_playwright_projects_are_the_expected_browser_set() -> None:
    assert _configured_projects() == EXPECTED_PROJECTS


def test_ci_and_docker_install_every_configured_browser() -> None:
    workflow = (ROOT / ".github" / "workflows" / "non-dart.yml").read_text(encoding="utf-8")
    dockerfile = (ROOT / "Dockerfile.e2e").read_text(encoding="utf-8")

    install = "playwright install --with-deps chromium firefox webkit"
    assert workflow.count(install) == 2
    assert install in dockerfile
    # Mobile projects reuse Chromium/WebKit binaries with device descriptors.
    assert EXPECTED_ENGINES <= EXPECTED_PROJECTS

    list_command = (
        "playwright test --list "
        "--project=chromium --project=firefox --project=webkit "
        "--project=mobile-chromium --project=mobile-webkit"
    )
    assert list_command in workflow
