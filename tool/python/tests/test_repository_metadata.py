"""Canonical checkout identity, portable tooling, Pages gating, and exact vendoring."""
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import sys

import pytest

PYTHON_DIR = Path(__file__).resolve().parents[1]
ROOT = PYTHON_DIR.parents[1]
sys.path.insert(0, str(PYTHON_DIR / "vendor"))
import repository_metadata_generator as canonical_generator
from repository_metadata_generator import record_from_checkout
from repository_metadata_contract import validate_repository_record


def git(root, *args):
    return subprocess.check_output(["git", *args], cwd=root, text=True).strip()


@pytest.fixture
def checkout(tmp_path):
    git(tmp_path, "init", "-b", "main")
    git(tmp_path, "config", "user.name", "Metadata Test")
    git(tmp_path, "config", "user.email", "test@example.invalid")
    (tmp_path / "sample.txt").write_text("tracked\n")
    git(tmp_path, "add", ".")
    git(tmp_path, "commit", "-m", "metadata fixture 日本語")
    git(tmp_path, "checkout", "--detach")
    return tmp_path


@pytest.mark.parametrize("env,branch", [
    ({"GITHUB_REF_NAME": "main"}, "main"),
    ({"GITHUB_REF_NAME": "release/test"}, "release/test"),
    ({}, "detached"),
    ({"GITHUB_HEAD_REF": "feature/test", "GITHUB_REF_NAME": "123/merge"}, "feature/test"),
])
def test_detached_identity_uses_checkout_and_canonical_ref(checkout, env, branch):
    record = record_from_checkout(checkout, "example/repo", env={**env, "GITHUB_SHA": "f" * 40})
    validate_repository_record(record)
    assert record["head"]["sha"] == git(checkout, "rev-parse", "HEAD")
    assert record["head"]["branch"] == branch
    assert record["head"]["subject"] == "metadata fixture 日本語"


def test_cli_gated_sha_and_json_jsonl(checkout, tmp_path):
    output = tmp_path / "out"
    command = [sys.executable, str(PYTHON_DIR / "generate_repository_metadata.py"),
               "--root", str(checkout), "--repository", "example/repo",
               "--output-dir", str(output), "--expected-sha"]
    failure = subprocess.run([*command, "f" * 40], capture_output=True, text=True)
    assert failure.returncode != 0
    assert "gated checkout SHA" in failure.stderr
    assert not output.exists()
    subprocess.run([*command, git(checkout, "rev-parse", "HEAD")], check=True)
    record = json.loads((output / "repository-metadata.json").read_text())
    assert record == json.loads((output / "repository-metadata.jsonl").read_text())
    validate_repository_record(record)
    assert record["tooling"]["python"] == canonical_generator.normalize_version_output(
        "python", canonical_generator.platform.python_version(),
    )
    assert record["tooling"]["git"] == canonical_generator.normalize_version_output(
        "git", git(checkout, "--version"),
    )


@pytest.mark.parametrize(
    "python_version,command_versions,expected_tooling",
    [
        pytest.param(
            "3.11.9",
            {"git": "2.45.0", "gh": "2.61.0", "node": "22.1.0", "npm": "10.8.0", "npx": "10.8.0"},
            {"python": "3.11.9", "git": "2.45.0", "gh": "2.61.0", "node": "22.1.0", "npm": "10.8.0", "npx": "10.8.0"},
            id="all-present",
        ),
        pytest.param(
            "3.11.9", {"git": "2.45.0"},
            {"python": "3.11.9", "git": "2.45.0"}, id="partial",
        ),
        pytest.param("not-a-version", {}, {}, id="empty"),
    ],
)
def test_adapter_collects_canonical_tooling_without_nulls(
    checkout, tmp_path, monkeypatch, python_version, command_versions, expected_tooling,
):
    # Control observation inputs, not the adapter, collector or checkout identity.
    monkeypatch.setattr(canonical_generator.platform, "python_version", lambda: python_version)
    observed_commands = []

    def observe_command(command):
        observed_commands.append(command)
        return command_versions.get(command)

    monkeypatch.setattr(canonical_generator, "observe_command_version", observe_command)
    main = runpy.run_path(str(PYTHON_DIR / "generate_repository_metadata.py"))["main"]
    output = tmp_path / "out"
    sha = git(checkout, "rev-parse", "HEAD")
    assert main([
        "--root", str(checkout), "--repository", "example/repo",
        "--output-dir", str(output), "--expected-sha", sha,
    ]) == 0

    record = json.loads((output / "repository-metadata.json").read_text(encoding="utf-8"))
    assert record == json.loads((output / "repository-metadata.jsonl").read_text(encoding="utf-8"))
    validate_repository_record(record)
    assert observed_commands == ["git", "gh", "node", "npm", "npx"]
    assert record["tooling"] == expected_tooling
    assert record["head"]["sha"] == sha
    assert record["head"]["subject"] == "metadata fixture 日本語"


