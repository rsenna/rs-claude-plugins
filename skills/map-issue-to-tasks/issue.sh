#!/usr/bin/env bash
# issue.sh — GitHub issue plumbing for the map-issue-to-tasks / fix-mapped-issue skills.
#
# Subcommands:
#   fetch <n>            print a readable digest of issue #n (title, state, labels, body, comments)
#   json  <n>            raw JSON (number,title,state,labels,body,comments,url) for parsing
#   slug  <n>            print "<n>-<slugified-title>" (used for tasks/issue-<n>-<slug>.md)
#   comment <n> <file>   post <file> as a comment on #n   (DRY_RUN=1 prints instead of posting)
#   close <n> <file>     post <file> as a comment on #n, then close it (DRY_RUN=1 prints, no close)
#
# Env:
#   DRY_RUN=1   never write to GitHub; print what would be posted.
set -euo pipefail

log()  { printf '\033[1;34m[issue]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[issue] %s\033[0m\n' "$*" >&2; exit 1; }

cmd_json() { gh issue view "${1:?usage: issue.sh json <n>}" \
  --json number,title,state,labels,body,comments,url; }

cmd_fetch() {
  local n="${1:?usage: issue.sh fetch <n>}"
  gh issue view "$n" --json number,title,state,labels,body,comments,url --jq '
    "#\(.number)  [\(.state)]  \(.title)\n\(.url)\n" +
    "labels: " + ((.labels|map(.name))|join(", ")) + "\n\n" +
    "── body ──\n" + (.body // "(empty)") + "\n" +
    (if (.comments|length)>0
     then "\n── comments ──\n" + ([.comments[] | "@\(.author.login): \(.body)"]|join("\n\n"))
     else "" end)'
}

cmd_slug() {
  local n="${1:?usage: issue.sh slug <n>}"
  local title; title="$(gh issue view "$n" --json title --jq .title)"
  local slug; slug="$(printf '%s' "$title" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')"
  # Cap length without cutting a word in half: if truncating, drop the last token.
  if [ "${#slug}" -gt 50 ]; then slug="$(printf '%s' "$slug" | cut -c1-50 | sed -E 's/-[^-]*$//')"; fi
  printf '%s-%s\n' "$n" "$slug"
}

cmd_comment() {
  local n="${1:?usage: issue.sh comment <n> <file>}"; local f="${2:?missing file}"
  [ -f "$f" ] || die "file not found: $f"
  if [ "${DRY_RUN:-0}" = "1" ]; then
    log "DRY_RUN — would post to #$n:"; echo "-----"; cat "$f"; echo "-----"; return 0
  fi
  gh issue comment "$n" --body-file "$f"; log "commented on #$n"
}

cmd_close() {
  local n="${1:?usage: issue.sh close <n> <file>}"; local f="${2:?missing file}"
  [ -f "$f" ] || die "file not found: $f"
  if [ "${DRY_RUN:-0}" = "1" ]; then
    log "DRY_RUN — would comment then close #$n:"; echo "-----"; cat "$f"; echo "-----"; return 0
  fi
  gh issue comment "$n" --body-file "$f"
  gh issue close "$n"; log "commented on and closed #$n"
}

case "${1:-}" in
  fetch)   shift; cmd_fetch "$@" ;;
  json)    shift; cmd_json "$@" ;;
  slug)    shift; cmd_slug "$@" ;;
  comment) shift; cmd_comment "$@" ;;
  close)   shift; cmd_close "$@" ;;
  *) die "usage: issue.sh {fetch|json|slug|comment|close} ..." ;;
esac
