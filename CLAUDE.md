# Claude instructions

Claude / `@claude` is available in this repository through `.github/workflows/claude.yml`.
Shared autonomy and escalation rules live in `AGENTS.md`. Prefer that file as the single source of truth for common agent behavior.

## Claude-specific notes

- Keep changes small and scoped to the request. Do not perform unrelated refactors or dependency upgrades.
- Preserve existing CI, deployment, and GitHub Pages configuration unless the request explicitly requires changing it.
- For implementation tasks, run the smallest relevant existing checks and report the result in the pull request.
- The Claude GitHub Action authenticates with `CLAUDE_CODE_OAUTH_TOKEN` (not `ANTHROPIC_API_KEY`).

## Review-only requests

When asked to audit, observe, or review only, leave findings as comments. Do not edit files, create commits, or open a pull request unless explicitly asked to implement a change. This matches the shared task-mode rule in `AGENTS.md`.

## Role reminder

- ChatGPT: design / requirements / pre-review
- Cursor: implementation / test / PR
- Copilot: GitHub-side audit / CI analysis
- Claude (`@claude`): on-demand GitHub assistance when mentioned or manually dispatched