def test_vendor_lock_matches_exact_bytes_and_ci_contract():
    vendor = PYTHON_DIR / "vendor"
    lock = json.loads((PYTHON_DIR / "vendor.lock.json").read_text(encoding="utf-8"))
    assert lock["schema"] == "vendor-lock/1"
    expected = {
        ("myon-bioinformatics/Ironmate", "repository_metadata_contract.py", "tool/python/vendor/repository_metadata_contract.py"),
        ("myon-bioinformatics/Ironmate", "repository_metadata_generator.py", "tool/python/vendor/repository_metadata_generator.py"),
        ("myon-bioinformatics/Ironmate", "LICENSE", "tool/python/vendor/Ironmate-LICENSE"),
        ("myon-bioinformatics/yourself", "yourself.py", "tool/python/vendor/yourself.py"),
        ("myon-bioinformatics/yourself", "LICENSE", "tool/python/vendor/yourself-LICENSE"),
        ("myon-bioinformatics/xprobe", "xprobe.py", "tool/python/vendor/xprobe.py"),
        ("myon-bioinformatics/xprobe", "LICENSE", "tool/python/vendor/xprobe-LICENSE"),
        ("myon-bioinformatics/browser-test-kit", "scripts/gh_ops.py", "tool/python/vendor/gh_ops.py"),
        ("myon-bioinformatics/browser-test-kit", "scripts/check_evidence.py", "tool/python/vendor/check_evidence.py"),
        ("myon-bioinformatics/browser-test-kit", "scripts/check_png.py", "tool/python/vendor/check_png.py"),
        ("myon-bioinformatics/browser-test-kit", "scripts/jsonl_digest.py", "tool/python/vendor/jsonl_digest.py"),
        ("myon-bioinformatics/browser-test-kit", "LICENSE", "tool/python/vendor/browser-test-kit-LICENSE"),
        ("myon-bioinformatics/myon-bioinformatics", "git_inspector.py", "tool/python/vendor/git_inspector.py"),
        ("myon-bioinformatics/myon-bioinformatics", "LICENSE", "tool/python/vendor/myon-bioinformatics-LICENSE"),
        ("myon-bioinformatics/cli_args", "cli_args.py", "tool/python/vendor/cli_args.py"),
        ("myon-bioinformatics/cli_args", "LICENSE", "tool/python/vendor/cli_args-LICENSE"),
        ("myon-bioinformatics/gh_identity", "gh_identity.py", "tool/python/vendor/gh_identity.py"),
        ("myon-bioinformatics/gh_identity", "LICENSE", "tool/python/vendor/gh_identity-LICENSE"),
    }
    entries = lock["files"]
    assert {(entry["repository"], entry["source"], entry["destination"]) for entry in entries} == expected
    for entry in entries:
        if entry["repository"] == "myon-bioinformatics/Ironmate":
            # The metadata sources were retired from Ironmate main. Resolve the
            # already-adopted source/LICENSE snapshot instead of a deleted path.
            assert entry["ref"] == entry["commit"] == "73157cb7fed236a4a941722a6dcddd69a33ab95a"
        else:
            assert entry["ref"] == "refs/heads/main"
    assert len({entry["destination"] for entry in entries}) == len(entries)
    for entry in entries:
        commit = entry["commit"]
        assert len(commit) == 40 and set(commit) <= set("0123456789abcdef")
        data = (ROOT / entry["destination"]).read_bytes()
        assert hashlib.sha256(data).hexdigest() == entry["sha256"]
        blob = f"blob {len(data)}".encode() + bytes([0]) + data
        assert hashlib.sha1(blob).hexdigest() == entry["blob_sha"]
    assert not (vendor / "repository_metadata_provenance.json").exists()

    workflow = (ROOT / ".github/workflows/non-dart.yml").read_text(encoding="utf-8")
    assert workflow.count("ref: 380d877cd85837f36cf6030d626ee8bb7dfa28cb") == 2
    assert workflow.count("vendor_sync.py update --manifest tool/python/vendor.lock.json") == 1
    assert workflow.count("vendor_sync.py materialize --manifest tool/python/vendor.lock.json") == 1
    assert not any(token in workflow for token in ("VENDOR_UPDATE_TOKEN", "VENDOR_UPDATES_ENABLED", "GH_TOKEN"))
    assert "380d877cd85837f36cf6030d626ee8bb7dfa28cb" in (PYTHON_DIR / "README.md").read_text(encoding="utf-8")


def test_pages_generates_only_after_checkout_gate_and_embeds_asset():
    workflow = (ROOT / ".github/workflows/flutter-pages.yml").read_text()
    assert "github.event.workflow_run.head_branch == 'main'" in workflow
    assert workflow.index("Verify checkout matches gated SHA") < workflow.index("generate_repository_metadata.py --expected-sha")
    assert workflow.index("generate_repository_metadata.py --expected-sha") < workflow.index("meta --platform web --repository-metadata") < workflow.index("flutter build web")
    assert "assets/diagnostics/build_metadata.json" in (ROOT / "pubspec.yaml").read_text()


def test_dart_has_no_independent_git_identity_collector():
    source = (ROOT / "tool/build_metadata.dart").read_text()
    assert "_discoverRevision" not in source
    assert "_gitOutput(['status', '--porcelain'])" in source
    for git_identity_command in ["rev-parse", "--format=%cI", "--format=%s", "--show-current"]:
        assert git_identity_command not in source


def test_curl_runtime_uses_canonical_repository_metadata():
    workflow = (ROOT / ".github/workflows/curl-runtime.yml").read_text(encoding="utf-8")
    assert "tool/python/generate_repository_metadata.py" in workflow
    assert "--output-dir build/curl-runtime/repository" in workflow
    assert "gh_identity.local_identity" not in workflow
    assert "git rev-parse HEAD" not in workflow
    assert "local-identity.json" not in workflow


def test_http_editor_does_not_depend_directly_on_legacy_curl_parser():
    page = (ROOT / "lib/features/http_request_draft/presentation/http_request_draft_page.dart").read_text(encoding="utf-8")
    assert "curl_safe_subset.dart" not in page
    assert "CurlSafeSubset" not in page
    assert "RequestDraftCodec.toCurl(" in page
    assert not (ROOT / "lib/shared/http/curl_export.dart").exists()
