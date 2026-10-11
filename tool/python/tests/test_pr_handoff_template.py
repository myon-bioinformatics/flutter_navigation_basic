"""Guard the #144 handoff template without making it mandatory for unrelated PRs."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
TEMPLATE = ROOT / ".github" / "pull_request_template.md"


def test_tracking_handoff_template_is_explicit_and_nonclosing():
    text = TEMPLATE.read_text(encoding="utf-8")
    assert "Related: #144" in text
    assert "https://github.com/myon-bioinformatics/flutter_navigation_basic/issues/144" in text
    assert "issuecomment-6108583942" in text
    assert "Before -> after" in text
    assert "Observable effect" in text
    assert "same-head CI" in text
    assert "Remaining work" in text
    assert "#144 ledger update link after merge:" in text
    assert 'For unrelated PRs, remove this section' in text
    assert 'Do not use "Closes #144"' in text


def test_priority_is_not_confused_with_completion():
    text = TEMPLATE.read_text(encoding="utf-8")
    assert "priority:high" in text
    assert "not proof" in text
    assert "Never auto-close #144" in text
