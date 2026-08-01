# Issue #3 — Design: cross-repo doc/folder standard (repo.toml stage tiers) + repo-standard skill

https://github.com/rsenna/rs-claude-plugins/issues/3

## Tasks

- [x] **1 — Write and commit the design doc**
  - Acceptance: `docs/superpowers/specs/2026-08-01-repo-standard-design.md`
    covers the `repo.toml` `stage` field, the per-stage doc/folder tier
    table, and the `repo-standard` skill's audit/scaffold enforcement model.
  - Verify: self-review for placeholders/contradictions/scope (done); no
    code gate applies (docs-only change in a skills/docs repo).
  - Files: `docs/superpowers/specs/2026-08-01-repo-standard-design.md`

- [ ] **2 — Implement the `repo-standard` skill** 🔓
  - Acceptance: `skills/repo-standard/SKILL.md` implements `audit` (read-only
    diff against the declared stage's tier) and `scaffold` (non-destructive
    creation of what's missing), matching the design doc's Section 3.
  - Verify: manual dry run against at least one real repo per stage tier
    that exists today (e.g. roset.sh for `prototype`, iklo for
    `in-progress`).
  - Files: `skills/repo-standard/SKILL.md` (+ any supporting script)

- [ ] **3 — Set `stage` + roll out tiers per repo, one PR each**
  - Acceptance: each of roset.sh, iklo, what-about, guiltty,
    obsidian-hivemind, wawk.js has a `repo.toml` `stage` field and matches
    its tier's required artifacts — shipped as separate, per-repo PRs
    through the normal issue → worktree → PR flow, not one mass edit.
  - Verify: `repo-standard audit` (from task 2) reports clean for each repo
    after its PR merges.
  - Files: `repo.toml`, `AGENTS.md`, `README.md`, and stage-specific spec
    folders in each of the six repos.
