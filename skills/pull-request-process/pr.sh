#!/usr/bin/env bash
# pr.sh — safe git/gh plumbing for the pull-request-process skill.
#
# Language-agnostic: it does NOT run any project quality gate. Run the gate
# yourself (per the project's AGENTS.md/CLAUDE.md) BEFORE `pr.sh push`.
#
# Subcommands:
#   start <branch>        create <branch> in a FRESH git worktree off up-to-date origin/BASE
#                         (a sibling directory next to the repo, never the shared checkout)
#                         and print its path — cd there for every remaining step.
#   push <branch>         explicit-refspec push + verify branch landed & BASE didn't move
#   open <title> [body]   gh pr create --base BASE (body = path to a markdown file), print URL, STOP
#   threads <pr>          list UNRESOLVED review threads on a PR (work them one by one)
#   reviews <pr>           list PR-LEVEL review comments (the "Overall Comments" a bot leaves on
#                          the review itself, not on a line — these have no thread and can't be
#                          replied to with `reply`). Pulls out each bot's "Prompt for AI Agent(s)"
#                          block when present, since that's the actionable part.
#   reply <pr> <id> <body> reply to a review thread comment (body = inline string or path to a markdown file)
#   cleanup               once a task is FULLY done (PR merged or abandoned — not right after
#                         opening; the review loop still needs this worktree): verify it's
#                         pristine, remove it, and print the main checkout's path to cd back
#                         into. Only ever removes a worktree under the exact <repo>-worktrees
#                         root `start` creates. NON-DESTRUCTIVE — if dirty (including gitignored
#                         files the removal would otherwise silently take with it) it reports
#                         and stops (never discards).
#
# Env:
#   BASE                  base branch (default: main). The skill supplies this from the project's docs.
#   DRAFT                 set DRAFT=1 to open the PR as a draft (bots typically don't review drafts).
#   DRY_RUN               set DRY_RUN=1 so `open` prints the gh command instead of creating the PR.
#   FORCE_REMOVE_IGNORED  set to 1 to let `cleanup` remove a worktree that still has gitignored
#                         files in it (otherwise it refuses, since removal deletes the whole
#                         directory — build artifacts are fine to lose, a stray .env isn't).
set -euo pipefail

BASE="${BASE:-main}"
log()  { printf '\033[1;34m[pr]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[pr] %s\033[0m\n' "$*" >&2; }
die()  { printf '\033[1;31m[pr] %s\033[0m\n' "$*" >&2; exit 1; }

remote_sha() { git ls-remote --heads origin "$1" 2>/dev/null | awk '{print $1}'; }

# Resolves the TRUE main checkout's root, regardless of which worktree (if any)
# we're currently invoked from. The common git dir is shared across every
# worktree of a repo and always resolves to <main-checkout>/.git in a standard
# (non-bare) setup — unlike scanning `git worktree list` for a worktree with a
# particular branch checked out, this doesn't break the moment nothing has
# $BASE checked out (e.g. the shared checkout is on some other branch).
main_checkout_root() {
  local common_dir
  common_dir="$(git rev-parse --git-common-dir)"
  common_dir="$(cd "$common_dir" && pwd)" # normalize to an absolute path
  dirname "$common_dir"
}

cmd_start() {
  local br="${1:?usage: pr.sh start <branch>}"
  git rev-parse --git-dir >/dev/null 2>&1 || die "not a git repo"
  git show-ref --verify --quiet "refs/heads/$br" && die "branch '$br' already exists locally"
  log "fetching origin/$BASE"; git fetch origin "$BASE"
  local main_root wt_root wt_path
  main_root="$(main_checkout_root)"
  wt_root="${main_root}-worktrees"
  wt_path="$wt_root/$br"
  [ -e "$wt_path" ] && die "worktree path '$wt_path' already exists"
  mkdir -p "$(dirname "$wt_path")"
  # --no-track: branch off origin/$BASE's tip WITHOUT setting up tracking against it.
  # Without this, `branch.autoSetupMerge` (on by default) would make the new branch
  # track origin/$BASE since the start point is a remote-tracking ref — then a bare
  # `git push` (push.default=upstream) would write straight to origin/$BASE, bypassing
  # the whole PR/review flow. This is also why we never touch the shared checkout's
  # own local $BASE branch here: a fresh worktree branching straight off origin/$BASE
  # needs no local $BASE ref update at all, and can't collide with whatever the shared
  # checkout (or another worktree) currently has checked out or uncommitted.
  git worktree add --no-track -b "$br" "$wt_path" "origin/$BASE" >/dev/null
  log "worktree created at '$wt_path' on new branch '$br' (off up-to-date origin/$BASE)."
  log "cd into it now — every remaining step (implement, gate, push, open, review loop) runs from there:"
  log "  cd '$wt_path'"
}

