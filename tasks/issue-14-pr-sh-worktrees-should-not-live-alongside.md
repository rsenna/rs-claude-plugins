# Issue #14 — pr.sh worktrees should not live alongside personal repos under ~/REPO/ME

https://github.com/rsenna/rs-agent-plugin/issues/14

## Tasks

- [x] **1 — Define a centralized worktree-root strategy for `pr.sh`**
  - Acceptance: `skills/pull-request-process/pr.sh` has a single resolver for the worktree root used by both `start` and `cleanup`, with a default location that is **not** a sibling of the main checkout (so agent worktrees never share a parent directory with personal repos).
  - Verify: no project-wide quality gate is documented for this repo; run `bash -n skills/pull-request-process/pr.sh` and inspect the resolver call sites in `cmd_start`/`cmd_cleanup`.
  - Files: `skills/pull-request-process/pr.sh`

- [x] **2 — Migrate `start`/`cleanup` to the new root without weakening safety guardrails**
  - Acceptance: `cmd_start` creates new worktrees under the centralized root; `cmd_cleanup` only removes worktrees under sanctioned roots (new root, plus explicit transitional compatibility for previously created legacy paths if needed) and keeps the same non-destructive behavior for dirty/ignored files.
  - Verify: no project-wide quality gate is documented for this repo; run `bash -n skills/pull-request-process/pr.sh`, then smoke-check with `BASE=main skills/pull-request-process/pr.sh start <tmp-branch>` and `BASE=main skills/pull-request-process/pr.sh cleanup` from that worktree.
  - Files: `skills/pull-request-process/pr.sh`

- [x] **3 — Update pull-request-process docs to match the new worktree location model**
  - Acceptance: `skills/pull-request-process/SKILL.md` and any affected inline script help text describe where task worktrees are created, how users/agents find them, and how cleanup behaves; wording no longer says sibling `<repo>-worktrees` next to the repo checkout.
  - Verify: no project-wide quality gate is documented for this repo; docs self-review confirms command examples and behavior description match `pr.sh`.
  - Files: `skills/pull-request-process/SKILL.md`, `skills/pull-request-process/pr.sh`

- [x] **4 — Validate cross-repo safety intent from the issue**
  - Acceptance: final behavior guarantees that for checkouts under `~/REPO/ME/<repo>`, generated worktrees are not created under `~/REPO/ME/`; log output still provides an easy `cd` target for ongoing work.
  - Verify: no project-wide quality gate is documented for this repo; manual smoke check confirms the printed worktree path is outside `~/REPO/ME/` and cleanup still returns to the main checkout path.
  - Files: `skills/pull-request-process/pr.sh`
  - Note: the guarantee above holds for the default centralized root. An explicit `PR_WORKTREE_ROOT` override is validated (must be absolute, must not be inside the main checkout) but is otherwise unrestricted — an operator can point it anywhere, including under `~/REPO/ME/`. That is deliberate: overrides target non-standard layouts (e.g. a second disk), and policing the operator's chosen mount was out of scope for this issue.
