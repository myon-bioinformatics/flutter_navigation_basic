"""Keep pip requirement files aligned with python/pyproject.toml floors."""
from __future__ import annotations

import re
import tomllib
from pathlib import Path

PYTHON_DIR = Path(__file__).resolve().parents[1]
REQ_LINE = re.compile(r"^([A-Za-z0-9_.-]+)\s*>=\s*(.+)$")


def _parse_requirements(path: Path) -> dict[str, str]:
    specs: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        match = REQ_LINE.fullmatch(stripped)
        assert match, f"unexpected requirement line in {path}: {line!r}"
        name, floor = match.groups()
        specs[name.lower()] = floor.strip()
    return specs


def _pyproject_floors() -> tuple[dict[str, str], dict[str, str]]:
    data = tomllib.loads((PYTHON_DIR / "pyproject.toml").read_text(encoding="utf-8"))
    default = {}
    for item in data["project"]["dependencies"]:
        name, floor = item.split(">=", 1)
        default[name.lower()] = floor
    fixtures = {}
    for item in data["dependency-groups"]["fixtures"]:
        name, floor = item.split(">=", 1)
        fixtures[name.lower()] = floor
    return default, fixtures


def test_default_requirements_mirror_pyproject_dependencies() -> None:
    expected, _ = _pyproject_floors()
    assert _parse_requirements(PYTHON_DIR / "requirements.txt") == expected


def test_fixture_requirements_mirror_pyproject_group() -> None:
    _, expected = _pyproject_floors()
    assert _parse_requirements(PYTHON_DIR / "requirements-fixtures.txt") == expected
