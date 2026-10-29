"""Contract tests: parent vendored gh_ops delegates to adjacent gh_identity."""

from __future__ import annotations

import sys
import io
import subprocess
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


def test_parent_gh_ops_open_prs_maps_search_items_to_pull_rows(gh_ops, monkeypatch):
    def search(query, **kwargs):
        return {
            "items": [{
                "repository": "octo/demo",
                "number": 42,
                "draft": True,
                "updated_at": "2026-10-17T00:00:00Z",
                "author": "alice",
                "title": "Add feature",
                "url": "https://github.com/octo/demo/pull/42",
            }],
            "total_count": 1,
            "complete": True,
            "truncated": False,
        }

    monkeypatch.setattr(gh_ops.gh_identity, "search", search)
    result = gh_ops.open_prs("octo", limit=10)
    assert result["ok"]
    assert result["pulls"] == [{
        "repo": "octo/demo",
        "number": 42,
        "draft": True,
        "updated_at": "2026-10-17T00:00:00Z",
        "author": "alice",
        "title": "Add feature",
        "url": "https://github.com/octo/demo/pull/42",
    }]


def test_parent_gh_ops_open_prs_search_item_author_none_becomes_empty(gh_ops, monkeypatch):
    def search(query, **kwargs):
        return {
            "items": [{
                "repository": "octo/demo",
                "number": 7,
                "draft": False,
                "updated_at": "2026-10-17T01:00:00Z",
                "author": None,
                "title": "No author",
                "url": "https://github.com/octo/demo/pull/7",
            }],
            "total_count": 1,
            "complete": True,
            "truncated": False,
        }

    monkeypatch.setattr(gh_ops.gh_identity, "search", search)
    row = gh_ops.open_prs("octo", limit=1)["pulls"][0]
    assert row["author"] == ""


def test_parent_gh_ops_open_prs_search_item_draft_none_becomes_false(gh_ops, monkeypatch):
    def search(query, **kwargs):
        return {
            "items": [{
                "repository": "octo/demo",
                "number": 8,
                "draft": None,
                "updated_at": "2026-10-17T02:00:00Z",
                "author": "bob",
                "title": "Draft unknown",
                "url": "https://github.com/octo/demo/pull/8",
            }],
            "total_count": 1,
            "complete": True,
            "truncated": False,
        }

    monkeypatch.setattr(gh_ops.gh_identity, "search", search)
    row = gh_ops.open_prs("octo", limit=1)["pulls"][0]
    assert row["draft"] is False


def test_parent_gh_ops_open_prs_maps_gh_identity_search_error(gh_ops, monkeypatch):
    def search(query, **kwargs):
        raise gh_ops.gh_identity.Error("forbidden")

    monkeypatch.setattr(gh_ops.gh_identity, "search", search)
    with pytest.raises(gh_ops.GhOpsError, match="forbidden"):
        gh_ops.open_prs("octo", limit=3)


def test_git_push_dry_run_uses_real_adjacent_ghi_without_network(gh_ops, monkeypatch, tmp_path):
    def git(*args):
        return subprocess.run(["git", "-C", str(tmp_path), *args], check=True,
                              capture_output=True, text=True).stdout.strip()

    git("init", "--initial-branch=main")
    git("-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid",
        "commit", "--allow-empty", "-m", "fixture")
    git("remote", "add", "origin", "https://example.invalid/never-push.git")
    head = git("rev-parse", "HEAD")
    actual_run = gh_ops.gh_identity._git_run
    seen = []

    def local_only(root, args, **kwargs):
        assert args[0] in {"branch", "check-ref-format", "rev-parse", "remote"}
        if args[0] == "remote":
            assert args == ["remote", "get-url", "--push", "--all", "origin"]
        assert kwargs["inherit_auth"] is False
        assert 0 < kwargs["timeout"] <= 5
        seen.append(args)
        return actual_run(root, args, **kwargs)

    monkeypatch.setattr(gh_ops.gh_identity, "_git_run", local_only)
    result = gh_ops.git_push(cwd=str(tmp_path), timeout=5, write=False)
    assert result["ok"] and result["dry_run"]
    assert result["head_sha"] == head
    assert result["mutation_status"] == result["verification_status"] == "not_attempted"
    assert result["pushed"] is False
    assert len(seen) == 4
    assert git("rev-parse", "HEAD") == head


@pytest.mark.parametrize("inherit_auth", [False, True])
def test_adjacent_ghi_bounded_runner_keywords_with_mocked_transport(
        gh_ops, monkeypatch, tmp_path, inherit_auth):
    ghi = gh_ops.gh_identity
    observed = []

    class Process:
        def __init__(self):
            self.stdout = io.BytesIO(b"")
            self.stderr = io.BytesIO(b"")

        def wait(self, timeout=None):
            assert timeout is not None and 0 < timeout <= 2
            return 0

    def spawn(command, **kwargs):
        assert kwargs["shell"] is False
        assert kwargs["env"]["GIT_TERMINAL_PROMPT"] == "0"
        observed.append(command)
        return Process()

    monkeypatch.setattr(ghi, "_git_spawn", spawn)
    assert ghi._git_run(tmp_path, ["status", "--porcelain"], timeout=2,
                        inherit_auth=inherit_auth) == (b"", False, 0)
    assert len(observed) == (3 if inherit_auth else 1)
    assert observed[-1][-2:] == ["status", "--porcelain"]


def test_adjacent_ghi_timeout_stops_mocked_process(gh_ops, monkeypatch, tmp_path):
    ghi = gh_ops.gh_identity
    stopped = []

    class Process:
        pid = 12345
        stdout = io.BytesIO(b"")
        stderr = io.BytesIO(b"")

        def wait(self, timeout=None):
            if timeout is not None:
                raise subprocess.TimeoutExpired("mocked git", timeout)
            return -9

        def kill(self):
            stopped.append("process")

    monkeypatch.setattr(ghi, "_git_spawn", lambda *args, **kwargs: Process())
    if ghi.os.name == "posix":
        monkeypatch.setattr(ghi.os, "killpg", lambda pid, sig: stopped.append(pid))
    with pytest.raises(ghi.GitInspectionError, match="timed out"):
        ghi._git_run(tmp_path, ["status"], timeout=0.1, inherit_auth=False)
    assert stopped == ([12345] if ghi.os.name == "posix" else ["process"])
