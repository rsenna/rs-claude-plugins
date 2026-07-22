---
name: fix-mapped-issue
description: Implement the tasks mapped from a GitHub issue, ship each through the pull-request process, and close the issue once everything is merged. Use when asked to fix/work/implement/resolve a GitHub issue that already has a task breakdown (tasks/issue-<n>-*.md). Runs after map-issue-to-tasks.
---

# Fix Mapped Issue

Steps 4–6 of the issue lifecycle: **implement the mapped tasks, ship them via the
pull-request process, then update and close the issue.** Assumes
`map-issue-to-tasks` already produced `tasks/issue-<n>-<slug>.md`. If that file
doesn't exist, run `map-issue-to-tasks` first.

Reuses the sibling skills' scripts (this plugin's other skills):
- `${CLAUDE_PLUGIN_ROOT}/skills/pull-request-process/pr.sh` (branch/push/PR/threads)
- `${CLAUDE_PLUGIN_ROOT}/skills/map-issue-to-tasks/issue.sh` (`close` for the final comment)

## Portability — read the project's specifics first

From the project's `AGENTS.md`/`CLAUDE.md`: the **base branch** and the
**quality gate command + coverage bar** (e.g. `what-about`:
`mix precommit --cover`, ≥ 90% — AGENTS.md:23–30). Pass the base branch as
`BASE=` to `pr.sh`.

## Do this (per task, until the issue is done)

1. **Pick the next task** from `tasks/issue-<n>-*.md`: the next unchecked box,
   respecting dependency order. If it's a 🔒 ask-first gate (new dependency, DB
   migration, CI/secret change), **pause and get explicit approval** before starting.
2. **Implement** via the `incremental-implementation` and
   `test-driven-development` skills. New or changed behaviour **must be described
   by tests** (behaviour-asserting, not coverage-padding).
3. **Ship it via the `pull-request-process` skill** — one task ≈ one PR:
   `pr.sh start` → implement/commit → run the gate → `pr.sh push` → `pr.sh open`
   → **STOP** (never merge). Then handle review threads per that skill.
4. **After the maintainer/bots merge**, tick the task in `tasks/issue-<n>-*.md`
   and move to the next. Repeat until every task is merged.

## Close it (step 6)

Once **all** tasks are merged:
1. Write a **solution comment**: what shipped, and links to the merged PRs.
2. `issue.sh close <n> <solution.md>` — posts the comment and closes the issue.
   (`DRY_RUN=1` previews without posting/closing.)

```bash
P=${CLAUDE_PLUGIN_ROOT}/skills/pull-request-process/pr.sh
I=${CLAUDE_PLUGIN_ROOT}/skills/map-issue-to-tasks/issue.sh
BASE=main "$P" start fix/issue-24-notify
# …implement + test…  then run the project gate…
BASE=main "$P" push fix/issue-24-notify
BASE=main "$P" open "feat: notify on (re)publish (#24)" pr-body.md   # then STOP
# …after all tasks merged…
DRY_RUN=1 "$I" close 24 solution.md      # preview
"$I" close 24 solution.md                # post solution + close
```

## Guardrails (never violate)

- Never merge a PR, never mark it ready — bots/maintainer do that.
- Never resolve review threads — reply per thread; the maintainer resolves.
- Never close the issue until **every** mapped task is merged.
- Never push unless the project's quality gate is green.
