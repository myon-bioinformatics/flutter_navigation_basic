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


def _current_head_sha() -> str:
    result = subprocess.run(
        ["git", "rev-parse", "HEAD"],
        cwd=_repo_root(),
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout.strip()


def fetch_latest_summary(
    *,
    branch: str | None = None,
    workflow: str | None = "Flutter",
) -> ActionsSummary:
    if _gh_available():
        return fetch_summary_via_gh(branch=branch, workflow=workflow)
    return fetch_summary_via_api(branch=branch, workflow=workflow)


def evaluate_summary(
    summary: ActionsSummary,
    *,
    allow_stale: bool = False,
    expected_sha: str | None = None,
) -> tuple[int, list[str]]:
    """Return (exit_code, reasons).

    Default policy:
    - require a run
    - require conclusion == \"success\" (cancelled/timed_out/failure/etc. are non-zero)
    - require summary.head_sha == current git HEAD (unless allow_stale)
    """
    reasons: list[str] = []
    expected = expected_sha or _current_head_sha()

    if summary.run_id is None:
        return 2, ["no workflow run found for branch/workflow"]

    if summary.conclusion != "success":
        reasons.append(
            f"conclusion is {summary.conclusion!r} (only 'success' exits 0)"
        )
        return 1, reasons

    if not summary.head_sha:
        reasons.append("run head_sha is missing")
        return 3, reasons

    if summary.head_sha != expected:
        msg = f"stale run: run head_sha {summary.head_sha} != current HEAD {expected}"
        if allow_stale:
            reasons.append(msg + " (--allow-stale)")
            return 0, reasons
        reasons.append(msg + " (pass --allow-stale to override)")
        return 3, reasons

    return 0, reasons


def download_artifact(
    *,
    name: str,
    summary: ActionsSummary | None = None,
    run_id: int | None = None,
    branch: str | None = None,
    workflow: str | None = "Flutter",
    dest: Path | None = None,
    allow_stale: bool = False,
    expected_sha: str | None = None,
) -> Path:
    """Download a named artifact only from a freshness-checked green run."""
    if not _gh_available():
        raise RuntimeError("Artifact download requires the gh CLI.")
    if summary is None:
        summary = fetch_summary_via_gh(branch=branch, workflow=workflow)
    if run_id is not None:
        summary = ActionsSummary(
            branch=summary.branch,
            workflow=summary.workflow,
            run_id=run_id,
            head_sha=summary.head_sha if summary.run_id == run_id else summary.head_sha,
            conclusion=summary.conclusion if summary.run_id == run_id else summary.conclusion,
            url=summary.url,
            checks=summary.checks if summary.run_id == run_id else summary.checks,
            source=summary.source,
        )
    code, reasons = evaluate_summary(
        summary,
        allow_stale=allow_stale,
        expected_sha=expected_sha,
    )
    if code != 0:
        raise RuntimeError(
            "Refusing artifact download until Actions summary is fresh/green: "
            + "; ".join(reasons)
        )
    if summary.run_id is None:
        raise RuntimeError("No workflow run id available for artifact download.")

    dest = dest or (_repo_root() / "build" / "diagnostics" / "actions-artifacts")
    dest.mkdir(parents=True, exist_ok=True)
    _run_gh(
        [
            "run",
            "download",
            str(summary.run_id),
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


def summary_to_dict(
    summary: ActionsSummary,
    *,
    allow_stale: bool = False,
    expected_sha: str | None = None,
) -> dict[str, Any]:
    expected = expected_sha or _current_head_sha()
    exit_code, reasons = evaluate_summary(
        summary,
        allow_stale=allow_stale,
        expected_sha=expected,
    )
    return {
        "branch": summary.branch,
        "workflow": summary.workflow,
        "run_id": summary.run_id,
        "head_sha": summary.head_sha,
        "expected_sha": expected,
        "fresh": summary.head_sha == expected,
        "allow_stale": allow_stale,
        "evaluation_exit_code": exit_code,
        "evaluation_reasons": reasons,
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


def print_human(
    summary: ActionsSummary,
    *,
    allow_stale: bool = False,
    expected_sha: str | None = None,
) -> None:
    data = summary_to_dict(
        summary,
        allow_stale=allow_stale,
        expected_sha=expected_sha,
    )
    print(f"branch: {data['branch']}")
    print(f"workflow: {data['workflow']}")
    print(f"run_id: {data['run_id']}")
    print(f"head_sha: {data['head_sha']}")
    print(f"expected_sha: {data['expected_sha']}")
    print(f"fresh: {data['fresh']}")
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
    if data["evaluation_reasons"]:
        print("evaluation:")
        for reason in data["evaluation_reasons"]:
            print(f"  - {reason}")


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
    parser.add_argument(
        "--allow-stale",
        action="store_true",
        help="Allow a green run whose head_sha differs from current git HEAD",
    )
    parser.add_argument(
        "--expected-sha",
        help="Override the SHA freshness check (default: git rev-parse HEAD)",
    )
    args = parser.parse_args(argv)

    workflow = args.workflow or None
    summary = fetch_latest_summary(branch=args.branch, workflow=workflow)
    data = summary_to_dict(
        summary,
        allow_stale=args.allow_stale,
        expected_sha=args.expected_sha,
    )
    if args.write:
        args.write.parent.mkdir(parents=True, exist_ok=True)
        args.write.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    if args.download_artifact:
        try:
            path = download_artifact(
                name=args.download_artifact,
                summary=summary,
                branch=args.branch,
                workflow=workflow,
                dest=args.artifact_dir,
                allow_stale=args.allow_stale,
                expected_sha=args.expected_sha,
            )
        except RuntimeError as error:
            print(str(error), file=sys.stderr)
            if args.json:
                print(json.dumps(data, indent=2))
            else:
                print_human(
                    summary,
                    allow_stale=args.allow_stale,
                    expected_sha=args.expected_sha,
                )
            return int(data["evaluation_exit_code"]) or 1
        print(f"artifact_dir: {path}", file=sys.stderr)
    if args.json:
        print(json.dumps(data, indent=2))
    else:
        print_human(
            summary,
            allow_stale=args.allow_stale,
            expected_sha=args.expected_sha,
        )

    return int(data["evaluation_exit_code"])


if __name__ == "__main__":
    raise SystemExit(main())
