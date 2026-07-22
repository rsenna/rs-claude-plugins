---
name: map-issue-to-tasks
description: Turn a GitHub issue into an enriched analysis plus a concrete task breakdown. Use when asked to map/analyse/enrich/scope a GitHub issue, break an issue into tasks, or plan the work for an issue before implementing. Posts the enrichment as a non-destructive issue comment, labels the issue "mapped", and writes tasks to tasks/issue-<n>-<slug>.md.
---

# Map Issue → Tasks

Steps 1–3 of the issue lifecycle: **analyse an open issue, enrich it against a
template, and break it into a dependency-ordered task list.** Implementation is
a separate skill (`fix-mapped-issue`).

Plumbing is in **`issue.sh`**, at `${CLAUDE_PLUGIN_ROOT}/skills/map-issue-to-tasks/issue.sh`.
The enrichment template is `${CLAUDE_PLUGIN_ROOT}/skills/map-issue-to-tasks/templates/issue-enrichment.md`.

## Do this

1. **Fetch.** `issue.sh fetch <n>` — read title, body, labels, and existing
   comments. Note related/duplicate issues. If it's already labeled `mapped`,
   say so and confirm before redoing the work.
2. **Explore the codebase** for the modules/files this touches. Use the
   project's own affordances (e.g. `what-about` has a `run-what-about` skill and
   a `tasks/` convention). Cite concrete file paths.
3. **Enrich.** Fill the template (copy it, replace the `<!-- … -->` guidance):
   Analysis, Context & affected areas, Acceptance criteria, Non-goals, Open
   questions, Task breakdown. Write it to a scratch file.
4. **Derive tasks.** Run the `spec-driven-development` and
   `planning-and-task-breakdown` skills to turn the acceptance criteria into
   small, verifiable, dependency-ordered tasks. Render them in **the project's
   task format** — match an existing example if the repo has one (e.g.
   `what-about`'s `tasks/todo.md`: `**ID — Title** 🔒gate`, then `Acceptance:` /
   `Verify:` / `Files:`, where **`Verify:` always includes the project's quality
   gate**; add dependency/milestone notes à la `tasks/plan.md`). If the repo has
   no `tasks/` convention, create `tasks/issue-<n>-<slug>.md` with that shape.
5. **Write outputs (non-destructive):**
   - Tasks → **`tasks/issue-<n>-<slug>.md`** (`issue.sh slug <n>` gives the
     `<n>-<slug>` stem). Never overwrite an unrelated existing task file.
   - Enrichment → a **GitHub issue comment** via `issue.sh comment <n> <file>`.
     The original issue body is **left untouched**.
6. **Label it.** `issue.sh label <n>` — tags the issue `mapped` (creating the
   label on first use). This is what lets `issue.sh unmapped` distinguish
   issues still needing this treatment from ones already scoped. Do this last,
   after the enrichment comment has actually posted.

## Review before posting

Default to **`DRY_RUN=1`** first — it prints the comment (and the label action)
instead of posting, so you (and the user) can check it. Post for real only once
it reads well.

```bash
I=${CLAUDE_PLUGIN_ROOT}/skills/map-issue-to-tasks/issue.sh
"$I" unmapped                          # which open issues still need mapping
"$I" fetch 24                          # read the issue
"$I" slug  24                          # -> 24-show-a-notification-when-a-profile-is-re-published
DRY_RUN=1 "$I" comment 24 enrich.md    # preview the enrichment comment
"$I" comment 24 enrich.md              # post it for real
"$I" label 24                          # tag it mapped
```

## Boundaries

- Do not edit the issue body, do not close the issue, do not start implementing
  — that's `fix-mapped-issue`.
- Flag 🔒 ask-first gates in the tasks (new deps, DB migrations, CI/secret
  changes) so implementation pauses for approval.
- Keep each task small enough to ship as its own PR (one concern).
