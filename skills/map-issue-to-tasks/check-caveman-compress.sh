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
# Looks for caveman-compress in order: $CAVEMAN_COMPRESS_SCRIPT (exact path),
# $AGENT_SKILLS_ROOT/caveman-compress/..., this script's own skills root
# (caveman-compress installed as a sibling of this skill), then
# $HOME/.agents/skills/caveman-compress/... — self-locating rather than
# assuming a fixed root, since different installers place skills differently.
# Exit codes:
#   0  patched — safe to invoke caveman-compress
#   1  not installed anywhere above — caller should skip compression, not fail
#      (this script only warns; it never treats "not installed" as an error)
#   2  installed but NOT patched — caller must stop and surface the message below
set -euo pipefail

log() { printf '\033[1;34m[check-caveman-compress]\033[0m %s\n' "$*"; }
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

  # Self-locate: caveman-compress, if installed, is a SIBLING of this script's
  # own skill directory under whatever skills root installed this plugin —
  # same rationale as this plugin's own SKILL.md docs (see
  # pull-request-process/SKILL.md et al.): don't assume a fixed install root,
  # derive it from where this script itself actually lives.
  local self_dir skills_root
  self_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  skills_root="$(dirname "$self_dir")"

  local candidates=(
    "${CAVEMAN_COMPRESS_SCRIPT:-}"
  )
  if [[ -n "${AGENT_SKILLS_ROOT:-}" ]]; then
    candidates+=(
      "$AGENT_SKILLS_ROOT/caveman-compress/scripts/compress.py"
    )
  fi
  candidates+=(
    "$skills_root/caveman-compress/scripts/compress.py"
  )
  if [[ -n "$home" ]]; then
    candidates+=(
      "$home/.agents/skills/caveman-compress/scripts/compress.py"
    )
  fi
  local c
  for c in "${candidates[@]}"; do
    [[ -n "$c" && -f "$c" ]] && {
      printf '%s\n' "$c"
      return 0
    }
  done
  # Last resort: shallow searches under every root we know about. Search one
  # root at a time so a missing/inaccessible sibling cannot poison the
  # documented exit status, and use -print -quit to avoid SIGPIPE under
  # pipefail.
  local -a search_roots=("$skills_root")
  if [[ -n "${AGENT_SKILLS_ROOT:-}" ]]; then
    search_roots+=("$AGENT_SKILLS_ROOT")
  fi
  if [[ -n "$home" ]]; then
    search_roots+=("$home/.agents/skills" "$home/.claude/skills" "$home/.codex/skills")
  fi
  local root found
  for root in "${search_roots[@]}"; do
    [[ -d "$root" ]] || continue
    found="$(find "$root" -maxdepth 4 -path "*caveman-compress/scripts/compress.py" -print -quit 2>/dev/null || true)"
    [[ -n "$found" ]] && {
      printf '%s\n' "$found"
      return 0
    }
  done
}

# `|| true`: when find_compress_py finds nothing, its own final statement
# (the last-resort search loop) legitimately evaluates false as its very last
# executed command, which — under `set -e`, with no exempting context —
# would otherwise abort THIS script right here, at the assignment, before
# the "not found, warn and skip" handling below ever runs. `|| true` makes
# "nothing found" the expected, handled outcome it already is (checked by
# the very next line), not a script-ending error.
compress_py="$(find_compress_py)" || true

if [[ -z "$compress_py" ]]; then
  warn "caveman-compress not found (checked \$CAVEMAN_COMPRESS_SCRIPT, \$AGENT_SKILLS_ROOT," \
       "this skill's own skills root, \$HOME/.agents/skills, \$HOME/.claude/skills," \
       "and \$HOME/.codex/skills) — skipping compression, proceeding uncompressed." \
       "This is not a failure."
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

call_claude_defs = [
    node
    for node in tree.body
    if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef))
    and node.name == "call_claude"
]
if len(call_claude_defs) != 1:
    raise SystemExit(1)
call_claude = call_claude_defs[0]

def is_subprocess_run(node):
    if not isinstance(node, ast.Call) or not node.args:
        return False
    func = node.func
    return (
        isinstance(func, ast.Attribute)
        and func.attr == "run"
        and isinstance(func.value, ast.Name)
        and func.value.id == "subprocess"
    )


def assigned_subprocess_run(statement):
    if not isinstance(statement, (ast.Assign, ast.AnnAssign)):
        return None
    return statement.value if is_subprocess_run(statement.value) else None


class OwnScopeSubprocessCalls(ast.NodeVisitor):
    def __init__(self):
        self.calls = []

    def visit_Call(self, node):
        func = node.func
        if (
            isinstance(func, ast.Attribute)
            and isinstance(func.value, ast.Name)
            and func.value.id == "subprocess"
        ):
            self.calls.append(node)
        self.generic_visit(node)

    def visit_FunctionDef(self, node):
        pass

    visit_AsyncFunctionDef = visit_FunctionDef
    visit_Lambda = visit_FunctionDef
    visit_ClassDef = visit_FunctionDef


visitor = OwnScopeSubprocessCalls()
for statement in call_claude.body:
    visitor.visit(statement)

# The known-safe upstream call_claude layout is: docstring, api_key assignment,
# conditional SDK path, claude_bin assignment, then the CLI Try as the final
# statement. Pinning that layout proves the guarded call is reachable when the
# SDK path is unavailable; broader matching admits unreachable decoys.
body = call_claude.body
layout_ok = (
    len(body) == 5
    and isinstance(body[0], ast.Expr)
    and isinstance(body[0].value, ast.Constant)
    and isinstance(body[0].value.value, str)
    and isinstance(body[1], ast.Assign)
    and len(body[1].targets) == 1
    and isinstance(body[1].targets[0], ast.Name)
    and body[1].targets[0].id == "api_key"
    and isinstance(body[2], ast.If)
    and isinstance(body[2].test, ast.Name)
    and body[2].test.id == "api_key"
    and not body[2].orelse
    and isinstance(body[3], ast.Assign)
    and len(body[3].targets) == 1
    and isinstance(body[3].targets[0], ast.Name)
    and body[3].targets[0].id == "claude_bin"
    and isinstance(body[4], ast.Try)
    and body[4].body
)
accepted_call = assigned_subprocess_run(body[4].body[0]) if layout_ok else None
if (
    accepted_call is None
    or len(visitor.calls) != 1
    or visitor.calls[0] is not accepted_call
):
    raise SystemExit(1)

subprocess_calls = [accepted_call]

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
