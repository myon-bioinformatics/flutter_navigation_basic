"""Enforce Docker and import boundaries for generated pattern catalogues.

The catalogue is intentionally not part of the Docker E2E image. Keep this
boundary test on changes that could add Dart imports or alter Docker context.
"""

from __future__ import annotations

import fnmatch
from pathlib import Path
import subprocess

import pytest


ROOT = Path(__file__).resolve().parents[3]
PATTERN_DIRECTORY = "*_patterns"
DOCKERIGNORE_RULES = (
    "lib/features/*_patterns/",
    "test/features/*_patterns/",
)
_DIRECTIVES = {"import", "export", "part"}


def _dart_tokens(source: str) -> list[tuple[str, str]]:
    """Tokenize enough Dart syntax to retain strings and ignore comments."""
    tokens: list[tuple[str, str]] = []
    index = 0
    while index < len(source):
        char = source[index]
        if char.isspace():
            index += 1
            continue
        if source.startswith("//", index):
            newline = source.find("\n", index + 2)
            index = len(source) if newline < 0 else newline + 1
            continue
        if source.startswith("/*", index):
            index += 2
            depth = 1
            while index < len(source) and depth:
                if source.startswith("/*", index):
                    depth += 1
                    index += 2
                elif source.startswith("*/", index):
                    depth -= 1
                    index += 2
                else:
                    index += 1
            continue
        if char in "'\"":
            quote = char
            delimiter = quote * 3 if source.startswith(quote * 3, index) else quote
            index += len(delimiter)
            start = index
            value: list[str] = []
            while index < len(source):
                if source[index] == "\\":
                    value.append(source[index:index + 2])
                    index += min(2, len(source) - index)
                    continue
                if source.startswith(delimiter, index):
                    value.append(source[start:index])
                    index += len(delimiter)
                    break
                index += 1
            else:
                value.append(source[start:index])
            tokens.append(("string", "".join(value)))
            continue
        if char.isalpha() or char in "_$":
            start = index
            index += 1
            while index < len(source) and (source[index].isalnum() or source[index] in "_$"):
                index += 1
            tokens.append(("identifier", source[start:index]))
            continue
        tokens.append(("symbol", char))
        index += 1
    return tokens


def _directive_uris(source: str) -> list[str]:
    """Return string URIs from import/export/part directives.

    All string literals before the directive's semicolon are retained, which
    includes conditional alternatives and string-form part-of directives.
    """
    tokens = _dart_tokens(source)
    uris: list[str] = []
    brace_depth = 0
    for index, (kind, value) in enumerate(tokens):
        if kind == "identifier" and value in _DIRECTIVES and brace_depth == 0:
            previous = tokens[index - 1] if index else None
            if previous is None or previous == ("symbol", ";") or previous == ("symbol", "}"):
                for body_kind, body_value in tokens[index + 1:]:
                    if body_kind == "symbol" and body_value == ";":
                        break
                    if body_kind == "string":
                        uris.append(body_value)
        if kind == "symbol" and value == "{":
            brace_depth += 1
        elif kind == "symbol" and value == "}":
            brace_depth = max(0, brace_depth - 1)
    return uris


def _tracked_dart_files() -> list[Path]:
    completed = subprocess.run(
        ["git", "ls-files", "-z", "--", "lib", "test"],
        cwd=ROOT,
        check=True,
        capture_output=True,
    )
    paths = [
        item.decode("utf-8")
        for item in completed.stdout.split(b"\0")
        if item and item.decode("utf-8").endswith(".dart")
    ]
    return [
        ROOT / path
        for path in paths
        if not any(fnmatch.fnmatchcase(part, PATTERN_DIRECTORY) for part in Path(path).parts)
    ]


def test_directive_parser_collects_multiline_and_conditional_uris() -> None:
    source = """import
      'package:app/main.dart'
      if (dart.library.io)
        "package:app_patterns/io.dart";
    export "package:app/export.dart";
    part 'src/part.dart';
    part of "package:app/library.dart";
    """
    assert _directive_uris(source) == [
        "package:app/main.dart",
        "package:app_patterns/io.dart",
        "package:app/export.dart",
        "src/part.dart",
        "package:app/library.dart",
    ]


def test_directive_parser_ignores_comment_and_string_examples() -> None:
    source = """// import 'package:fake_patterns/line.dart';
    /*
      export "package:fake_patterns/block.dart";
    */
    import 'package:real/main.dart';
    const example = "part 'package:fake_patterns/string.dart';";
    """
    assert _directive_uris(source) == ["package:real/main.dart"]


def test_directive_parser_finds_pattern_uri_only_in_conditional_branch() -> None:
    source = """import 'package:app/main.dart'
      if (dart.library.html) 'package:app/web.dart'
      if (dart.library.io) "package:app_patterns/native.dart";
    """
    assert _directive_uris(source) == [
        "package:app/main.dart",
        "package:app/web.dart",
        "package:app_patterns/native.dart",
    ]
    assert any("_patterns/" in uri for uri in _directive_uris(source))


def test_tracked_non_catalogue_dart_files_do_not_import_pattern_catalogues() -> None:
    violations: list[tuple[str, str]] = []
    for path in _tracked_dart_files():
        source = path.read_text(encoding="utf-8")
        for uri in _directive_uris(source):
            if "_patterns/" in uri.replace("\\", "/"):
                violations.append((path.relative_to(ROOT).as_posix(), uri))

    assert not violations, "Unexpected pattern catalogue imports:\n" + "\n".join(
        f"- {path}: {uri}" for path, uri in violations
    )


def test_dockerignore_excludes_only_the_two_pattern_catalogue_trees() -> None:
    lines = (ROOT / ".dockerignore").read_text(encoding="utf-8").splitlines()
    for rule in DOCKERIGNORE_RULES:
        assert lines.count(rule) == 1, f"expected exactly one .dockerignore rule: {rule}"


def test_non_dart_workflow_runs_the_boundary_test_for_relevant_changes() -> None:
    workflow = (ROOT / ".github" / "workflows" / "non-dart.yml").read_text(encoding="utf-8")
    for path_filter in (
        '      - ".dockerignore"',
        '      - "lib/**/*.dart"',
        '      - "test/**/*.dart"',
    ):
        assert workflow.count(path_filter) == 2, f"expected pull_request and push filters: {path_filter}"

    assert (
        '.dockerignore|lib/*.dart|test/*.dart|'
        'tool/python/tests/test_pattern_catalogue_boundary.py|'
        '.github/workflows/non-dart.yml'
    ) in workflow
    assert "pattern_boundary: ${{ steps.filter.outputs.pattern_boundary }}" in workflow
    assert "if: needs.changes.outputs.pattern_boundary == 'true'" in workflow
