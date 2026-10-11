"""Deployed source links must be pinned to the deployed commit, not a branch."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]


def test_pages_build_pins_validation_source_links_to_the_gated_commit():
    widget = (ROOT / "lib/core/data_processing/validation_pattern_links.dart").read_text(encoding="utf-8")
    pages = (ROOT / ".github/workflows/flutter-pages.yml").read_text(encoding="utf-8")
    assert "String.fromEnvironment(\n      'SOURCE_REF'" in widget
    assert "/blob/$_ref/" in widget
    assert '--dart-define=SOURCE_REF="$GATED_SHA"' in pages
    assert "GATED_SHA: ${{ steps.gated.outputs.sha }}" in pages
