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

FIX_MARKER='--strict-mcp-config'

find_compress_py() {
  local candidates=(
    "${CAVEMAN_COMPRESS_SCRIPT:-}"
    "$HOME/.claude/skills/caveman-compress/scripts/compress.py"
    "$HOME/.agents/skills/caveman-compress/scripts/compress.py"
  )
  local c
  for c in "${candidates[@]}"; do
    [ -n "$c" ] && [ -f "$c" ] && { printf '%s\n' "$c"; return 0; }
  done
  # Last resort: shallow search under common skill roots, for hosts laid out
  # differently than this one.
  find "$HOME/.claude/skills" "$HOME/.agents/skills" "$HOME/.codex/skills" \
    -maxdepth 4 -path "*caveman-compress/scripts/compress.py" 2>/dev/null \
    | head -n1
}

compress_py="$(find_compress_py)"

if [ -z "$compress_py" ]; then
  warn "caveman-compress not found on this host — skipping compression, not failing."
  exit 1
fi

if grep -q -- "$FIX_MARKER" "$compress_py" 2>/dev/null; then
  log "caveman-compress at $compress_py carries the subprocess isolation fix."
  exit 0
fi

warn "caveman-compress at $compress_py is UNPATCHED (missing '$FIX_MARKER')."
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
