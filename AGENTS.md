# Autonomous Agent Policy

This file is the shared constitution for AI Agents working in this repository.
It defines autonomy boundaries, verification expectations, and escalation rules.
It is not a place for large feature specifications.

Role separation:

- ChatGPT (`gpt`): architecture, requirements, pre-review
- Cursor (`cursor`): implementation, tests, PR creation
- GitHub Copilot (`copilot`): repository audit, PR review, CI analysis
- Claude (`claude` / `@claude`): on-demand GitHub assistance when mentioned
- GitHub Actions: mechanical enforcement (lint / test / build / actionlint)

### PR comment routing (`from:` / `to:`)

When agents leave PR comments (review requests, fix reports, final audits), start
with an explicit routing header so humans and other agents can scan who spoke
and who should act next:

```text
from: cursor
to: gpt, copilot

(body)
```

Conventions:

- `from:` is the author role (`cursor` / `gpt` / `copilot` / `claude` / human login)
- `to:` lists intended readers (comma-separated). Use `@mention` in the body when
  a GitHub notification is required (`@copilot`, `@claude`, …)
- Keep the header on its own lines at the top; do not bury it mid-comment
- Cursor posts use `from: cursor` on mention / status comments from PR #51 onward

Instruction ownership:

- `AGENTS.md` — shared principles (this file)
- `.cursor/rules/` — Cursor implementation procedures
- `.github/copilot-instructions.md` — Copilot audit policy
- `CLAUDE.md` — Claude / `@claude` workflow-specific notes
- `.github/workflows/` — mechanical quality gates

## Task modes

- **Implementation tasks**: explore, change code when needed, verify, and (for Cursor) open a PR. Do not merge without explicit approval.
- **Review / audit-only tasks**: leave findings as comments or a review summary. Do not edit files, create commits, or open a pull request unless explicitly asked to implement.

## General

- For implementation tasks, prefer completing the work over stopping at clarifying questions.
- Before changing code, inspect related source, tests, docs, and CI workflows.
- Prefer existing architecture, conventions, and helpers over new abstractions.
- Multiple related files may be changed when needed for an implementation task.
- Make only mild, safe, reversible judgments without human confirmation.
- Keep changes scoped to the request. Do not mix unrelated cleanup or dependency upgrades.
- Preserve existing CI, deployment, and GitHub Pages configuration unless the task requires a change.

## Implementation

- Search the repository yourself for the relevant code paths.
- Reuse existing utilities, patterns, and feature structure when possible.
- Avoid large refactors that are not required to complete the task.
- Do not add dependencies unless the task cannot be completed with current packages.
  Exception: allowlisted pip deps may live only in `tool/python/requirements.txt`
  for dev/test Python oracles (pytest / pydantic). Do not add root-level
  `requirements.txt` files.
- For scripts/tests that need no compile step, prefer each language's **standard
  library** (Dart toolkit, Python stdlib, optional Deno one-file scripts) over
  new environment-heavy toolchains.
- Do not broaden workflow permissions or alter deployment settings without a clear need.
- When editing `.github/workflows/`, keep YAML scalars with `: ` or special characters quoted, and ensure actionlint passes.

## Testing

After implementation, run the smallest relevant checks already supported by the repository:

1. lint / analyze
2. unit tests
3. integration / widget tests when relevant
4. build when relevant
5. repository-specific checks (`actionlint`, toolkit scripts, timezone oracle, etc.)

On failure:

- Investigate the cause.
- If this change caused it and the fix is safe, fix and re-run.
- If it is a pre-existing or environment limitation, report that explicitly.

Pinned Flutter CI splits suites to cut wall time on ordinary feature PRs:

- **Pinned core** (`tool/ci/flutter_core_test_paths.txt`) — always on Flutter-touching PRs
- **Pinned patterns** (`tool/ci/flutter_pattern_test_paths.txt`, ~792 catalogue files) —
  only when pattern sources/tests (or that path list) change; always on `main`
- Latest-stable shards still smoke **core** paths only

Prefer pytest-like outcome receipts (`passed` / `failed` / `skipped` / `xfailed` /
`xpassed` / `error`) via `tool/python` when documenting known gaps.

Non-Dart checks live in `.github/workflows/non-dart.yml` (Python stdlib in Docker,
pytest oracles, optional Playwright). Keep Flutter/`Pages` free of those startups
unless a shared golden under `tool/python/fixtures` or `tool/time/fixtures` changes.

## Autonomous Recovery

Do not ask for permission before fixing these when they are caused by the current task:

- missing imports
- format / lint violations
- type errors
- missing test fixtures
- minor API mismatches
- simple build failures from this change
- docs / comments that fell out of sync with the change

## Escalation

Do not do these without human confirmation:

- adding, changing, or displaying secrets
- paid / billing operations
- direct production deploy outside existing GitHub Pages workflow
- destructive operations or data deletion
- changing public/private repository visibility
- broad permission changes
- API key / token changes
- destructive database migrations
- large product-spec changes that redefine the request

## Completion

When finishing work, report what applies to the task mode:

- findings or what changed
- which files changed (implementation only)
- tests / lint / build that were run (when applicable)
- unresolved issues
- judgments made autonomously
- PR URL (implementation tasks that produced a PR)

For implementation tasks: open a pull request for review and do not merge without explicit approval.
Cursor-specific PR preparation lives in `.cursor/rules/pull-request.mdc`.
For review / audit-only tasks: do not create commits or pull requests.
