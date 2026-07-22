#!/usr/bin/env bash
# pr.sh — safe git/gh plumbing for the pull-request-process skill.
#
# Language-agnostic: it does NOT run any project quality gate. Run the gate
# yourself (per the project's AGENTS.md/CLAUDE.md) BEFORE `pr.sh push`.
#
# Subcommands:
#   start <branch>        create <branch> off an up-to-date local BASE, the safe way
#   push <branch>         explicit-refspec push + verify branch landed & BASE didn't move
#   open <title> [body]   gh pr create --base BASE (body = path to a markdown file), print URL, STOP
#   threads <pr>          list UNRESOLVED review threads on a PR (work them one by one)
#   reviews <pr>           list PR-LEVEL review comments (the "Overall Comments" a bot leaves on
#                          the review itself, not on a line — these have no thread and can't be
#                          replied to with `reply`). Pulls out each bot's "Prompt for AI Agent(s)"
#                          block when present, since that's the actionable part.
#   reply <pr> <id> <body> reply to a review thread comment (body = inline string or path to a markdown file)
#   cleanup               after a PR: verify the worktree is pristine, then switch to BASE.
#                         NON-DESTRUCTIVE — if dirty, it reports and stops (never discards).
#
# Env:
#   BASE     base branch (default: main). The skill supplies this from the project's docs.
#   DRAFT    set DRAFT=1 to open the PR as a draft (bots typically don't review drafts).
#   DRY_RUN  set DRY_RUN=1 so `open` prints the gh command instead of creating the PR.
set -euo pipefail

BASE="${BASE:-main}"
log()  { printf '\033[1;34m[pr]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[pr] %s\033[0m\n' "$*" >&2; }
die()  { printf '\033[1;31m[pr] %s\033[0m\n' "$*" >&2; exit 1; }

remote_sha() { git ls-remote --heads origin "$1" 2>/dev/null | awk '{print $1}'; }

cmd_start() {
  local br="${1:?usage: pr.sh start <branch>}"
  git rev-parse --git-dir >/dev/null 2>&1 || die "not a git repo"
  git show-ref --verify --quiet "refs/heads/$br" && die "branch '$br' already exists locally"
  log "fetching origin/$BASE"; git fetch origin "$BASE"
  # Update local BASE to origin/BASE without switching risk, then branch off it.
  if git show-ref --verify --quiet "refs/heads/$BASE"; then
    git switch "$BASE" >/dev/null 2>&1
    git merge --ff-only "origin/$BASE" || die "local '$BASE' has diverged from origin/$BASE; reconcile first"
  else
    git switch -c "$BASE" "origin/$BASE" >/dev/null 2>&1
  fi
  # Plain checkout -b (NOT `-b <br> origin/BASE`) so the branch does NOT track BASE.
  git switch -c "$br" >/dev/null 2>&1
  log "on new branch '$br' (off up-to-date $BASE). push.default-safe: use 'pr.sh push $br'."
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
    warn "worktree NOT pristine — leaving branch '$(git rev-parse --abbrev-ref HEAD)' as-is, not switching to $BASE."
    warn "resolve these (commit, stash, or remove) then re-run 'pr.sh cleanup':"
    git status --short >&2
    return 1
  fi
  log "worktree pristine"
  git switch "$BASE" >/dev/null 2>&1 || die "could not switch to $BASE"
  log "checked out $BASE — ready for the next task"
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
