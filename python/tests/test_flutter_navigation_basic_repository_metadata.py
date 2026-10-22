"""Canonical checkout identity, portable tooling, Pages gating, and exact vendoring."""
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import sys

import pytest

PYTHON_DIR = Path(__file__).resolve().parents[1]
ROOT = PYTHON_DIR.parent
sys.path.insert(0, str(PYTHON_DIR / "vendor"))
import gh_identity as ghi


def record_from_checkout(root, repository, *, env):
    return ghi.repository_metadata_v1(root, repository=repository, env=env)


validate_repository_record = ghi.validate_repository_metadata_v1


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
    observed = ghi.tool_versions(("git",), include_python=True)
    assert record["tooling"]["python"] == observed["python"]
    assert record["tooling"]["git"] == observed["git"]


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
    monkeypatch.setattr("platform.python_version", lambda: python_version)
    observed_commands = []
    banners = {"git": "git version {}", "gh": "gh version {} (2024-01-01)",
               "node": "v{}", "npm": "{}", "npx": "{}"}

    def which(command):
        observed_commands.append(command)
        return "/fake/" + command if command in command_versions else None

    real_run = subprocess.run

    def run(argv, **kwargs):
        if not str(argv[0]).startswith("/fake/"):
            return real_run(argv, **kwargs)  # fixture Git calls stay real
        command = argv[0].rsplit("/", 1)[-1]
        return subprocess.CompletedProcess(argv, 0, banners[command].format(command_versions[command]) + "\n", "")

    monkeypatch.setattr(ghi.shutil, "which", which)
    monkeypatch.setattr(ghi.subprocess, "run", run)
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
        ("myon-bioinformatics/browser-test-kit", "scripts/image_diff.py", "python/vendor/image_diff.py"),
        ("myon-bioinformatics/Ironmate", "pillow_min.py", "python/vendor/pillow_min/pillow_min.py"),
        ("myon-bioinformatics/Ironmate", "LICENSE", "python/vendor/pillow_min/Ironmate-LICENSE"),
        ("myon-bioinformatics/yourself", "yourself.py", "python/vendor/yourself.py"),
        ("myon-bioinformatics/yourself", "LICENSE", "python/vendor/yourself-LICENSE"),
        ("myon-bioinformatics/xprobe", "xprobe.py", "python/vendor/xprobe.py"),
        ("myon-bioinformatics/xprobe", "LICENSE", "python/vendor/xprobe-LICENSE"),
        ("myon-bioinformatics/myon-bioinformatics", "gh_ops.py", "python/vendor/gh_ops.py"),
        ("myon-bioinformatics/myon-bioinformatics", "LICENSE", "python/vendor/myon-bioinformatics-LICENSE"),
        ("myon-bioinformatics/browser-test-kit", "scripts/check_evidence.py", "python/vendor/check_evidence.py"),
        ("myon-bioinformatics/browser-test-kit", "scripts/check_png.py", "python/vendor/check_png.py"),
        ("myon-bioinformatics/browser-test-kit", "scripts/jsonl_digest.py", "python/vendor/jsonl_digest.py"),
        ("myon-bioinformatics/browser-test-kit", "LICENSE", "python/vendor/browser-test-kit-LICENSE"),
        ("myon-bioinformatics/cli_args", "cli_args.py", "python/vendor/cli_args.py"),
        ("myon-bioinformatics/cli_args", "LICENSE", "python/vendor/cli_args-LICENSE"),
        ("myon-bioinformatics/gh_identity", "gh_identity.py", "python/vendor/gh_identity.py"),
        ("myon-bioinformatics/gh_identity", "LICENSE", "python/vendor/gh_identity-LICENSE"),
        ("myon-bioinformatics/browser-test-kit", "scripts/interaction.mjs", "e2e/utils/interaction.mjs"),
        ("myon-bioinformatics/browser-test-kit", "scripts/browser_execution.mjs", "e2e/utils/browser_execution.mjs"),
    }
    entries = lock["files"]
    assert {(entry["repository"], entry["source"], entry["destination"]) for entry in entries} == expected
    for entry in entries:
        assert entry["ref"] == entry["commit"]
        assert len(entry["ref"]) == 40 and set(entry["ref"]) <= set("0123456789abcdef")
    # The former Ironmate producer was replaced by gh_identity (#169) and removed.
    assert not any((vendor / name).exists() for name in (
        "repository_metadata_contract.py", "repository_metadata_generator.py", "Ironmate-LICENSE"))
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
    pin = "2192ff22acafdd09e80ac722df91ee937aaedd5e"
    assert workflow.count(f"ref: {pin}") == 1
    assert "vendor_sync.py update --manifest python/vendor.lock.json" not in workflow
    assert workflow.count("vendor_sync.py materialize --manifest python/vendor.lock.json") == 1
    assert not any(token in workflow for token in ("VENDOR_UPDATE_TOKEN", "VENDOR_UPDATES_ENABLED", "GH_TOKEN"))
    assert pin in (PYTHON_DIR / "README.md").read_text(encoding="utf-8")


