#!/usr/bin/env bash
# check-caveman-compress.sh — verify the locally installed caveman-compress
# skill carries the claude --print subprocess isolation fix before this skill
# relies on it to compress a generated file.
#
# Without the fix, caveman-compress's `claude --print` fallback boots a full
# Claude Code session that inherits the host's hooks/MCP config, and can leak
# narrated commentary into the file it's supposed to be compressing instead
# of shrinking it (observed and fixed upstream: JuliusBrussee/caveman#920,
# fix in #921). This is a temporary guardrail against running an unpatched
# copy on a host where the fix hasn't been picked up yet — remove once the
# fix has shipped upstream for a while and re-checking every run stops
# earning its keep.
#
# Usage: check-caveman-compress.sh
# Exit codes:
#   0  patched — safe to invoke caveman-compress
#   1  not installed on this host — caller should skip compression, not fail
#   2  installed but NOT patched — caller must stop and surface the message below
set -euo pipefail

log()  { printf '\033[1;34m[check-caveman-compress]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[check-caveman-compress] %s\033[0m\n' "$*" >&2; }

# Both flags together are the fix (see the upstream PR) — checking only one
# would report "patched" if a future edit ever dropped just the other half.
FIX_MARKERS=('--strict-mcp-config' '--setting-sources')

find_compress_py() {
  # ${HOME:-} rather than $HOME: some minimal/sandboxed subprocess environments
  # run with HOME unset, and under `set -u` that would abort the script with a
  # raw "HOME: unbound variable" instead of falling into the "not installed,
  # skip compression" (exit 1) path this case should take.
  local home="${HOME:-}"
  local candidates=(
    "${CAVEMAN_COMPRESS_SCRIPT:-}"
  )
  if [ -n "$home" ]; then
    candidates+=(
      "$home/.claude/skills/caveman-compress/scripts/compress.py"
      "$home/.agents/skills/caveman-compress/scripts/compress.py"
    )
  fi
  local c
  for c in "${candidates[@]}"; do
    [ -n "$c" ] && [ -f "$c" ] && { printf '%s\n' "$c"; return 0; }
  done
  [ -n "$home" ] || return 0
  # Last resort: shallow search under common skill roots, for hosts laid out
  # differently than this one.
  find "$home/.claude/skills" "$home/.agents/skills" "$home/.codex/skills" \
    -maxdepth 4 -path "*caveman-compress/scripts/compress.py" 2>/dev/null \
    | head -n1
}

compress_py="$(find_compress_py)"

if [ -z "$compress_py" ]; then
  warn "caveman-compress not found on this host — skipping compression, not failing."
  exit 1
fi

all_markers_present=1
for marker in "${FIX_MARKERS[@]}"; do
  grep -q -- "$marker" "$compress_py" 2>/dev/null || all_markers_present=0
done

if [ "$all_markers_present" = 1 ]; then
  log "caveman-compress at $compress_py carries the subprocess isolation fix."
  exit 0
fi

warn "caveman-compress at $compress_py is UNPATCHED (missing ${FIX_MARKERS[*]})."
warn "Its 'claude --print' fallback can leak this host's hooks/MCP context into"
warn "whatever file it compresses instead of shrinking it — do not run it as-is."
warn ""
warn "Fix: apply https://github.com/JuliusBrussee/caveman/pull/921"
warn "  (or, until it merges: JuliusBrussee/caveman#920 has the same diff inline)."
warn "  In compress.py's call_claude(), change:"
warn '    [claude_bin, "--print"]'
warn "  to:"
warn '    [claude_bin, "--print", "--setting-sources", "", "--strict-mcp-config"]'
exit 2
