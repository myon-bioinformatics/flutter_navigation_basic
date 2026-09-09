"""Fetch and summarize the latest GitHub Actions results (stdlib only)."""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import urllib.error
import urllib.request
import zipfile
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any


@dataclass
class CheckRow:
    name: str
    status: str
    conclusion: str | None
    url: str | None = None


@dataclass
class ActionsSummary:
    branch: str
    workflow: str | None
    run_id: int | None
    head_sha: str | None
    conclusion: str | None
    url: str | None
    checks: list[CheckRow]
    source: str


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


def _detect_repo_slug() -> str:
    env = os.environ.get("GITHUB_REPOSITORY")
    if env:
        return env
    result = subprocess.run(
        ["git", "remote", "get-url", "origin"],
        cwd=_repo_root(),
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise RuntimeError("Could not detect repository slug from origin remote.")
    url = result.stdout.strip()
    # Strip credentials from https://x-access-token:...@github.com/owner/repo
    if "@github.com/" in url:
        url = "https://github.com/" + url.split("@github.com/", 1)[1]
    if url.endswith(".git"):
        url = url[:-4]
    if "github.com/" in url:
        return url.split("github.com/", 1)[1]
    if "github.com:" in url:
        return url.split("github.com:", 1)[1]
    raise RuntimeError(f"Unrecognized origin URL: {url}")


def _current_branch() -> str:
    env = os.environ.get("GITHUB_REF_NAME")
    if env:
        return env
    result = subprocess.run(
        ["git", "branch", "--show-current"],
        cwd=_repo_root(),
        check=True,
        capture_output=True,
        text=True,
    )
    branch = result.stdout.strip()
    if not branch:
        raise RuntimeError("Detached HEAD; pass --branch explicitly.")
    return branch


def _gh_available() -> bool:
    return shutil.which("gh") is not None


def _run_gh(args: list[str]) -> str:
    result = subprocess.run(
        ["gh", *args],
        cwd=_repo_root(),
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or result.stdout.strip() or "gh failed")
    return result.stdout


def fetch_summary_via_gh(
    *,
    branch: str | None = None,
    workflow: str | None = "Flutter",
    limit: int = 1,
) -> ActionsSummary:
    branch = branch or _current_branch()
    args = [
        "run",
        "list",
        "--branch",
        branch,
        "--limit",
        str(limit),
        "--json",
        "databaseId,name,conclusion,headSha,url,status,workflowName,displayTitle",
    ]
    if workflow:
        args.extend(["--workflow", workflow])
    runs = json.loads(_run_gh(args))
    if not runs:
        return ActionsSummary(
            branch=branch,
            workflow=workflow,
            run_id=None,
            head_sha=None,
            conclusion=None,
            url=None,
            checks=[],
            source="gh",
        )
    run = runs[0]
    run_id = int(run["databaseId"])
    jobs_json = _run_gh(
        [
            "run",
            "view",
            str(run_id),
            "--json",
            "jobs,conclusion,url,headSha,name",
        ]
    )
    payload = json.loads(jobs_json)
    checks = [
        CheckRow(
            name=job.get("name") or "unknown",
            status=job.get("status") or "unknown",
            conclusion=job.get("conclusion"),
            url=job.get("url"),
        )
        for job in payload.get("jobs") or []
    ]
    return ActionsSummary(
        branch=branch,
        workflow=payload.get("name") or workflow,
        run_id=run_id,
        head_sha=payload.get("headSha") or run.get("headSha"),
        conclusion=payload.get("conclusion") or run.get("conclusion"),
        url=payload.get("url") or run.get("url"),
        checks=checks,
        source="gh",
    )


def fetch_summary_via_api(
    *,
    branch: str | None = None,
    workflow: str | None = "Flutter",
    token: str | None = None,
) -> ActionsSummary:
    """Fallback when gh is unavailable. Uses GITHUB_TOKEN / GH_TOKEN."""
    branch = branch or _current_branch()
    token = token or os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")
    if not token:
        raise RuntimeError(
            "Neither gh CLI nor GITHUB_TOKEN/GH_TOKEN is available for Actions lookup."
        )
    repo = _detect_repo_slug()
    query = f"branch={branch}&per_page=5"
    if workflow:
        # Resolve workflow file id/name via runs filter
        query += f"&event=push"
    url = f"https://api.github.com/repos/{repo}/actions/runs?{query}"
    req = urllib.request.Request(
        url,
        headers={
            "Accept": "application/vnd.github+json",
            "Authorization": f"Bearer {token}",
            "X-GitHub-Api-Version": "2022-11-28",
            "User-Agent": "flutter-navigation-basic-actions-latest",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            payload = json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as error:
        raise RuntimeError(f"GitHub API error: {error.code} {error.reason}") from error

    runs = payload.get("workflow_runs") or []
    if workflow:
        runs = [run for run in runs if run.get("name") == workflow]
    if not runs:
        return ActionsSummary(
            branch=branch,
            workflow=workflow,
            run_id=None,
            head_sha=None,
            conclusion=None,
            url=None,
            checks=[],
            source="api",
        )
    run = runs[0]
    run_id = int(run["id"])
    jobs_url = f"https://api.github.com/repos/{repo}/actions/runs/{run_id}/jobs"
    jobs_req = urllib.request.Request(
        jobs_url,
        headers={
            "Accept": "application/vnd.github+json",
            "Authorization": f"Bearer {token}",
            "X-GitHub-Api-Version": "2022-11-28",
            "User-Agent": "flutter-navigation-basic-actions-latest",
        },
    )
    with urllib.request.urlopen(jobs_req, timeout=30) as response:
        jobs_payload = json.loads(response.read().decode("utf-8"))
    checks = [
        CheckRow(
            name=job.get("name") or "unknown",
            status=job.get("status") or "unknown",
            conclusion=job.get("conclusion"),
            url=job.get("html_url"),
        )
        for job in jobs_payload.get("jobs") or []
    ]
    return ActionsSummary(
        branch=branch,
        workflow=run.get("name") or workflow,
        run_id=run_id,
        head_sha=run.get("head_sha"),
        conclusion=run.get("conclusion"),
        url=run.get("html_url"),
        checks=checks,
        source="api",
    )


def fetch_latest_summary(
    *,
    branch: str | None = None,
    workflow: str | None = "Flutter",
) -> ActionsSummary:
    if _gh_available():
        return fetch_summary_via_gh(branch=branch, workflow=workflow)
    return fetch_summary_via_api(branch=branch, workflow=workflow)


def download_artifact(
    *,
    name: str,
    run_id: int | None = None,
    branch: str | None = None,
    workflow: str | None = "Flutter",
    dest: Path | None = None,
) -> Path:
    """Download a named artifact from the latest (or given) workflow run via gh."""
    if not _gh_available():
        raise RuntimeError("Artifact download requires the gh CLI.")
    if run_id is None:
        summary = fetch_summary_via_gh(branch=branch, workflow=workflow)
        if summary.run_id is None:
            raise RuntimeError("No workflow run found to download artifacts from.")
        run_id = summary.run_id
    dest = dest or (_repo_root() / "build" / "diagnostics" / "actions-artifacts")
    dest.mkdir(parents=True, exist_ok=True)
    _run_gh(
        [
            "run",
            "download",
            str(run_id),
            "--name",
            name,
            "--dir",
            str(dest),
        ]
    )
    return dest


def write_local_summary(path: Path, summary: ActionsSummary) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(
            {
                "branch": summary.branch,
                "workflow": summary.workflow,
                "run_id": summary.run_id,
                "head_sha": summary.head_sha,
                "conclusion": summary.conclusion,
                "url": summary.url,
                "source": summary.source,
                "checks": [asdict(row) for row in summary.checks],
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )


def summary_to_dict(summary: ActionsSummary) -> dict[str, Any]:
    return {
        "branch": summary.branch,
        "workflow": summary.workflow,
        "run_id": summary.run_id,
        "head_sha": summary.head_sha,
        "conclusion": summary.conclusion,
        "url": summary.url,
        "source": summary.source,
        "checks": [asdict(row) for row in summary.checks],
        "failed": [
            asdict(row)
            for row in summary.checks
            if row.conclusion not in (None, "success", "skipped")
        ],
        "pending": [
            asdict(row)
            for row in summary.checks
            if row.status not in ("completed",) or row.conclusion is None
        ],
    }


def unpack_zip(archive: Path, dest: Path) -> Path:
    dest.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(archive) as zf:
        zf.extractall(dest)
    return dest


def print_human(summary: ActionsSummary) -> None:
    data = summary_to_dict(summary)
    print(f"branch: {data['branch']}")
    print(f"workflow: {data['workflow']}")
    print(f"run_id: {data['run_id']}")
    print(f"head_sha: {data['head_sha']}")
    print(f"conclusion: {data['conclusion']}")
    print(f"url: {data['url']}")
    print(f"source: {data['source']}")
    print("checks:")
    for row in summary.checks:
        mark = row.conclusion or row.status
        print(f"  - [{mark}] {row.name}")
    if data["failed"]:
        print("failed:")
        for row in data["failed"]:
            print(f"  - {row['name']}: {row['conclusion']} ({row.get('url')})")
    if data["pending"]:
        print("pending:")
        for row in data["pending"]:
            print(f"  - {row['name']}: {row['status']}")


def main(argv: list[str] | None = None) -> int:
    import argparse

    parser = argparse.ArgumentParser(
        description="Summarize the latest GitHub Actions run for this branch."
    )
    parser.add_argument("--branch", help="Branch name (default: current git branch)")
    parser.add_argument(
        "--workflow",
        default="Flutter",
        help='Workflow name filter (default: "Flutter"; use "" for any)',
    )
    parser.add_argument("--json", action="store_true", help="Print machine-readable JSON")
    parser.add_argument(
        "--write",
        type=Path,
        help="Also write summary JSON to this path",
    )
    parser.add_argument(
        "--download-artifact",
        metavar="NAME",
        help="Download a named artifact from the selected run via gh",
    )
    parser.add_argument(
        "--artifact-dir",
        type=Path,
        default=None,
        help="Directory for --download-artifact (default: build/diagnostics/actions-artifacts)",
    )
    args = parser.parse_args(argv)

    workflow = args.workflow or None
    summary = fetch_latest_summary(branch=args.branch, workflow=workflow)
    if args.write:
        write_local_summary(args.write, summary)
    if args.download_artifact:
        path = download_artifact(
            name=args.download_artifact,
            run_id=summary.run_id,
            branch=args.branch,
            workflow=workflow,
            dest=args.artifact_dir,
        )
        print(f"artifact_dir: {path}", file=sys.stderr)
    if args.json:
        print(json.dumps(summary_to_dict(summary), indent=2))
    else:
        print_human(summary)

    if summary.conclusion == "failure":
        return 1
    if summary.conclusion is None and summary.run_id is None:
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
