---
name: repo-standard
description: Audit or scaffold a repo's documentation/folder layout against its declared repo.toml stage tier. Use when asked to audit, check, scaffold, or bring a repo up to standard. Triggered on demand only — not a pre-PR gate.
---

# repo-standard

Checks (or creates) the documentation and folder artifacts required for a repo's declared `stage` tier, as defined in the [cross-repo standard design doc](../../docs/superpowers/specs/2026-08-01-repo-standard-design.md).

Two modes — **`audit`** (read-only) and **`scaffold`** (non-destructive write).

Both fail closed if `repo.toml` is absent or `stage` is missing/invalid.

## Prerequisites

- You must be inside a git repo with a `repo.toml` that has a valid `stage` field. **Both `audit` and `scaffold` fail closed** — they stop with a clear error if `repo.toml` is absent or `stage` is missing or not one of the four valid values. No default is inferred.
- Valid `stage` values: `prototype`, `in-progress`, `released`, `archived`.
- `scaffold` never overwrites existing content — only creates what is absent.

## Workflow

### `audit` — read-only compliance check

1. **Verify bootstrap:** confirm `repo.toml` exists and `stage` is a valid value. If not, stop with a clear error — do not infer a default.
2. **Read the stage** from `repo.toml`.
3. **Diff against the required-paths table** (see below). For each required path: check whether it exists. For `repo.toml` itself, also confirm the `stage=` line is present and valid. For `.gitignore`, existence isn't enough — also confirm it contains both a line starting with `# graphify` and a line containing `graphify-out/*` (see starter content below; the comment alone isn't sufficient, since a bare comment with no pattern would still pass a naive check and defeat the point of the requirement). This is the one required path with a content check, everywhere else stays presence-only.
4. **Report** missing required paths, note optional paths that are absent (for information only), and confirm what is already present. Output is human-readable; no files are created or modified.

### `scaffold` — non-destructive creation

1. Run the full `audit` check first. Same bootstrap rules apply — fail closed on missing/invalid `stage`.
2. For each **missing required** path, offer to create it with minimal starter content (see starters below). **Never overwrite** a path that already exists, even if its content looks wrong — report it and move on.
3. After creating files, print a summary of what was created vs what was skipped (already existed).

## Required paths by stage (authoritative)

This table is the single source of truth. `audit` reports anything in the "required" column that is absent. `scaffold` creates it.

| Path | `prototype` | `in-progress` | `released` | `archived` |
|---|---|---|---|---|
| `repo.toml` (with `stage=`) | required | required | required | required |
| `.gitignore` (with `# graphify` block) | required | required | required | required |
| `AGENTS.md` | required | required | required | required (frozen) |
| `README.md` | required | required | required | required (frozen) |
| `SPEC.md` | required | — | — | — |
| `specs/` | — | required | required | — |
| `specs/decisions/` | — | required | required | — |
| `.specify/` (full spec-kit) | — | required | required | — |
| `.specify/memory/constitution.md` | — | required | required | — |
| `tasks/` | — | required | required | — |
| `CHANGELOG.md` | — | *(optional)* | required | — |
| `SECURITY.md` | — | *(optional)* | *(optional)* | — |

**`archived` notes:**
- `AGENTS.md` and `README.md` are marked `required (frozen)` — audit checks they exist; scaffold does **not** create them (they should already exist from a prior stage). If they are somehow absent, that is reported but not auto-fixed.
- All spec/tasks/changelog artifacts are not required and not scaffolded.

## Starter content for `scaffold`

When creating a missing required file, use the minimal content below. Most starters include a `# TODO` marker so the maintainer knows what to fill in — `.gitignore` is the exception, since there's nothing project-specific to fill in.

> **Note:** `repo.toml` is never created by scaffold — both modes require it to already exist with a valid `stage`. If it is absent, stop and tell the user to create it manually first.

