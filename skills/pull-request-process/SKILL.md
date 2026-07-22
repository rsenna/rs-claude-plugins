---
name: pull-request-process
description: Open a pull request the safe way and handle review comments on it. Use when creating a branch, pushing work, opening a PR, or working through bot/human review threads. Encodes branch hygiene, an explicit-refspec push that can't accidentally advance main, "open the PR but never merge — bots/maintainer review," and the per-thread review-reply loop.
---

# Pull Request Process

The repeatable, safe way to ship a change: branch → run the project's quality
gate → push without ever touching `main` → open a PR → **stop** (never merge) →
work each review thread. This is a **building block** other skills call
(`fix-mapped-issue` follows it for "till the issue is fixed").

The git/gh plumbing is in **`pr.sh`**, at `${CLAUDE_PLUGIN_ROOT}/skills/pull-request-process/pr.sh`.
It is language-agnostic and **does not run the quality gate** — you do, per the project's docs.

## Portability — read the project's specifics first

This skill hardcodes nothing project-specific. Before shipping, read from the
project's `AGENTS.md`/`CLAUDE.md`:
- **Base branch** (usually `main`) → pass as `BASE=<branch>` to `pr.sh`.
- **The quality gate command** and any coverage bar (e.g. `cargo test` for
  Rust, `mix precommit --cover` for Elixir — read AGENTS.md for the exact
  command and thresholds).

If the project has no documented gate, run its tests + formatter/linter and say so.

## The process

1. **Branch.** `pr.sh start <branch>` — updates local `main` and cuts the branch
   the safe way. Do this on a feature branch; never commit straight to `main`.
2. **Implement + commit.** (Commit conventions: follow the
   `git-workflow-and-versioning` skill.)
3. **Gate.** Run the project's quality gate yourself. **Do not push unless green.**
4. **Push.** `pr.sh push <branch>` — explicit-refspec push, then verifies the
   branch landed and `origin/main` did **not** move.
5. **Open.** `pr.sh open "<title>" [body.md]` — `gh pr create --base main`,
   prints the URL, then **STOP.** Do not merge, do not mark ready — automated
   review bots and the maintainer review and merge.
6. **Review loop.** When comments arrive: `pr.sh threads <pr>` lists unresolved
   threads (with numeric comment IDs). `pr.sh reviews <pr>` lists PR-level
   review comments (a bot's "Overall Comments" on the review itself, not on a
   line — these have no thread and can't be replied to with `reply`; the
   command pulls out each bot's "Prompt for AI Agent(s)" block when present).
   For each unresolved thread: make the fix if warranted (re-push via step 4,
   keeping the gate green), then **reply on that thread** with your conclusion:

   ```bash
   # Reply with an inline message:
   pr.sh reply 27 3623709612 "Fixed in abc1234. ..."

   # Or reply from a file:
   pr.sh reply 27 3623709612 /tmp/reply.md
   ```

   **Never resolve threads yourself and never merge** — the maintainer does both.
7. **Cleanup.** Once the PR is opened, `pr.sh cleanup` leaves the worktree ready
   for the next task: it verifies the tree is **pristine** and switches back to
   `main`. It is **non-destructive** — if there are uncommitted or untracked
   files it reports them and stops (never discards), so you can commit/stash/remove
   them and re-run. (`git status --porcelain` ignores gitignored build artifacts
   like `target/`, `node_modules/`, `_build/`, so those don't count as dirty.)
   Run this after `open`, and also after
   the review loop when you switch away to another task.

## Commands (verified)

```bash
P=${CLAUDE_PLUGIN_ROOT}/skills/pull-request-process/pr.sh
BASE=main "$P" start  my-feature          # cut branch off up-to-date main
BASE=main "$P" push   my-feature          # safe push + verify main didn't advance
BASE=main "$P" open   "feat: my feature" body.md   # gh pr create --base main, then STOP
BASE=main DRAFT=1 "$P" open "wip: experiment"      # open as draft (bots typically skip drafts)
BASE=main DRY_RUN=1 "$P" open "feat: foo"          # preview the gh command without creating
"$P" threads 17                            # list unresolved review threads on PR #17
"$P" reviews 17                            # list PR-level review comments + their AI-agent prompts
"$P" reply 17 3623709612 "Fixed in abc1234."       # reply to a thread (inline)
"$P" reply 17 3623709612 /tmp/reply.md             # reply to a thread (file)
BASE=main "$P" cleanup                     # verify pristine, switch back to main (non-destructive)
```

`threads` truncates each comment body to 280 chars — enough to identify the
concern, not enough to read an entire review. Use the PR URL for full context.
The numeric comment IDs shown can be passed to `reply` to post a response on
that thread.

## Why the push is done this way (don't shortcut it)

- Create branches with **plain** `git checkout -b <name>` off an updated local
  `main` — **not** `git checkout -b <name> origin/main`. The latter makes the
  branch *track* `main`; with `push.default=upstream` a bare `git push` then
  writes to `origin/main`, bypassing the whole PR/review flow. `pr.sh start`
  does it the safe way for you.
- Always push with an **explicit refspec** (`git push origin HEAD:refs/heads/<name>`)
  and verify afterward. `pr.sh push` captures `origin/main` before and after and
  **fails loudly if it moved** — this is the guardrail against the once-real
  accident of pushing straight to `main`.

## Guardrails (never violate)

- Never merge a PR or mark it ready-to-merge.
- Never resolve review threads — reply, and let the maintainer resolve.
- Never push unless the project's quality gate is green.
- One concern per PR.
