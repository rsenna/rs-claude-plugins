# Issue #14 — pr.sh worktrees should not live alongside personal repos under ~/REPO/ME

https://github.com/rsenna/rs-claude-plugins/issues/14

## Tasks

- [x] **1 — Define centralized worktree-root strategy for `pr.sh`**
  - Accept: `skills/pull-request-process/pr.sh` has single resolver for worktree root, used by both `start` and `cleanup`, default location **not** sibling of main checkout (agent worktrees never share parent dir w/ personal repos).
  - Verify: no project-wide quality gate for this repo; run `bash -n skills/pull-request-process/pr.sh`, inspect resolver call sites in `cmd_start`/`cmd_cleanup`.
  - Files: `skills/pull-request-process/pr.sh`

- [x] **2 — Migrate `start`/`cleanup` to new root, keep safety guardrails**
  - Accept: `cmd_start` creates new worktrees under centralized root; `cmd_cleanup` removes worktrees only under sanctioned roots (new root + explicit transitional compat for old legacy paths if needed), keeps same non-destructive behavior for dirty/ignored files.
  - Verify: no project-wide quality gate for this repo; run `bash -n skills/pull-request-process/pr.sh`, then smoke-check w/ `BASE=main skills/pull-request-process/pr.sh start <tmp-branch>` and `BASE=main skills/pull-request-process/pr.sh cleanup` from that worktree.
  - Files: `skills/pull-request-process/pr.sh`

- [x] **3 — Update pull-request-process docs to match new worktree location model**
  - Accept: `skills/pull-request-process/SKILL.md` + affected inline script help text describe where task worktrees are made, how users/agents find them, cleanup behavior; wording no longer says sibling `<repo>-worktrees` next to repo checkout.
  - Verify: no project-wide quality gate for this repo; docs self-review confirms cmd examples + behavior desc match `pr.sh`.
  - Files: `skills/pull-request-process/SKILL.md`, `skills/pull-request-process/pr.sh`

- [x] **4 — Validate cross-repo safety intent from issue**
  - Accept: final behavior guarantees for checkouts under `~/REPO/ME/<repo>`, generated worktrees not created under `~/REPO/ME/`; log output still gives easy `cd` target for ongoing work.
  - Verify: no project-wide quality gate for this repo; manual smoke check confirms printed worktree path outside `~/REPO/ME/`, cleanup still returns to main checkout path.
  - Files: `skills/pull-request-process/pr.sh`
  - Note: guarantee above holds for default centralized root only. Explicit `PR_WORKTREE_ROOT` override validated (must be absolute, must not be inside main checkout) but otherwise unrestricted — operator can point it anywhere, incl under `~/REPO/ME/`. Deliberate: overrides target non-standard layouts (e.g. 2nd disk), policing operator's chosen mount out of scope for this issue.