def test_pages_generates_only_after_checkout_gate_and_embeds_asset():
    workflow = (ROOT / ".github/workflows/flutter-pages.yml").read_text()
    assert "github.event.workflow_run.head_branch == 'main'" in workflow
    assert workflow.index("Verify checkout matches gated SHA") < workflow.index("generate_repository_metadata.py --expected-sha")
    assert workflow.index("generate_repository_metadata.py --expected-sha") < workflow.index("meta --platform web --repository-metadata") < workflow.index("uses: ./.github/actions/build-companions")
    assert "assets/diagnostics/build_metadata.json" in (ROOT / "pubspec.yaml").read_text()


def test_dart_has_no_independent_git_identity_collector():
    source = (ROOT / "build_tools/build_metadata.dart").read_text()
    assert "_discoverRevision" not in source
    assert "_gitOutput(['status', '--porcelain'])" in source
    for git_identity_command in ["rev-parse", "--format=%cI", "--format=%s", "--show-current"]:
        assert git_identity_command not in source


def test_curl_runtime_uses_canonical_repository_metadata():
    workflow = (ROOT / ".github/workflows/curl-runtime.yml").read_text(encoding="utf-8")
    assert "python/generate_repository_metadata.py" in workflow
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


# Frozen compatibility with the former Ironmate producer (73157cb7). These
# values were produced by its write_metadata()/collect_portable_tooling() before
# it was removed; gh_identity must keep emitting the same bytes and labels.
IRONMATE_FIXTURE_SHA256 = {
    "repository-metadata.json": "e34d4a69e1dcdd14a0983d141f0111f42cf144974157baf2772f60cdc2016df6",
    "repository-metadata.jsonl": "f250d22adcdd7ceccfc43aec956fa370d71baf37e37d1a6c480c3c72208d7099",
}


def test_v1_writer_bytes_match_former_ironmate_output(tmp_path):
    record = json.loads((PYTHON_DIR / "fixtures/repository_metadata_v1.json").read_text(encoding="utf-8"))
    ghi.write_repository_metadata(record, tmp_path)
    for name, digest in IRONMATE_FIXTURE_SHA256.items():
        assert hashlib.sha256((tmp_path / name).read_bytes()).hexdigest() == digest


@pytest.mark.parametrize("version,label", [
    ("3.12.3", "3.12.3"), ("3.14.0rc1", "3.14.0rc1"), ("3.12.1.post1", "3.12.1.post1"),
    ("3.13.0.dev2", "3.13.0.dev2"), ("3.12.1+local.1", "3.12.1+local.1"), ("1!3.12.0", "1!3.12.0"),
    ("not-a-version", None),
])
def test_python_tooling_label_matches_former_ironmate(monkeypatch, version, label):
    monkeypatch.setattr("platform.python_version", lambda: version)
    assert ghi.tool_versions(include_python=True).get("python") == label
