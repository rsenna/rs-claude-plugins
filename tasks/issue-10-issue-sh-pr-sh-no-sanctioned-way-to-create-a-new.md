# Issue #10 — issue.sh/pr.sh: no sanctioned way to create a new issue under the bot identity

https://github.com/rsenna/rs-claude-plugins/issues/10

## Tasks

- [ ] **1 — Add `create` subcommand to `issue.sh` with bot-identity enforcement**
  - Acceptance: `skills/map-issue-to-tasks/issue.sh` supports `create <repo> <title> <file>` and runs `gh issue create --repo <repo> --title <title> --body-file <file>` using the same Doppler/`GH_TOKEN` enforcement posture as existing subcommands (die loudly if bot token unavailable; no ambient `gh auth` fallback).
  - Verify: no project-wide quality gate is documented for this repo; run `bash -n skills/map-issue-to-tasks/issue.sh` and a DRY_RUN invocation to confirm command shape.
  - Files: `skills/map-issue-to-tasks/issue.sh`

- [ ] **2 — Wire `create` into usage/help and DRY_RUN behavior**
  - Acceptance: Subcommand list, usage string, and command dispatch include `create`; with `DRY_RUN=1`, command prints what would be created and does not open/modify issues.
  - Verify: no project-wide quality gate is documented for this repo; run `issue.sh` usage output and `DRY_RUN=1 issue.sh create ...` smoke check.
  - Files: `skills/map-issue-to-tasks/issue.sh`

- [ ] **3 — Update map-issue-to-tasks skill docs to include sanctioned create flow**
  - Acceptance: `skills/map-issue-to-tasks/SKILL.md` documents when to use `issue.sh create` (cross-repo follow-up issues) and includes an example command.
  - Verify: no project-wide quality gate is documented for this repo; docs self-review for consistency with script behavior.
  - Files: `skills/map-issue-to-tasks/SKILL.md`

