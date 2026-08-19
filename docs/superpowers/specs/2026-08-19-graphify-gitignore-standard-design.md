# graphify as a standard dev-process artifact: `.gitignore` requirement design

## Context

The `graphify` skill (external, `~/.claude/skills/graphify`) turns any repo into a
queryable knowledge graph under `graphify-out/`. It is being adopted across all of
Rogério's repos as a standing part of the development process — Claude Code should
consult the graph before broad codebase exploration, and rebuild it after code changes.

Because `graphify-out/` mixes real outputs (the graph itself, the audit report) with
local bookkeeping (interpreter cache paths, cost tracking, incremental-update
manifests), each repo needs a `.gitignore` that draws that line consistently. Rather
than solving this once per repo, this change makes `.gitignore` — with a standard
graphify block — part of what `repo-standard` scaffolds and audits everywhere.

This repo (`rs-claude-plugins`) is the source of the `repo-standard` skill
(`skills/repo-standard/SKILL.md`), so the change lands here and ships to every repo
that installs the plugin.

## What's committed vs ignored in `graphify-out/`

| File | Committed? | Why |
|---|---|---|
| `graph.json` | Yes | The knowledge graph itself — the actual output. |
| `GRAPH_REPORT.md` | Yes | Human-readable audit report — browsable on GitHub, useful in diff review. |
| `graph.html` | No | Large self-contained visualization, no diff value, regenerate on demand (`graphify export html`). |
| `manifest.json` | No | Incremental-update bookkeeping (per-file hashes). AST-only rebuilds (`graphify update .`) from a fresh clone are cheap either way; a corpus with docs/papers/images re-running full semantic extraction (`graphify extract`) is not — a missing `manifest.json`/`cache/` means that work (and its LLM cost) redoes from scratch. |
| `cost.json` | No | Local token-cost tracking, machine-specific, not useful in history. |
| `cache/` | No | Semantic-extraction cache — see the `manifest.json` caveat above; ignoring it is still correct, just not free on re-run for non-code corpora. |
| Everything else (`wiki/`, `obsidian/`, `.graphify_*`, and any future export/bookkeeping graphify adds) | No | Not enumerated individually — see "Denylist vs allowlist" below. |

Rationale: `graph.json` and `GRAPH_REPORT.md` are the knowledge the graph exists to
produce — worth having on a fresh clone and worth tracking in history. Everything
else is either regenerable (at some cost, see above) or specific to the
machine/session that produced it, and committing it would turn every rebuild into
diff noise.

### Denylist vs allowlist

An early draft of this design enumerated each ignored file by name
(`graph.html`, `manifest.json`, `cost.json`, `cache/`, `.graphify_*`). That list
was already incomplete against graphify's actual output surface — it missed
`graphify-out/wiki/`, `graphify-out/obsidian/`, `graphify-out/needs_update`
(no leading dot), `graphify-out/.vocab.txt`, and several other export/bookkeeping
paths — and would keep drifting every time graphify adds a new export flag.
`CLAUDE.md`'s own graphify block already tells Claude to check
`graphify-out/wiki/index.md` when present, so an incomplete denylist would let a
`--wiki` run's full export tree land in git by default.

The starter content below uses an **allowlist** instead: ignore everything
under `graphify-out/`, then explicitly un-ignore only the two files that are
meant to be committed. This is robust to graphify growing new output types —
nothing new can accidentally get committed — at the cost of needing to update
the allowlist (not a denylist) if a third file ever earns commit status.

## Change to `repo-standard`

### Required-paths table

Add `.gitignore` as a new row, required at **all four stages** (`prototype`,
`in-progress`, `released`, `archived`) — same tier as `repo.toml`, `AGENTS.md`,
`README.md`. Even a prototype benefits from ignoring OS/editor cruft from day one,
and once created it persists through `archived` like the other frozen-required docs.

### Starter content

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

The graphify block is always included, even in repos that haven't run `/graphify`
yet — the goal is one standard template, not a conditional one, so nothing has to
be revisited later when a repo does adopt it.

### Audit behavior

`.gitignore` is the one required path where audit does more than check existence:
it also verifies the file contains both a line starting with `# graphify` and a
line containing `graphify-out/*` — the comment alone isn't sufficient, since a
`.gitignore` with the marker comment but no actual pattern would still (wrongly)
pass a comment-only check. A `.gitignore` that exists but lacks either is reported
as non-compliant. This is a deliberate exception to repo-standard's existing
presence-only audit pattern, justified because a missing graphify block silently
defeats the whole point of the requirement (a stray `graph.html`, `cache/`, or
future export tree getting committed).

Every other required path keeps its existing presence-only check — this is not a
general shift toward content auditing.

### Scaffold behavior

Unchanged pattern: scaffold creates `.gitignore` with the starter content above if
absent. If `.gitignore` already exists but is missing the graphify block, scaffold
does **not** auto-append (consistent with "never overwrite existing content, even
if it looks wrong" — report and move on, same as every other required path).

## Rollout in this repo

`rs-claude-plugins` adopts the new standard as part of this same change:

- New `.gitignore` at repo root, using the starter content above.
- `graphify-out/graph.json` and `graphify-out/GRAPH_REPORT.md` committed for the
  first time.
- `README.md` gains a short "Development" section pointing at `graphify query`
  as the first step for codebase questions, and documenting the commit/ignore
  split above so future contributors don't have to rediscover it.
- `CLAUDE.md` (auto-written by the `/graphify` run that produced this repo's
  graph) is committed as-is — no edits needed, but it is new to version control
  as of this change (the README's "Development" section now depends on it
  being tracked, since it points readers at `CLAUDE.md` for details).

## Out of scope

- This repo's `repo.toml` has no `stage` field set, which means `repo-standard
  audit`/`scaffold` would currently fail closed here regardless of this change.
  Fixing that is a separate, unrelated gap — not addressed by this PR.
- No git post-commit hook (`graphify hook install`) is being wired in; it's local
  machine state that a PR can't install for other clones. Manual
  `graphify update .` (already documented in `CLAUDE.md`) is the update path for
  now.
- `graph.html` is not offered as an optional-commit choice — it's unconditionally
  ignored, per the allowlist above.
- This repo's own `repo-standard` audit/scaffold path for the new `.gitignore`
  row can't be exercised end-to-end here (see the `stage` gap above), so it
  ships unverified by this repo's own tooling — verification is manual review
  of the SKILL.md/design-doc text plus `git check-ignore` against the actual
  `.gitignore` committed here.