### `.gitignore`
Same graphify block in every repo, regardless of whether `/graphify` has been run yet — the goal is one standard template, not a conditional one. If `.gitignore` already exists but is missing the graphify block, scaffold does **not** auto-append (never overwrite existing content, even if it looks incomplete) — it reports the gap and moves on, same as any other required path.
```gitignore
# OS / editor
.DS_Store
*.swp

# graphify (knowledge graph) — allowlist: commit only graph.json + GRAPH_REPORT.md,
# ignore everything else graphify-out/ produces (exports, caches, bookkeeping)
graphify-out/*
!graphify-out/graph.json
!graphify-out/GRAPH_REPORT.md
```

### `AGENTS.md`

Use the **prototype style** for `stage = prototype`; use the **in-progress / released style** for `stage = in-progress` or `stage = released`. (`archived` repos are not scaffolded.)

#### prototype style
```markdown
# AGENTS.md

## Rules
<!-- TODO: key constraints for this repo (naming, architecture, non-goals) -->

## Setup
<!-- TODO: how to get the repo running locally -->

## Validation
<!-- TODO: the quality gate command (tests, linter, formatter) -->
```

#### in-progress / released style
```markdown
# AGENTS.md

## What's implemented
<!-- TODO: honest map of what works vs what's aspirational -->

## Rules & decisions
<!-- TODO: decided conventions, architecture rules, non-goals -->

## Dev commands
<!-- TODO: build, test, lint, run -->

## Where things live
<!-- TODO: module map — what's in which directory -->
```

### `README.md`
```markdown
# <repo name>

<!-- TODO: one-line description -->

## Status
<!-- TODO: current status, known limitations, next steps -->
```

### `SPEC.md` (prototype only)
```markdown
# Spec

<!-- TODO: what this thing is meant to do; key decisions; what it is NOT -->
```

### `specs/` and `specs/decisions/`
Create as empty directories (add a `.gitkeep` if needed).

### `.specify/` and `.specify/memory/constitution.md`
`.specify/` should be bootstrapped from iklo's reference implementation — do **not** create a hand-rolled imitation. The reference is in the `iklo` repo (sibling of the target repo under `~/REPO/ME/` by default — adjust the path to match your local layout). Copy the full `.specify/` tree from that reference and adapt only the project-specific references in `constitution.md`.

```markdown
# Constitution — <repo name>

<!-- TODO: governing principles, constraints, and architectural decisions for this project -->
<!-- Reference: copied from iklo/.specify/memory/constitution.md structure -->
```

### `tasks/`
Create as an empty directory (add a `.gitkeep` if the repo won't have any tasks yet).

### `CHANGELOG.md`
```markdown
# Changelog

All notable changes to this project will be documented here.

<!-- TODO: follow Keep a Changelog format (https://keepachangelog.com) -->
```

## Invocation

This skill is a **GitHub Copilot CLI slash command** — invoke it by typing `/repo-standard` in the Copilot CLI chat, followed by the mode:

```
/repo-standard audit      # read-only compliance check
/repo-standard scaffold   # non-destructive creation of missing artifacts
```

Run from inside the target repo's directory (so the skill can find `repo.toml` and check paths relative to the repo root).

## Example session

```
# Audit a repo
cd ~/REPO/ME/roset.sh
/repo-standard audit

# Output example:
# stage: prototype
# ✓  repo.toml (stage=prototype)
# ✓  AGENTS.md
# ✓  README.md
# ✗  SPEC.md  [MISSING — required for prototype]
# audit complete: 1 required artifact missing

# Scaffold the missing piece
/repo-standard scaffold
# → Creates SPEC.md with starter content
# → Prints: created SPEC.md
```

## Guardrails

- Never infer a default stage — fail closed if `repo.toml` or `stage` is absent/invalid.
- Never overwrite existing files in scaffold mode.
- Never run as an automatic pre-PR check — on-demand only.
- `.gitignore` is audited by content (a `# graphify`-prefixed line plus a `graphify-out/*` pattern), not just presence — this is a deliberate, singular exception; every other required path stays presence-only.
- For `.specify/`: always bootstrap from iklo's reference, never hand-roll.
- For `archived` repos: audit reports that the repo is archived and skips all non-required checks; scaffold does nothing (archived repos are frozen).
