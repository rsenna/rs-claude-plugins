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
