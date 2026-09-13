"""Deterministic tests for build_artifact_report (tempfile trees)."""

from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest

_HERE = Path(__file__).resolve().parent
_PYTHON_DIR = _HERE.parent
if str(_PYTHON_DIR) not in sys.path:
    sys.path.insert(0, str(_PYTHON_DIR))

from build_artifact_report import (  # noqa: E402
    categorize,
    compare_reports,
    gzip_size,
    main,
    scan_root,
)


def _write(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)


def test_categorize_extensions() -> None:
    assert categorize(Path("main.dart.js")) == "js"
    assert categorize(Path("app.wasm")) == "wasm"
    assert categorize(Path("icons/logo.png")) == "assets"
    assert categorize(Path("mystery.bin")) == "other"


def test_scan_root_counts_and_gzip(tmp_path: Path) -> None:
    root = tmp_path / "web"
    js_bytes = b"console.log('hello');\n" * 20
    wasm_bytes = b"\x00asm" + b"\x01" * 40
    png_bytes = b"\x89PNG\r\n\x1a\n" + b"\x00" * 30
    other_bytes = b"binary-blob"
    _write(root / "main.dart.js", js_bytes)
    _write(root / "canvaskit" / "canvaskit.wasm", wasm_bytes)
    _write(root / "assets" / "logo.png", png_bytes)
    _write(root / "extra.bin", other_bytes)

    report = scan_root(root, largest_n=2)

    assert report["file_count"] == 4
    assert report["total_bytes"] == len(js_bytes) + len(wasm_bytes) + len(png_bytes) + len(
        other_bytes
    )
    assert report["by_category"]["js"]["count"] == 1
    assert report["by_category"]["js"]["bytes"] == len(js_bytes)
    assert report["by_category"]["wasm"]["count"] == 1
    assert report["by_category"]["assets"]["count"] == 1
    assert report["by_category"]["other"]["count"] == 1
    assert report["by_extension"][".js"]["count"] == 1
    assert report["by_extension"][".wasm"]["count"] == 1
    assert report["gzip_estimate_bytes"] == (
        gzip_size(js_bytes)
        + gzip_size(wasm_bytes)
        + gzip_size(png_bytes)
        + gzip_size(other_bytes)
    )
    assert len(report["largest_files"]) == 2
    assert report["largest_files"][0]["bytes"] >= report["largest_files"][1]["bytes"]


def test_compare_reports_delta(tmp_path: Path) -> None:
    before_root = tmp_path / "before"
    after_root = tmp_path / "after"
    _write(before_root / "a.js", b"aaaa")
    _write(after_root / "a.js", b"aaaaaa")
    _write(after_root / "b.png", b"pngdata")

    before = scan_root(before_root)
    after = scan_root(after_root)
    delta = compare_reports(before, after)

    assert delta["kind"] == "build_artifact_compare"
    assert delta["file_count"]["before"] == 1
    assert delta["file_count"]["after"] == 2
    assert delta["file_count"]["delta"] == 1
    assert delta["total_bytes"]["delta"] == (len(b"aaaaaa") + len(b"pngdata")) - len(b"aaaa")
    assert delta["by_category"]["js"]["bytes"] == len(b"aaaaaa") - len(b"aaaa")
    assert delta["by_category"]["assets"]["count"] == 1


def test_cli_root_and_compare(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    root = tmp_path / "web"
    _write(root / "main.js", b"var x = 1;\n")
    out_path = tmp_path / "report.json"
    assert main(["--root", str(root), "--output", str(out_path)]) == 0
    report = json.loads(out_path.read_text(encoding="utf-8"))
    assert report["file_count"] == 1

    before = tmp_path / "before.json"
    after = tmp_path / "after.json"
    before.write_text(json.dumps(report), encoding="utf-8")
    _write(root / "extra.wasm", b"\x00asmxx")
    assert main(["--root", str(root), "--output", str(after)]) == 0
    compare_out = tmp_path / "delta.json"
    assert main(["--compare", str(before), str(after), "--output", str(compare_out)]) == 0
    delta = json.loads(compare_out.read_text(encoding="utf-8"))
    assert delta["file_count"]["delta"] == 1
    captured = capsys.readouterr()
    assert '"kind": "build_artifact_compare"' in captured.out or '"kind": "build_artifact_report"' in captured.out
