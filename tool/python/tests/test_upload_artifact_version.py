"""Check artifact uploader version consistency without pinning a future-obsolete major.

Dependabot checks upstream GitHub Actions releases; this offline test verifies
that all workflow files use the same supported major in each proposed PR.
"""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[3]
UPLOAD = re.compile(r"(?m)^\s*-?\s*uses:\s*actions/upload-artifact@([^\s#]+)")
MAJOR = re.compile(r"v([1-9][0-9]*)\Z")


def collect_upload_versions():
    workflows = sorted((ROOT / ".github" / "workflows").glob("*.y*ml"))
    assert workflows, "workflow directory is empty"
    return [
        (path.relative_to(ROOT).as_posix(), match.group(1))
        for path in workflows
        for match in UPLOAD.finditer(path.read_text(encoding="utf-8"))
    ]


def test_all_workflow_upload_artifact_references_use_one_modern_major():
    references = collect_upload_versions()
    assert references, "no artifact upload actions found"
    invalid = [(path, version) for path, version in references
               if not MAJOR.fullmatch(version)]
    assert not invalid, f"Expected a major-version tag: {invalid}"
    versions = {version for _, version in references}
    assert len(versions) == 1, f"Artifact uploader majors differ: {references}"
    major = int(next(iter(versions))[1:])
    assert major >= 7, f"Legacy artifact uploader major v{major} is not allowed"


def test_dependabot_checks_github_actions_weekly():
    config = (ROOT / ".github" / "dependabot.yml").read_text(encoding="utf-8")
    assert 'package-ecosystem: "github-actions"' in config
    assert 'interval: "weekly"' in config
