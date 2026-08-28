# Issue #9 — repo-standard-design: make repos agent-agnostic by default (Claude, Copilot, others)

https://github.com/rsenna/rs-claude-plugins/issues/9

## Tasks

- [x] **1 — Amend the repo-standard design doc with an explicit agent-agnostic default**
  - Acceptance: `docs/superpowers/specs/2026-08-01-repo-standard-design.md` states plainly that repos are multi-agent by default; scaffolding for one agent must not replace/prune another agent's integration.
  - Verify: no project-wide quality gate is documented for this repo; perform docs consistency review against the issue ask and existing required-paths table.
  - Files: `docs/superpowers/specs/2026-08-01-repo-standard-design.md`

- [x] **2 — Define where the policy is binding for agents picking up a repo cold**
  - Acceptance: the same design doc states where the rule must be visible in two specific locations: (1) the **in-progress/released stage narrative** section and (2) the **Guardrails** section that agents read when scaffolding. Both must be present so agents do not infer single-agent scope from silence.
  - Verify: no project-wide quality gate is documented for this repo; check that a reader can find the policy from both named sections of the design doc without external context.
  - Files: `docs/superpowers/specs/2026-08-01-repo-standard-design.md`

- [x] **3 — Align `repo-standard` skill wording with the new policy**
  - Acceptance: `skills/repo-standard/SKILL.md` reflects the agent-agnostic principle in scaffold guidance and does not imply that the active session agent is the only supported integration surface.
  - Verify: no project-wide quality gate is documented for this repo; `bash -n skills/repo-standard/SKILL.md` is not applicable (docs only); perform docs self-review for consistency with the agent-agnostic policy from tasks 1 and 2.
  - Files: `skills/repo-standard/SKILL.md`
