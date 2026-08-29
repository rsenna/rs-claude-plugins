# Issue #10 — issue.sh/pr.sh: no sanctioned way to create a new issue under the bot identity

https://github.com/rsenna/rs-claude-plugins/issues/10

## Tasks

- [x] **1 — Add `create` subcommand to `issue.sh` with bot-identity enforcement**
  - Acceptance: `skills/map-issue-to-tasks/issue.sh` supports `create <repo> <title> <file>` and runs `gh issue create --repo <repo> --title <title> --body-file <file>`. It enforces Doppler/`GH_TOKEN` exactly like the other subcommands: die loudly when the bot token is unavailable; never fall back to ambient `gh auth`.
  - Verify: no project-wide quality gate is documented for this repo. Run `bash -n skills/map-issue-to-tasks/issue.sh` and a `DRY_RUN=1` invocation; confirm the command shape.
  - Files: `skills/map-issue-to-tasks/issue.sh`

- [x] **2 — Wire `create` into usage/help and DRY_RUN behavior**
  - Acceptance: the subcommand list, usage string, and command dispatch include `create`. With `DRY_RUN=1`, the command prints what it would create without opening or modifying an issue.
  - Verify: no project-wide quality gate is documented for this repo. Check `issue.sh` usage output and smoke-test `DRY_RUN=1 issue.sh create ...`.
  - Files: `skills/map-issue-to-tasks/issue.sh`

- [x] **3 — Update map-issue-to-tasks skill docs to include sanctioned create flow**
  - Acceptance: `skills/map-issue-to-tasks/SKILL.md` documents when to use `issue.sh create` (for a cross-repo follow-up issue) and includes an example command.
  - Verify: no project-wide quality gate is documented for this repo. Self-review the docs and confirm they match script behavior.
  - Files: `skills/map-issue-to-tasks/SKILL.md`
