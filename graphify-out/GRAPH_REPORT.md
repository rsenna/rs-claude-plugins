# Graph Report - graphify-gitignore-standard  (2026-08-19)

## Corpus Check
- 28 files · ~22,859 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 85 nodes · 116 edges · 13 communities (9 shown, 4 thin omitted)
- Extraction: 96% EXTRACTED · 4% INFERRED · 0% AMBIGUOUS · INFERRED: 5 edges (avg confidence: 0.89)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `9e16cd26`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- pr.sh
- issue.sh
- marketplace.json
- Cross-repo documentation/folder standard design doc
- pull-request-process SKILL.md
- doppler-secrets SKILL.md
- obsidian-official-cli skill-card (top-level)
- Obsidian Bases Functions Reference
- opn-api.sh
- patchmon-api.sh
- graphify usage rules (project CLAUDE.md)
- opencode GitHub Action workflow
- graphify as a standard dev-process artifact: `.gitignore` requirement design

## God Nodes (most connected - your core abstractions)
1. `pr.sh script` - 11 edges
2. `issue.sh script` - 9 edges
3. `log()` - 9 edges
4. `die()` - 6 edges
5. `graphify as a standard dev-process artifact: `.gitignore` requirement design` - 6 edges
6. `cmd_push()` - 5 edges
7. `cmd_open()` - 5 edges
8. `cmd_cleanup()` - 5 edges
9. `Change to `repo-standard`` - 5 edges
10. `Cross-repo documentation/folder standard design doc` - 5 edges

## Surprising Connections (you probably didn't know these)
- `repo-standard SKILL.md` --references--> `Cross-repo documentation/folder standard design doc`  [EXTRACTED]
  skills/repo-standard/SKILL.md → docs/superpowers/specs/2026-08-01-repo-standard-design.md
- `Issue #3 task breakdown: cross-repo doc/folder standard` --references--> `Cross-repo documentation/folder standard design doc`  [EXTRACTED]
  tasks/issue-3-design-cross-repo-doc-folder-standard-repo-toml.md → docs/superpowers/specs/2026-08-01-repo-standard-design.md
- `repo-standard audit mode (read-only compliance check)` --conceptually_related_to--> `Per-stage doc/folder tier table (prototype/in-progress/released/archived)`  [EXTRACTED]
  skills/repo-standard/SKILL.md → docs/superpowers/specs/2026-08-01-repo-standard-design.md
- `repo-standard scaffold mode (non-destructive creation)` --conceptually_related_to--> `Per-stage doc/folder tier table (prototype/in-progress/released/archived)`  [EXTRACTED]
  skills/repo-standard/SKILL.md → docs/superpowers/specs/2026-08-01-repo-standard-design.md
- `Issue #3 task breakdown: cross-repo doc/folder standard` --references--> `repo-standard SKILL.md`  [EXTRACTED]
  tasks/issue-3-design-cross-repo-doc-folder-standard-repo-toml.md → skills/repo-standard/SKILL.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Shared Doppler-sourced credential injection pattern across admin skills** — skills_doppler_secrets_skill_document, skills_opnsense_admin_references_lessons_learned_document, skills_patchmon_admin_references_lessons_learned_document [EXTRACTED 1.00]
- **Issue -> tasks -> implementation -> PR skill pipeline** — readme_document, skills_map_issue_to_tasks_skill_document, skills_fix_mapped_issue_skill_document, skills_pull_request_process_skill_document [EXTRACTED 1.00]
- **repo.toml stage-tier design, enforcing skill, and rollout task** — docs_superpowers_specs_2026_08_01_repo_standard_design_document, skills_repo_standard_skill_document, tasks_issue_3_design_cross_repo_doc_folder_standard_repo_toml_document [EXTRACTED 1.00]

## Communities (13 total, 4 thin omitted)

### Community 0 - "pr.sh"
Cohesion: 0.30
Nodes (13): cmd_cleanup(), cmd_comment(), cmd_comment_delete(), cmd_open(), cmd_push(), cmd_reply(), cmd_reviews(), cmd_start() (+5 more)

### Community 1 - "issue.sh"
Cohesion: 0.42
Nodes (10): cmd_close(), cmd_comment(), cmd_fetch(), cmd_json(), cmd_label(), cmd_slug(), cmd_unmapped(), die() (+2 more)

### Community 2 - "marketplace.json"
Cohesion: 0.25
Nodes (7): description, name, owner, name, url, plugins, $schema

### Community 3 - "Cross-repo documentation/folder standard design doc"
Cohesion: 0.29
Nodes (8): Cross-repo documentation/folder standard design doc, On-demand (not pre-PR-gated) enforcement decision for repo-standard, repo.toml stage field decision, Per-stage doc/folder tier table (prototype/in-progress/released/archived), repo-standard audit mode (read-only compliance check), repo-standard SKILL.md, repo-standard scaffold mode (non-destructive creation), Issue #3 task breakdown: cross-repo doc/folder standard

### Community 4 - "pull-request-process SKILL.md"
Cohesion: 0.36
Nodes (8): rs-claude-plugins README, fix-mapped-issue SKILL.md, map-issue-to-tasks SKILL.md, issue-enrichment.md template, Dedicated agent git/gh identity enforcement (rationale), pull-request-process SKILL.md, Explicit-refspec push guardrail against advancing main (rationale), Git worktree isolation instead of shared checkout (rationale)

### Community 5 - "doppler-secrets SKILL.md"
Cohesion: 0.29
Nodes (8): doppler-secrets SKILL.md, Doppler service-token least-privilege scoping rationale, OPNsense API lessons learned, Always pull config backup before nontrivial change (rationale), opnsense-admin SKILL.md, PatchMon API lessons learned, patchmon-admin SKILL.md, patch_all is a real immediate live-host action (rationale)

### Community 6 - "obsidian-official-cli skill-card (top-level)"
Cohesion: 0.50
Nodes (4): obsidian-official-cli skill-card (top-level), obsidian-official-cli SKILL.md (top-level), obsidian-official-cli skill-card (nested duplicate), obsidian-official-cli SKILL.md (nested duplicate)

### Community 7 - "Obsidian Bases Functions Reference"
Cohesion: 1.00
Nodes (3): Obsidian Bases Functions Reference, obsidian-bases skill-card, obsidian-bases SKILL.md

### Community 12 - "graphify as a standard dev-process artifact: `.gitignore` requirement design"
Cohesion: 0.17
Nodes (11): Audit behavior, Change to `repo-standard`, Context, Denylist vs allowlist, graphify as a standard dev-process artifact: `.gitignore` requirement design, Out of scope, Required-paths table, Rollout in this repo (+3 more)

## Knowledge Gaps
- **23 isolated node(s):** `$schema`, `name`, `description`, `name`, `url` (+18 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **4 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What connects `$schema`, `name`, `description` to the rest of the system?**
  _23 weakly-connected nodes found - possible documentation gaps or missing edges._