cmd_push() {
  local br="${1:?usage: pr.sh push <branch>}"
  [ "$(git rev-parse --abbrev-ref HEAD)" = "$br" ] || warn "HEAD is not '$br' (pushing HEAD anyway)"
  local base_before; base_before="$(remote_sha "$BASE")"
  log "pushing HEAD -> origin/$br (explicit refspec)"
  git push origin "HEAD:refs/heads/$br"
  # Verify: branch exists on remote, and BASE did NOT advance (the accident this guards against).
  [ -n "$(remote_sha "$br")" ] || die "branch '$br' not found on origin after push"
  local base_after; base_after="$(remote_sha "$BASE")"
  if [ "$base_before" != "$base_after" ]; then
    die "origin/$BASE moved during push ($base_before -> $base_after) — investigate immediately"
  fi
  log "ok: origin/$br updated; origin/$BASE unchanged ($base_after)"
}

cmd_open() {
  local title="${1:?usage: pr.sh open <title> [body-file]}"; local body="${2:-}"
  local br; br="$(git rev-parse --abbrev-ref HEAD)"
  local args=(pr create --base "$BASE" --head "$br" --title "$title")
  [ "${DRAFT:-0}" = "1" ] && args+=(--draft)
  if [ -n "$body" ]; then [ -f "$body" ] || die "body file not found: $body"; args+=(--body-file "$body"); else args+=(--body ""); fi
  if [ "${DRY_RUN:-0}" = "1" ]; then log "DRY_RUN — would run: gh ${args[*]}"; return 0; fi
  log "gh ${args[*]}"
  local url; url="$(gh "${args[@]}")"
  log "PR opened: $url"
  warn "STOP: do not merge or mark ready — bots/maintainer review and merge."
}

cmd_reply() {
  local pr="${1:?usage: pr.sh reply <pr-number> <comment-id> <body>}"
  local comment_id="${2:?usage: pr.sh reply <pr-number> <comment-id> <body>}"
  local body="${3:?usage: pr.sh reply <pr-number> <comment-id> <body>}"
  local nwo owner repo; nwo="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
  owner="${nwo%%/*}"; repo="${nwo##*/}"
  # Accept body as a file path or inline string.
  local body_arg
  if [ -f "$body" ]; then
    body_arg="$(cat "$body")"
  else
    body_arg="$body"
  fi
  local url
  url="$(gh api "repos/$owner/$repo/pulls/$pr/comments/$comment_id/replies" \
    -f body="$body_arg" | jq -r '.html_url')"
  log "reply posted: $url"
}

cmd_threads() {
  local pr="${1:?usage: pr.sh threads <pr-number>}"
  local nwo owner repo; nwo="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
  owner="${nwo%%/*}"; repo="${nwo##*/}"
  gh api graphql -F owner="$owner" -F repo="$repo" -F pr="$pr" -f query='
    query($owner:String!,$repo:String!,$pr:Int!){
      repository(owner:$owner,name:$repo){
        pullRequest(number:$pr){
          reviewThreads(first:100){ nodes{
            isResolved isOutdated path line
            comments(first:1){ nodes{ databaseId author{login} body } }
          } }
        }
      }
    }' --jq '
      .data.repository.pullRequest.reviewThreads.nodes
      | map(select(.isResolved==false))
      | if length==0 then "No unresolved review threads."
        else (.[] | "── \(.path):\(.line // "?") \(if .isOutdated then "(outdated)" else "" end)\n   reply with: pr.sh reply '"$pr"' \(.comments.nodes[0].databaseId) \"<body>\"\n@\(.comments.nodes[0].author.login // "?"): \(.comments.nodes[0].body // "" | gsub("\n";" ") | .[0:280])")
        end'
}

cmd_reviews() {
  local pr="${1:?usage: pr.sh reviews <pr-number>}"
  local nwo owner repo; nwo="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
  owner="${nwo%%/*}"; repo="${nwo##*/}"
  local reviews_json
  reviews_json="$(gh api "repos/$owner/$repo/pulls/$pr/reviews" --paginate)"
  local count
  count="$(jq '[.[] | select((.body // "") != "")] | length' <<<"$reviews_json")"
  if [ "$count" = "0" ]; then
    log "no PR-level review comments with a body."
    return 0
  fi
  jq -c '.[] | select((.body // "") != "")' <<<"$reviews_json" | while IFS= read -r review; do
    local login state id body prompt
    login="$(jq -r '.user.login' <<<"$review")"
    state="$(jq -r '.state' <<<"$review")"
    id="$(jq -r '.id' <<<"$review")"
    body="$(jq -r '.body' <<<"$review")"
    echo "── $login [$state] (review $id)"
    # Extract the fenced block following any "Prompt for AI Agent(s)" mention. Bots vary fence
    # style (~~~markdown vs ```text) and casing, so match generically on both.
    prompt="$(awk '
      BEGIN{seen=0; infence=0}
      { line=$0; ltmp=tolower(line); if (ltmp ~ /prompt for ai agent/) { seen=1 } }
      seen && !infence && (line ~ /^(```+|~~~+)/) { infence=1; next }
      infence && (line ~ /^(```+|~~~+)[ \t]*$/) { infence=0; exit }
      infence { print }
    ' <<<"$body")"
    if [ -n "$prompt" ]; then
      echo "  prompt:"
      echo "$prompt" | sed 's/^/    /'
    else
      echo "  $(echo "$body" | tr '\n' ' ' | cut -c1-280)"
    fi
    echo
  done
}

