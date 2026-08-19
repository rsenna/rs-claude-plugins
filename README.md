# rs-claude-plugins

Personal Claude Code plugin: a GitHub issue → PR workflow, factored into three skills.

## Install

```
/plugin marketplace add rsenna/rs-claude-plugins
/plugin install rs-workflow-skills@rs-claude-plugins
```

## Skills

- **`map-issue-to-tasks`** — analyse a GitHub issue, enrich it against a template, and break it into a dependency-ordered task list (`tasks/issue-<n>-<slug>.md`).
- **`fix-mapped-issue`** — implement the mapped tasks, ship each through `pull-request-process`, then close the issue once everything is merged.
- **`pull-request-process`** — the safe way to ship a change: branch → quality gate → push (never touching `main`) → open a PR → stop (never merge) → work each review thread. The other two skills call this one as a building block.

Each skill's `SKILL.md` documents its own commands and guardrails in full.

## Guardrails these skills share

- Never merge a PR or mark it ready — bots/maintainer review and merge.
- Never resolve review threads — reply, and let the maintainer resolve.
- Never push unless the project's own quality gate is green.
- Never push straight to the base branch — always an explicit-refspec push to a feature branch.

## Development

This repo uses the `graphify` skill to build a queryable knowledge graph of its
own codebase — god nodes, community structure, cross-file relationships. For
codebase questions, run
`graphify query "<question>"` before falling back to raw grep or file browsing
(see `CLAUDE.md`); `graphify path "<A>" "<B>"` and `graphify explain "<concept>"`
work the same way for narrower lookups.

`graphify-out/graph.json` and `graphify-out/GRAPH_REPORT.md` are committed — the
graph and its audit report are real outputs worth having on a fresh clone and
worth tracking in history. Everything else under `graphify-out/` (`graph.html`,
`manifest.json`, `cost.json`, `cache/`, `.graphify_*`) is local bookkeeping or
regenerable in seconds, and stays gitignored. After code changes, run
`graphify update .` (or `/graphify . --update`) to keep the committed graph
current before it ships in a PR.
