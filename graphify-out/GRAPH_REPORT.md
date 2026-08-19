# Graph Report - rs-claude-plugins  (2026-08-19)

## Corpus Check
- Corpus is ~20,587 words - fits in a single context window. You may not need a graph.

## Summary
- 73 nodes · 105 edges · 12 communities (8 shown, 4 thin omitted)
- Extraction: 95% EXTRACTED · 5% INFERRED · 0% AMBIGUOUS · INFERRED: 5 edges (avg confidence: 0.89)
- Token cost: 0 input · 124,145 output

## Community Hubs (Navigation)
- PR Workflow CLI (pr.sh)
- Issue Mapping CLI (issue.sh)
- Plugin Marketplace Manifest
- Repo-Standard Design & Tiers
- Workflow Skills Rationale
- Ops Admin Skills (Doppler/OPNsense/PatchMon)
- Obsidian CLI Skill (duplicated)
- Obsidian Bases Skill
- OPNsense API Script
- PatchMon API Script
- Graphify Project Rules
- OpenCode GitHub Action

## God Nodes (most connected - your core abstractions)
1. `pr.sh script` - 11 edges
2. `issue.sh script` - 9 edges
3. `log()` - 9 edges
4. `die()` - 6 edges
5. `cmd_push()` - 5 edges
6. `cmd_open()` - 5 edges
7. `cmd_cleanup()` - 5 edges
8. `Cross-repo documentation/folder standard design doc` - 5 edges
9. `pull-request-process SKILL.md` - 5 edges
10. `log()` - 4 edges

## Surprising Connections (you probably didn't know these)
- `repo-standard SKILL.md` --references--> `Cross-repo documentation/folder standard design doc`  [EXTRACTED]
  skills/repo-standard/SKILL.md → docs/superpowers/specs/2026-08-01-repo-standard-design.md
- `Issue #3 task breakdown: cross-repo doc/folder standard` --references--> `Cross-repo documentation/folder standard design doc`  [EXTRACTED]
  tasks/issue-3-design-cross-repo-doc-folder-standard-repo-toml.md → docs/superpowers/specs/2026-08-01-repo-standard-design.md
- `rs-claude-plugins README` --references--> `fix-mapped-issue SKILL.md`  [EXTRACTED]
  README.md → skills/fix-mapped-issue/SKILL.md
- `rs-claude-plugins README` --references--> `map-issue-to-tasks SKILL.md`  [EXTRACTED]
  README.md → skills/map-issue-to-tasks/SKILL.md
- `rs-claude-plugins README` --references--> `pull-request-process SKILL.md`  [EXTRACTED]
  README.md → skills/pull-request-process/SKILL.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Issue -> tasks -> implementation -> PR skill pipeline** — readme_document, skills_map_issue_to_tasks_skill_document, skills_fix_mapped_issue_skill_document, skills_pull_request_process_skill_document [EXTRACTED 1.00]
- **Shared Doppler-sourced credential injection pattern across admin skills** — skills_doppler_secrets_skill_document, skills_opnsense_admin_references_lessons_learned_document, skills_patchmon_admin_references_lessons_learned_document [EXTRACTED 1.00]
- **repo.toml stage-tier design, enforcing skill, and rollout task** — docs_superpowers_specs_2026_08_01_repo_standard_design_document, skills_repo_standard_skill_document, tasks_issue_3_design_cross_repo_doc_folder_standard_repo_toml_document [EXTRACTED 1.00]

## Communities (12 total, 4 thin omitted)

### Community 0 - "PR Workflow CLI (pr.sh)"
Cohesion: 0.30
Nodes (13): cmd_cleanup(), cmd_comment(), cmd_comment_delete(), cmd_open(), cmd_push(), cmd_reply(), cmd_reviews(), cmd_start() (+5 more)

### Community 1 - "Issue Mapping CLI (issue.sh)"
Cohesion: 0.42
Nodes (10): cmd_close(), cmd_comment(), cmd_fetch(), cmd_json(), cmd_label(), cmd_slug(), cmd_unmapped(), die() (+2 more)

### Community 2 - "Plugin Marketplace Manifest"
Cohesion: 0.25
Nodes (7): description, name, owner, name, url, plugins, $schema

### Community 3 - "Repo-Standard Design & Tiers"
Cohesion: 0.29
Nodes (8): Cross-repo documentation/folder standard design doc, On-demand (not pre-PR-gated) enforcement decision for repo-standard, repo.toml stage field decision, Per-stage doc/folder tier table (prototype/in-progress/released/archived), repo-standard audit mode (read-only compliance check), repo-standard SKILL.md, repo-standard scaffold mode (non-destructive creation), Issue #3 task breakdown: cross-repo doc/folder standard

### Community 4 - "Workflow Skills Rationale"
Cohesion: 0.36
Nodes (8): rs-claude-plugins README, fix-mapped-issue SKILL.md, map-issue-to-tasks SKILL.md, issue-enrichment.md template, Dedicated agent git/gh identity enforcement (rationale), pull-request-process SKILL.md, Explicit-refspec push guardrail against advancing main (rationale), Git worktree isolation instead of shared checkout (rationale)

### Community 5 - "Ops Admin Skills (Doppler/OPNsense/PatchMon)"
Cohesion: 0.29
Nodes (8): doppler-secrets SKILL.md, Doppler service-token least-privilege scoping rationale, OPNsense API lessons learned, Always pull config backup before nontrivial change (rationale), opnsense-admin SKILL.md, PatchMon API lessons learned, patchmon-admin SKILL.md, patch_all is a real immediate live-host action (rationale)

### Community 6 - "Obsidian CLI Skill (duplicated)"
Cohesion: 0.50
Nodes (4): obsidian-official-cli skill-card (top-level), obsidian-official-cli SKILL.md (top-level), obsidian-official-cli skill-card (nested duplicate), obsidian-official-cli SKILL.md (nested duplicate)

### Community 7 - "Obsidian Bases Skill"
Cohesion: 1.00
Nodes (3): Obsidian Bases Functions Reference, obsidian-bases skill-card, obsidian-bases SKILL.md

## Knowledge Gaps
- **15 isolated node(s):** `$schema`, `name`, `description`, `name`, `url` (+10 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **4 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What connects `$schema`, `name`, `description` to the rest of the system?**
  _15 weakly-connected nodes found - possible documentation gaps or missing edges._