cmd_cleanup() {
  git rev-parse --git-dir >/dev/null 2>&1 || die "not a git repo"
  # git status ignores gitignored build artifacts, so a non-empty result is real
  # uncommitted/untracked work — surface it and STOP rather than discard anything.
  if [ -n "$(git status --porcelain)" ]; then
    warn "worktree NOT pristine — leaving '$(pwd)' (branch '$(git rev-parse --abbrev-ref HEAD)') as-is."
    warn "resolve these (commit, stash, or remove) then re-run 'pr.sh cleanup':"
    git status --short >&2
    return 1
  fi
  log "worktree pristine"
  local wt_path main_root wt_root
  wt_path="$(git rev-parse --show-toplevel)"
  main_root="$(main_checkout_root)"
  wt_root="${main_root}-worktrees"
  [ "$wt_path" != "$main_root" ] || die "refusing to remove '$wt_path' — it IS the main checkout, not a task worktree"
  # Only ever remove worktrees under the exact root `pr.sh start` creates —
  # never an unrelated worktree someone else made for something else, even if
  # it happens to be pristine and even if it's linked to this same repo.
  case "$wt_path" in
    "$wt_root"/*) ;;
    *) die "refusing to remove '$wt_path' — it's not under '$wt_root', so 'pr.sh start' didn't create it; if you're sure, remove it manually with 'git worktree remove'" ;;
  esac
  # `git worktree remove` deletes the WHOLE directory, including anything
  # gitignored — unlike the old git-switch-in-place cleanup, which left
  # ignored files sitting on disk untouched. A build-artifact directory
  # (target/, node_modules/) disappearing is fine; a stray .env or local DB
  # someone stashed there is not. Refuse by default if any ignored path is
  # present; FORCE_REMOVE_IGNORED=1 opts in explicitly.
  local ignored
  ignored="$(git status --porcelain --ignored=matching | sed -n 's/^!! //p')"
  if [ -n "$ignored" ] && [ "${FORCE_REMOVE_IGNORED:-0}" != "1" ]; then
    warn "worktree has gitignored files 'git worktree remove' would delete along with the directory:"
    echo "$ignored" | sed 's/^/  /' >&2
    warn "if these are disposable build artifacts, re-run with FORCE_REMOVE_IGNORED=1 to remove anyway."
    warn "if not, move/copy anything you need out first."
    return 1
  fi
  # Point --git-dir directly at the shared git directory rather than running
  # `git -C <some-other-worktree>` — this works with no OTHER worktree needing
  # to exist in any particular state (in particular, no worktree needs $BASE
  # checked out), and still works even though the invoking shell's cwd is
  # literally inside the directory being removed.
  local common_dir; common_dir="$(cd "$(git rev-parse --git-common-dir)" && pwd)"
  git --git-dir="$common_dir" worktree remove "$wt_path" \
    || die "could not auto-remove worktree at '$wt_path' — remove manually: git --git-dir='$common_dir' worktree remove '$wt_path'"
  # Slash-named branches (e.g. feat/my-thing) leave a now-empty parent dir behind under
  # <repo>-worktrees/ — prune upward while empty, stopping at the worktrees root itself.
  local parent; parent="$(dirname "$wt_path")"
  while [ "$parent" != "$wt_root" ] && [ -d "$parent" ] && [ -z "$(ls -A "$parent" 2>/dev/null)" ]; do
    rmdir "$parent"
    parent="$(dirname "$parent")"
  done
  log "worktree removed. cd back into the main checkout for the next task:"
  log "  cd '$main_root'"
}

case "${1:-}" in
  start)   shift; cmd_start "$@" ;;
  push)    shift; cmd_push "$@" ;;
  open)    shift; cmd_open "$@" ;;
  threads) shift; cmd_threads "$@" ;;
  reviews) shift; cmd_reviews "$@" ;;
  reply)   shift; cmd_reply "$@" ;;
  cleanup) shift; cmd_cleanup "$@" ;;
  *) die "usage: pr.sh {start|push|open|threads|reviews|reply|cleanup} ...  (BASE=$BASE)" ;;
esac
