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

# The fix is only present when both flags are arguments to the subprocess.run
# call inside call_claude(). File-wide text checks are unsafe: comments or dead
# code can mention both flags while the active fallback remains unisolated.
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
  # Last resort: shallow searches under existing common skill roots. Search
  # one root at a time so a missing/inaccessible sibling cannot poison the
  # documented exit status, and use -print -quit to avoid SIGPIPE under
  # pipefail.
  local root found
  for root in "$home/.claude/skills" "$home/.agents/skills" "$home/.codex/skills"; do
    [ -d "$root" ] || continue
    found="$(find "$root" -maxdepth 4 -path "*caveman-compress/scripts/compress.py" -print -quit 2>/dev/null || true)"
    [ -n "$found" ] && { printf '%s\n' "$found"; return 0; }
  done
}

compress_py="$(find_compress_py)"

if [ -z "$compress_py" ]; then
  exit 1
fi

has_isolated_claude_invocation() {
  python3 - "$1" <<'PY'
import ast
import sys

required = {"--strict-mcp-config", "--setting-sources"}

try:
    tree = ast.parse(open(sys.argv[1], encoding="utf-8").read())
except (OSError, SyntaxError):
    raise SystemExit(1)

call_claude = next(
    (node for node in tree.body if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)) and node.name == "call_claude"),
    None,
)
if call_claude is None:
    raise SystemExit(1)

subprocess_calls = []
for node in ast.walk(call_claude):
    if not isinstance(node, ast.Call) or not node.args:
        continue
    func = node.func
    if (
        isinstance(func, ast.Attribute)
        and func.attr == "run"
        and isinstance(func.value, ast.Name)
        and func.value.id == "subprocess"
    ):
        subprocess_calls.append(node)

# Fail closed on refactors or decoy/dead calls. The known-safe implementation
# has exactly one direct subprocess.run call with a literal argv list.
if len(subprocess_calls) != 1:
    raise SystemExit(1)

argv = subprocess_calls[0].args[0]
if not isinstance(argv, (ast.List, ast.Tuple)):
    raise SystemExit(1)
literal_args = {
    item.value
    for item in argv.elts
    if isinstance(item, ast.Constant) and isinstance(item.value, str)
}
raise SystemExit(0 if required <= literal_args else 1)
PY
}

if has_isolated_claude_invocation "$compress_py"; then
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
