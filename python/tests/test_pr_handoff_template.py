"""Guard default PR template's #144 handoff as explicit opt-in."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TEMPLATE = ROOT / ".github" / "pull_request_template.md"


def _visible_markdown(text):
    # HTML comments must not contain nested comment delimiters.
    assert text.count("<!--") == text.count("-->")
    return re.sub(r"<!--.*?-->", "", text, flags=re.DOTALL)


def test_tracking_handoff_template_is_explicit_and_nonclosing():
    text = TEMPLATE.read_text(encoding="utf-8")
    assert "#144 HANDOFF: OPTIONAL / OPT-IN ONLY." in text
    assert "remove the enclosing HTML comment markers" in text
    assert "Related: #144" in text
    assert "https://github.com/myon-bioinformatics/flutter_navigation_basic/issues/144" in text
    assert "issuecomment-6108583942" in text
    assert "Before -> after" in text
    assert "Observable effect" in text
    assert "same-head CI" in text
    assert "Remaining work" in text
    assert "#144 ledger update link after merge:" in text
    assert 'Do not use "Closes #144"' in text


def test_default_pr_body_does_not_activate_tracking_handoff():
    text = TEMPLATE.read_text(encoding="utf-8")
    visible = _visible_markdown(text)
    for marker in ("Related: #144", "Policy:", "Baseline:", "## #144 tracking handoff"):
        assert marker not in visible
    assert "## Purpose and scope" in visible
    assert "## Verification" in visible


def test_priority_is_not_confused_with_completion():
    text = TEMPLATE.read_text(encoding="utf-8")
    assert "priority:high" in text
    assert "not proof" in text
    assert "Never auto-close #144" in text
