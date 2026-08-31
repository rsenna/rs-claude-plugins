# graphify as a standard dev-process artifact: `.gitignore` requirement design

## Context

The `graphify` skill (external, `$HOME/.agents/skills/graphify`) turns any repo into
a queryable knowledge graph under `graphify-out/`. It is being adopted across all of
Roger's repos as a standing part of the development process — agents should consult
the graph before broad codebase exploration, and rebuild it after code changes.

Because `graphify-out/` mixes real outputs (the graph itself, the audit report) with
local bookkeeping (interpreter cache paths, cost tracking, incremental-update
manifests), each repo needs a `.gitignore` that draws that line consistently. Rather
than solving this once per repo, this change makes `.gitignore` — with a standard
graphify block — part of what `repo-standard` scaffolds and audits everywhere.

This repo (`rs-agent-plugin`) is the source of the `repo-standard` skill
(`skills/repo-standard/SKILL.md`), so the change lands here and ships to every repo
that installs the plugin.

## What's committed vs ignored in `graphify-out/`

| File | Committed? | Why |
|---|---|---|
| `.graphify_python`, `.graphify_root`, `.graphify_labels.json`, other `.graphify_*` | No | Session/bookkeeping state; labels are already baked into the committed `graph.json`. |
| `cache/` | No | Semantic-extraction cache — see the `manifest.json` caveat; ignoring it is still correct, just not free on re-run for non-code corpora. |
| `cost.json` | No | Local token-cost tracking, machine-specific, not useful in history. |
| `graph.html` | No | Large self-contained visualization, no diff value, regenerate on demand (`graphify export html`). |
| `graph.json` | Yes | The knowledge graph itself — the actual output. |
| `GRAPH_REPORT.md` | Yes | Human-readable audit report — browsable on GitHub, useful in diff review. |
| `manifest.json` | No | Incremental-update bookkeeping (per-file hashes). AST-only rebuilds (`graphify update .`) from a fresh clone are cheap either way; a corpus with docs/papers/images re-running full semantic extraction (`graphify extract`) is not — a missing `manifest.json`/`cache/` means that work (and its LLM cost) redoes from scratch. |
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
`AGENTS.md`'s own graphify block already tells agents to check
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

`.gitignore` is the one required path where audit does more than check existence.

An earlier draft of this design checked for the presence of a `# graphify`
comment plus a `graphify-out/*` pattern via text matching. Review on the PR
that shipped this design (both `sourcery-ai` and `copilot-pull-request-reviewer`
independently) caught that text matching can't actually confirm the allowlist
*works*: the deny-all pattern could be present with one or both `!` negations
missing (silently blocking `graph.json`/`GRAPH_REPORT.md` from ever being
committed while still "looking" compliant), a pattern could be commented out,
or a later unrelated rule elsewhere in the file could override the allowlist
— none of which a substring check would catch, and a comment-wording or
whitespace tweak could just as easily produce a false negative on an otherwise
correct file.

The fix: audit is **behavioral**, not textual. From the repo root, run
`git check-ignore --no-index -q <path>` against five representative paths and
read the exit code (`0` = ignored, `1` = not ignored; `-q` suppresses output,
so the two "not ignored" paths print nothing either way and the exit code is
the only signal):

| Path | Expected exit code | Meaning |
|---|---|---|
| `graphify-out/graph.html` | `0` | ignored |
| `graphify-out/some-bookkeeping-file` | `0` | ignored |
| `graphify-out/wiki/index.md` | `0` | ignored (nested export tree) |
| `graphify-out/graph.json` | `1` | not ignored |
| `graphify-out/GRAPH_REPORT.md` | `1` | not ignored |

**`--no-index` is not optional.** A first pass at this fix (caught in the same
review round) ran plain `git check-ignore` and verified it manually — but only
against a scratch repo where nothing was committed yet. In every real target
repo, `graph.json`/`GRAPH_REPORT.md` *are* committed by design, and without
`--no-index`, `git check-ignore` answers "not ignored" for any tracked path
regardless of `.gitignore` content — silently reducing the two positive probes
to a no-op in exactly the repos this standard is meant to protect.
`--no-index` forces git to evaluate the ignore rules directly instead of
consulting the index. Confirmed by reproducing the bots' exact scenario
(negations deleted from an already-committed repo): without `--no-index` all
five probes falsely reported compliant; with it, the broken allowlist was
correctly caught.

The fifth probe (`wiki/index.md`) closes a second gap the first four paths
didn't cover: all four original probes are flat files directly under
`graphify-out/`, so a pattern set that only matches flat files (e.g.
`graphify-out/*.html` plus a literal filename, instead of the real
`graphify-out/*` deny-all) would pass all four while leaving an entire nested
export tree — including the `graphify-out/wiki/index.md` file `AGENTS.md`
tells agents to read — committable.

Exit code `128` (not a git repo, unsupported flag, git version too old) is an
audit error, not a verdict — report it as "audit could not run," never treat
a non-zero, non-`1` code as "not ignored."

If any of the five doesn't match its expected verdict, `.gitignore` is
reported non-compliant, even though the file exists. This catches the
text-matching failure modes above by asking the same question audit
ultimately cares about — would `git add -A` actually pick up the two
committed files and skip everything else — instead of a text proxy for it.
The five paths are representative, not exhaustive; extend the table if
`graphify-out/`'s output layout grows a new top-level shape worth probing.
Non-git repos: report the `.gitignore` row as not applicable.

Every other required path keeps its existing presence-only check — this is not a
general shift toward content auditing.

### Scaffold behavior

Unchanged pattern: scaffold creates `.gitignore` with the starter content above if
absent. If `.gitignore` already exists but is missing the graphify block, scaffold
does **not** auto-append (consistent with "never overwrite existing content, even
if it looks wrong" — report and move on, same as every other required path).

## Rollout in this repo

`rs-agent-plugin` adopts the new standard as part of this same change:

- New `.gitignore` at repo root, using the starter content above.
- `graphify-out/graph.json` and `graphify-out/GRAPH_REPORT.md` committed for the
  first time.
- `README.md` gains a short "Development" section pointing at `graphify query`
  as the first step for codebase questions, and documenting the commit/ignore
  split above so future contributors don't have to rediscover it.
- `AGENTS.md` (auto-written by the `/graphify` run that produced this repo's
  graph) is committed as-is — no edits needed, but it is new to version control
  as of this change (the README's "Development" section now depends on it
  being tracked, since it points readers at `AGENTS.md` for details).

## Out of scope

- This repo's `repo.toml` has no `stage` field set, which means `repo-standard
  audit`/`scaffold` would currently fail closed here regardless of this change.
  Fixing that is a separate, unrelated gap — not addressed by this PR.
- No git post-commit hook (`graphify hook install`) is being wired in; it's local
  machine state that a PR can't install for other clones. Manual
  `graphify update .` (already documented in `AGENTS.md`) is the update path for
  now.
- `graph.html` is not offered as an optional-commit choice — it's unconditionally
  ignored, per the allowlist above.
- This repo's own `repo-standard` audit/scaffold path for the new `.gitignore`
  row can't be exercised end-to-end here (see the `stage` gap above), so it
  ships unverified by this repo's own tooling — verification is manual review
  of the SKILL.md/design-doc text plus `git check-ignore` against the actual
  `.gitignore` committed here.
