# Issue #3 — Design: cross-repo doc/folder standard (repo.toml stage tiers) + repo-standard skill

https://github.com/rsenna/rs-claude-plugins/issues/3

## Tasks

- [x] **1 — Write and commit design doc** — ✅ merged (#4)
  - Acceptance: `docs/superpowers/specs/2026-08-01-repo-standard-design.md` covers `repo.toml` `stage` field, per-stage doc/folder tier table, and `repo-standard` skill's audit/scaffold enforcement model.
  - Verify: self-review for placeholders/contradictions/scope (done); no code gate applies (docs-only change in skills/docs repo).
  - Files: `docs/superpowers/specs/2026-08-01-repo-standard-design.md`

- [x] **2 — Implement `repo-standard` skill** ✅ merged (#16)
  - Acceptance: `skills/repo-standard/SKILL.md` implements `audit` (read-only diff against declared stage's tier) and `scaffold` (non-destructive creation of what's missing), matching design doc's Section 3.
  - Verify: manual dry run against at least one real repo per stage tier that exists today (e.g. roset.sh for `prototype`, iklo for `in-progress`). Each test repo must have valid `stage` in `repo.toml` before running audit/scaffold — skill fails closed on missing or invalid value (by design). Also verify `audit` fails with clear error on repo without `repo.toml`.
  - Files: `skills/repo-standard/SKILL.md` (+ any supporting script)

- [ ] **3 — Set `stage` + roll out tiers per repo, one PR each**
  - Acceptance: each of roset.sh, iklo, what-about, guiltty, obsidian-hivemind, wawk.js has `repo.toml` `stage` field and matches its tier's required artifacts (see required-paths table in design doc — table authoritative; file list below non-exhaustive) — shipped as separate, per-repo PRs through normal issue → worktree → PR flow, not one mass edit.
  - Verify: `repo-standard audit` (from task 2) reports clean for each repo after its PR merges.
  - Files: `repo.toml`, `AGENTS.md`, `README.md`, and stage-specific paths per required-paths table (e.g. `specs/`, `.specify/`, `specs/decisions/`, `tasks/`, `CHANGELOG.md`) in each of six repos, as applicable for that repo's declared stage.