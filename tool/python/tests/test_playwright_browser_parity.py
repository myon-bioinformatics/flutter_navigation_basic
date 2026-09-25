"""Regression guard for Playwright config/install browser parity.

PR #87 aligned configured engines with CI/Docker. PR #89 adds mobile projects
that reuse installed Chromium/WebKit binaries and intentionally run only the
small @portable representative-flow subset.
"""

from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[3]
EXPECTED_ENGINES = {"chromium", "firefox", "webkit"}
EXPECTED_PROJECTS = EXPECTED_ENGINES | {"mobile-chromium", "mobile-webkit"}
MOBILE_PROJECTS = {"mobile-chromium", "mobile-webkit"}


def _configured_projects() -> set[str]:
    source = (ROOT / "e2e" / "playwright.config.ts").read_text(encoding="utf-8")
    return set(re.findall(r"name:\s*['\"]([^'\"]+)['\"]", source))


def _install_lines(text: str) -> list[str]:
    return [
        line.strip()
        for line in text.splitlines()
        if "playwright install --with-deps" in line
    ]


def test_playwright_projects_are_the_expected_browser_set() -> None:
    assert _configured_projects() == EXPECTED_PROJECTS


def test_ci_and_docker_install_only_browser_engines() -> None:
    workflow = (ROOT / ".github" / "workflows" / "non-dart.yml").read_text(encoding="utf-8")
    dockerfile = (ROOT / "Dockerfile.e2e").read_text(encoding="utf-8")

    expected_install = "playwright install --with-deps chromium firefox webkit"
    workflow_installs = _install_lines(workflow)
    docker_installs = _install_lines(dockerfile)

    assert workflow_installs == [
        f"npx {expected_install}",
        f"npx {expected_install}",
    ]
    assert docker_installs == [f"&& npx --prefix e2e {expected_install}"]

    # Project/profile names are not Playwright browser-install targets.
    for line in [*workflow_installs, *docker_installs]:
        assert not any(project in line for project in MOBILE_PROJECTS)


def test_mobile_projects_reuse_the_expected_installed_engines_and_portable_subset() -> None:
    source = (ROOT / "e2e" / "playwright.config.ts").read_text(encoding="utf-8")

    # Device descriptors carry the engine choice used by these projects:
    # Pixel -> Chromium-oriented, iPhone -> WebKit-oriented. These are emulation,
    # not physical-device/Safari compatibility claims.
    assert re.search(
        r"name:\s*['\"]mobile-chromium['\"].*?"
        r"grep:\s*/@portable/.*?"
        r"devices\[['\"]Pixel 7['\"]\]",
        source,
        re.DOTALL,
    )
    assert re.search(
        r"name:\s*['\"]mobile-webkit['\"].*?"
        r"grep:\s*/@portable/.*?"
        r"devices\[['\"]iPhone 13['\"]\]",
        source,
        re.DOTALL,
    )


def test_ci_lists_every_exact_project() -> None:
    workflow = (ROOT / ".github" / "workflows" / "non-dart.yml").read_text(encoding="utf-8")
    list_command = (
        "playwright test --list "
        "--project=chromium --project=firefox --project=webkit "
        "--project=mobile-chromium --project=mobile-webkit"
    )
    assert list_command in workflow


def test_manual_e2e_uses_python_cli_for_portable_five_project_allowlist() -> None:
    workflow = (ROOT / ".github" / "workflows" / "non-dart.yml").read_text(encoding="utf-8")
    command = next(
        line.strip()
        for line in workflow.splitlines()
        if "python3 ../tool/python/playwright.py test" in line
    )
    for project in EXPECTED_PROJECTS:
        assert f"--project {project}" in command
    assert "--grep @portable" in command
    assert "--max-failures=1" in command
    for spec in (
        "tests/hub_navigation.spec.ts",
        "tests/screen_navigation.spec.ts",
        "tests/photo_studio.spec.ts",
        "tests/photo_studio_ingress.spec.ts",
        "tests/photo_studio_format_matrix.spec.ts",
    ):
        assert spec in command


def test_docker_default_cmd_keeps_portable_five_project_allowlist() -> None:
    import json

    dockerfile = (ROOT / "Dockerfile.e2e").read_text(encoding="utf-8")
    cmd_line = next(line for line in dockerfile.splitlines() if line.startswith("CMD ["))
    argv = json.loads(cmd_line.removeprefix("CMD "))

    assert argv[0] == "test"
    projects = {
        argv[index + 1]
        for index, token in enumerate(argv[:-1])
        if token == "--project"
    }
    assert projects == EXPECTED_PROJECTS
    grep_index = argv.index("--grep")
    assert argv[grep_index + 1] == "@portable"
    assert argv[argv.index("--max-failures") + 1] == "1"
    for spec in (
        "tests/hub_navigation.spec.ts",
        "tests/screen_navigation.spec.ts",
        "tests/photo_studio.spec.ts",
        "tests/photo_studio_ingress.spec.ts",
        "tests/photo_studio_format_matrix.spec.ts",
    ):
        assert spec in argv
