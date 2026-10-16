"""Pages must build validation source links pinned to the gated commit.

The Dart side is verified by validation_pattern_links_test.dart against the
rendered URLs (with and without SOURCE_REF); this checks the deploy wiring.
"""
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]


def test_pages_build_passes_the_gated_commit_as_source_ref():
    workflow = yaml.safe_load((ROOT / ".github/workflows/flutter-pages.yml").read_text(encoding="utf-8"))
    steps = [step for job in workflow["jobs"].values() for step in job.get("steps", [])]
    build = [step for step in steps if step.get("name") == "Build Flutter web"]
    assert len(build) == 1
    assert build[0]["env"]["GATED_SHA"] == "${{ steps.gated.outputs.sha }}"
    assert '--dart-define=SOURCE_REF="$GATED_SHA"' in build[0]["run"].split()
