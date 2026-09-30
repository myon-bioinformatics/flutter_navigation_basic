"""Canonical checkout identity, Pages gating, and exact vendoring provenance."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys

import pytest

PYTHON_DIR = Path(__file__).resolve().parents[1]
ROOT = PYTHON_DIR.parents[1]
sys.path.insert(0, str(PYTHON_DIR / "vendor"))
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


def test_vendor_provenance_matches_exact_bytes():
    vendor = PYTHON_DIR / "vendor"
    provenance = json.loads((vendor / "repository_metadata_provenance.json").read_text())
    assert provenance["source_commit"] == "0aee64da2f8d0119a3ef9b955e5c3818f28aaf92"
    assert provenance["repository"] == "myon-bioinformatics/Ironmate"
    expected = {
        "repository_metadata_contract.py": {
            "git_blob_sha": "a61a2949e58a42635b0830289e368b4125b1274b",
            "sha256": "c8093d806756925b68978b5a40a218e4acd5daf43f2d7fc2e358cabf8dc39e9a",
        },
        "repository_metadata_generator.py": {
            "git_blob_sha": "eef572ce64e92bfecf0451235f884aa208044587",
            "sha256": "a2edc91cc0a269d8b2fc6a9be1cfa0edbfae18604d53a1b9ebdcb72004be9a06",
        },
    }
    assert set(provenance["files"]) == set(expected)
    for name, hashes in expected.items():
        entry = provenance["files"][name]
        assert entry["git_blob_sha"] == hashes["git_blob_sha"]
        assert entry["sha256"] == hashes["sha256"]
        data = (vendor / name).read_bytes()
        assert hashlib.sha256(data).hexdigest() == hashes["sha256"]
        blob = f"blob {len(data)}\\0".encode() + data
        assert hashlib.sha1(blob).hexdigest() == hashes["git_blob_sha"]


def test_pages_generates_only_after_checkout_gate_and_embeds_asset():
    workflow = (ROOT / ".github/workflows/flutter-pages.yml").read_text()
    assert "github.event.workflow_run.head_branch == 'main'" in workflow
    assert workflow.index("Verify checkout matches gated SHA") < workflow.index("generate_repository_metadata.py --expected-sha")
    assert workflow.index("generate_repository_metadata.py --expected-sha") < workflow.index("meta --repository-metadata") < workflow.index("flutter build web")
    assert "assets/diagnostics/build_metadata.json" in (ROOT / "pubspec.yaml").read_text()


def test_dart_has_no_independent_git_identity_collector():
    source = (ROOT / "tool/build_metadata.dart").read_text()
    assert "_discoverRevision" not in source
    assert "_gitOutput(['status', '--porcelain'])" in source
    for git_identity_command in ["rev-parse", "--format=%cI", "--format=%s", "--show-current"]:
        assert git_identity_command not in source
