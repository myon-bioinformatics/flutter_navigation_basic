"""The documented emoji-transition one-liner resolves pages from the generated registry."""
import os
import re
import shlex
import subprocess
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[3]
DOC = ROOT / "docs/testing/page-identities.md"
PAGES = "https://myon-bioinformatics.github.io/flutter_navigation_basic/"


def documented_code():
    block = DOC.read_text(encoding="utf-8").split("<!-- emoji-transition-one-liner -->", 1)[1]
    command = re.search(r"```sh\n(.+?)\n```", block, re.S).group(1)
    argv = shlex.split(command)  # POSIX shell quoting, as in the doc
    assert argv[:2] == ["python3", "-c"] and len(argv) == 4
    return argv[2], argv[3]


def run(notation, base=None):
    code, _ = documented_code()
    env = {k: v for k, v in os.environ.items() if k != "BASE"}
    if base:
        env["BASE"] = base
    return subprocess.run([sys.executable, "-c", code, notation], cwd=ROOT, env=env,
                          capture_output=True, text=True, encoding="utf-8")


def routes(result):
    assert result.returncode == 0, result.stderr
    return [line.split("#", 1)[1] for line in result.stdout.splitlines()]


def test_documented_example_is_the_round_trip():
    _, example = documented_code()
    out = run(example)
    assert out.stdout.splitlines() == [PAGES + "#/", PAGES + "#/hub", PAGES + "#/"]


@pytest.mark.parametrize("notation,expected", [
    ("🏠 → 🥐", ["/", "/examples/irony-generator"]),
    ("🏠→🗺→🌍↔🕶️", ["/", "/hub", "/screen1", "/screen198", "/screen1"]),  # no variation selector on 🗺
    ("🗺️ ↔︎ 📋", ["/hub", "/core/clipboard-shelf", "/hub"]),
    ("🔢", ["/screen5"]),
])
def test_notation_expands_to_registry_routes(notation, expected):
    assert routes(run(notation)) == expected


def test_every_registered_emoji_resolves_to_its_route():
    registry = (ROOT / "lib/shared/navigation/page_identities.g.dart").read_text(encoding="utf-8")
    pages = re.findall(r"'(/[^']*)': '([^/'][^']*)'", registry.split("pageRouteAliases")[0])
    assert len(pages) == 210
    notation = " → ".join(emoji for _, emoji in pages)
    assert routes(run(notation)) == [route for route, _ in pages]


def test_unknown_emoji_fails_without_partial_output():
    out = run("🏠 → 🦄")
    assert out.returncode != 0 and out.stdout == "" and "🦄" in out.stderr


def test_base_override_for_local_builds():
    assert run("🏠 → 📋", base="http://127.0.0.1:8080/").stdout.splitlines() == [
        "http://127.0.0.1:8080/#/", "http://127.0.0.1:8080/#/core/clipboard-shelf"]
