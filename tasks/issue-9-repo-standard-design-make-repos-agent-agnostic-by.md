# Issue #9 — repo-standard-design: make repos agent-agnostic by default (Claude, Copilot, others)

https://github.com/rsenna/rs-claude-plugins/issues/9

## Tasks

- [x] **1 — Amend repo-standard design doc w/ explicit agent-agnostic default**
  - Accept: `docs/superpowers/specs/2026-08-01-repo-standard-design.md` states plain: repos multi-agent by default; scaffold for one agent must not replace/prune another agent's integration.
  - Verify: no project-wide quality gate documented this repo; do docs consistency review vs issue ask + existing required-paths table.
  - Files: `docs/superpowers/specs/2026-08-01-repo-standard-design.md`

- [x] **2 — Define where policy binding for agents picking up repo cold**
  - Accept: same design doc states rule must show in two spots: (1) **in-progress/released stage narrative** section, (2) **Guardrails** section agents read when scaffolding. Both needed so agents no infer single-agent scope from silence.
  - Verify: no project-wide quality gate documented this repo; check reader find policy from both named sections w/o outside context.
  - Files: `docs/superpowers/specs/2026-08-01-repo-standard-design.md`

- [x] **3 — Align `repo-standard` skill wording w/ new policy**
  - Accept: `skills/repo-standard/SKILL.md` reflects agent-agnostic principle in scaffold guidance, no imply active session agent only supported integration surface.
  - Verify: no project-wide quality gate documented this repo; `bash -n skills/repo-standard/SKILL.md` not applicable (docs only); do docs self-review for consistency w/ agent-agnostic policy from tasks 1 + 2.
  - Files: `skills/repo-standard/SKILL.md`