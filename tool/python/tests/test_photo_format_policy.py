"""Keep the reviewer-facing Photo Studio format inventory from drifting.

This is deliberately a documentation contract test: browser support alone is not
Photo Studio support, so every app-recognized format and a small set of common
reviewer-visible formats must stay explicitly classified.
"""

from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[3]
SNIFFER = ROOT / "lib" / "features" / "photo_studio" / "data" / "image_format_sniff.dart"
DOC = ROOT / "docs" / "photo-import-compatibility.md"


def _recognized_image_kinds() -> set[str]:
    source = SNIFFER.read_text(encoding="utf-8")
    match = re.search(r"enum ImageFormatKind\s*\{(?P<body>.*?)\}", source, re.DOTALL)
    assert match is not None
    return {
        token.strip()
        for token in match.group("body").split(",")
        if token.strip() and token.strip() not in {"empty", "unknown"}
    }


def test_every_sniffer_format_is_explicitly_classified_for_reviewers() -> None:
    doc = DOC.read_text(encoding="utf-8").lower()
    for kind in _recognized_image_kinds():
        assert f"| {kind}" in doc, f"{kind} is recognized by the app but absent from format inventory"


def test_common_uncontracted_formats_remain_explicitly_visible() -> None:
    doc = DOC.read_text(encoding="utf-8").lower()
    for label in ("apng", "svg", "bmp", "tiff", "ico / cur", "jpeg xl", "camera raw / dng", "psd"):
        assert f"| {label}" in doc, f"{label} disappeared from reviewer-facing format inventory"


def test_inventory_distinguishes_supported_unverified_and_unsupported() -> None:
    doc = DOC.read_text(encoding="utf-8").lower()
    assert "**supported / portable web baseline**" in doc
    assert "**recognized, not verified as supported**" in doc
    assert "**not supported by the current photo studio contract**" in doc
    assert "**out of scope / unsupported**" in doc
