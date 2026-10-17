"""Contract tests: parent vendored gh_ops delegates to adjacent gh_identity."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
VENDOR = ROOT / "python/vendor"

REPO = "octo/demo"
HEAD = "ecfd0ba1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7"


@pytest.fixture(scope="module")
def gh_ops():
    sys.path.insert(0, str(VENDOR))
    import gh_ops as module

    return module


def test_vendored_gh_identity_satisfies_parent_gh_ops_surface(gh_ops):
    ghi = gh_ops.gh_identity
    expected = VENDOR / "gh_identity.py"

    assert Path(ghi.__file__).resolve() == expected.resolve()
    assert callable(ghi.request)
    assert callable(ghi.search)
    assert issubclass(ghi.Error, RuntimeError)


def test_parent_gh_ops_pr_status_calls_gh_identity_request(gh_ops, monkeypatch):
    seen: list[tuple[str, str]] = []

    def request(method, path, **kwargs):
        seen.append((method, path))
        return {
            "state": "open",
            "draft": False,
            "merged": False,
            "mergeable": True,
            "mergeable_state": "clean",
            "head": {"sha": HEAD, "ref": "feature"},
            "base": {"ref": "main"},
            "commits": 1,
            "changed_files": 1,
            "additions": 1,
            "deletions": 0,
            "html_url": "https://github.com/octo/demo/pull/11",
        }

    monkeypatch.setattr(gh_ops.gh_identity, "request", request)
    result = gh_ops.pr_status(REPO, 11)
    assert result["head_sha"] == HEAD
    assert seen == [("GET", "repos/octo/demo/pulls/11")]


def test_parent_gh_ops_pr_status_maps_gh_identity_error(gh_ops, monkeypatch):
    def request(method, path, **kwargs):
        raise gh_ops.gh_identity.Error("not-found")

    monkeypatch.setattr(gh_ops.gh_identity, "request", request)
    with pytest.raises(gh_ops.GhOpsError, match="not-found"):
        gh_ops.pr_status(REPO, 11)


def test_parent_gh_ops_open_prs_calls_gh_identity_search(gh_ops, monkeypatch):
    seen: list[tuple[str, dict]] = []

    def search(query, **kwargs):
        seen.append((query, kwargs))
        return {"items": [], "total_count": 7, "complete": False, "truncated": True}

    monkeypatch.setattr(gh_ops.gh_identity, "search", search)
    result = gh_ops.open_prs("octo", org=True, limit=5)
    assert result["total"] == 7
    assert result["truncated"]
    assert not result["complete"]
    assert seen == [("is:open archived:false org:octo", {"kind": "pr", "max_items": 5})]


def test_parent_gh_ops_open_prs_maps_gh_identity_search_error(gh_ops, monkeypatch):
    def search(query, **kwargs):
        raise gh_ops.gh_identity.Error("forbidden")

    monkeypatch.setattr(gh_ops.gh_identity, "search", search)
    with pytest.raises(gh_ops.GhOpsError, match="forbidden"):
        gh_ops.open_prs("octo", limit=3)
