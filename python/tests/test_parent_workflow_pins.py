"""Local rollout contract; adopted vendor locks are deliberately independent."""
import re
from pathlib import Path

PARENT = "myon-bioinformatics/myon-bioinformatics"
PARENT_WORKFLOW_PIN = "9e3da7ae1846e9604ebc24bb5178f7de094a4e77"
ROOT = next(p for p in Path(__file__).resolve().parents if (p / ".github/workflows").is_dir())


def test_parent_workflow_references_use_reviewed_rollout_commit():
    pins = []
    for path in sorted((ROOT / ".github/workflows").glob("*")):
        if path.suffix not in (".yml", ".yaml"):
            continue
        text = path.read_text(encoding="utf-8")
        pins.extend(re.findall(r"uses:\s*" + re.escape(PARENT) + r"/[^\s@]+@([^\s]+)", text))
        lines = text.splitlines()
        for i, line in enumerate(lines):
            if not re.fullmatch(r"\s+repository:\s*" + re.escape(PARENT) + r"\s*", line):
                continue
            block = lines[i + 1:i + 12]
            if any(re.fullmatch(r"\s+path:\s*\.vendor-sync-tools\s*", item) for item in block):
                continue
            refs = [re.fullmatch(r"\s+ref:\s*(\S+)\s*", item) for item in block]
            pins.append(next((m.group(1) for m in refs if m), None))
    assert pins, "shared parent references must remain observable"
    assert set(pins) == {PARENT_WORKFLOW_PIN}, pins
