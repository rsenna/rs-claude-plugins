# Issue #10 — issue.sh/pr.sh: no sanctioned way to create a new issue under the bot identity

https://github.com/rsenna/rs-claude-plugins/issues/10

## Tasks

- [ ] **1 — Add `create` subcommand to `issue.sh` with bot-identity enforcement**
  - Acceptance: `skills/map-issue-to-tasks/issue.sh` support `create <repo> <title> <file>`, run `gh issue create --repo <repo> --title <title> --body-file <file>`. Same Doppler/`GH_TOKEN` enforce as other subcommand (die loud if no bot token; no ambient `gh auth` fallback).
  - Verify: no project-wide quality gate doc for repo. Run `bash -n skills/map-issue-to-tasks/issue.sh` + DRY_RUN call, confirm command shape.
  - Files: `skills/map-issue-to-tasks/issue.sh`

- [ ] **2 — Wire `create` into usage/help and DRY_RUN behavior**
  - Acceptance: subcommand list, usage string, command dispatch include `create`. With `DRY_RUN=1`, command print what would create, no open/modify issue.
  - Verify: no project-wide quality gate doc for repo. Run `issue.sh` usage output + `DRY_RUN=1 issue.sh create ...` smoke check.
  - Files: `skills/map-issue-to-tasks/issue.sh`

- [ ] **3 — Update map-issue-to-tasks skill docs to include sanctioned create flow**
  - Acceptance: `skills/map-issue-to-tasks/SKILL.md` document when use `issue.sh create` (cross-repo follow-up issue), include example command.
  - Verify: no project-wide quality gate doc for repo. Docs self-review, check consistent w/ script behavior.
  - Files: `skills/map-issue-to-tasks/SKILL.md`