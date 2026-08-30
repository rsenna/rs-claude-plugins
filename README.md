# rs-agent-plugin

_Personal AI agent plugin: a collection of agent-agnostic skills_.

- GitHub issue → PR workflow, factored into separate skills.
- Obsidian
- Graphify usage
- etc.

## Install

```
/plugin marketplace add rsenna/rs-agent-plugin
/plugin install rs-workflow-skills@rs-agent-plugin
```

## PR-related Skills

- **`map-issue-to-tasks`**:
  1. Analyse a GitHub issue.
  2. Enrich it against a template.
  3. And finally break it into a dependency-ordered task list (`tasks/issue-<n>-<slug>.md`).
- **`fix-mapped-issue`**:
  1. Implement the mapped tasks.
  2. Ship each through `pull-request-process`.
  3. Then close the issue once everything is merged.
- **`pull-request-process`** - the safe way to ship a change:
  1. Create local feature-branch.
  2. Run local quality gate.
  3. Push feature-branch to `origin`.
  4. Open a new PR.
  5. Stop and wait for code review (done by humans, or other agents).
  6. In case of code review issues, fix each review thread.

The `pull-request-process` skill is called by the other two skills, as a building block.

Each skill's `SKILL.md` documents its own commands and guardrails in full.

## Guardrails these skills share

- **ALWAYS use a _PR_ to send code changes**.
- **NEVER touch the `main`/`master` _branch_**.
- **NEVER _merge_ a PR or mark it ready**.
  - Instead, bots/maintainer will review and merge.
- **NEVER _resolve_ review threads**.
  - Reply, and let the maintainer resolve.
- **NEVER _push_, UNLESS the project's own quality gate is green**.
  - Make an explicit-refspec push to a feature branch instead.

## Development Remarks

### Graphify

#### Summary

This repo uses the `graphify` skill to build a queryable knowledge graph of its
own codebase: god nodes, community structure, cross-file relationships.

After code changes, run `graphify update .` (or `/graphify . --update`) to keep
the committed graph current, before it ships into a PR.

#### Queries

For codebase questions, run `graphify query "<question>"` before falling back to
raw grep or file browsing (see `CLAUDE.md`).

`graphify path "<A>" "<B>"` and `graphify explain "<concept>"` work the same way
for narrower lookups.

#### Files

`graphify-out/graph.json` and `graphify-out/GRAPH_REPORT.md` are committed: the
graph and its audit report are real outputs worth having on a fresh clone and
worth tracking in history.

Everything else under `graphify-out/` (`graph.html`, `manifest.json`,
`cost.json`, `cache/`, `.graphify_*`) is local bookkeeping and stays gitignored.
Those artifacts can be regenerated, but semantic extraction from a fresh clone
can redo non-trivial LLM work/cost.

