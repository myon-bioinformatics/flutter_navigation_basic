"""Keep all GitHub Actions artifact uploaders on the agreed v7 major."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[3]
UPLOAD = re.compile(r"(?m)^\s*-?\s*uses:\s*actions/upload-artifact@([^\s#]+)")


def test_all_workflow_upload_artifact_references_use_v7():
    workflows = sorted((ROOT / ".github" / "workflows").glob("*.y*ml"))
    assert workflows, "workflow directory is empty"
    references = [
        (path.relative_to(ROOT).as_posix(), match.group(1))
        for path in workflows
        for match in UPLOAD.finditer(path.read_text(encoding="utf-8"))
    ]
    assert references, "no artifact upload actions found"
    old = [(path, version) for path, version in references if version != "v7"]
    assert not old, f"Artifact upload action must be v7: {old}"
