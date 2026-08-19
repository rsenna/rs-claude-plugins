#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/repo-standard.sh"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  [[ "$haystack" == *"$needle"* ]] || fail "expected output to contain '$needle', got: $haystack"
}

run_expect_fail() {
  local dir="$1"
  shift
  set +e
  local out
  out="$(cd "$dir" && "$SCRIPT" "$@" 2>&1)"
  local code=$?
  set -e
  [[ $code -ne 0 ]] || fail "expected command to fail: $*"
  printf '%s' "$out"
}

run_expect_ok() {
  local dir="$1"
  shift
  cd "$dir" && "$SCRIPT" "$@"
}

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

[[ -x "$SCRIPT" ]] || fail "script not executable: $SCRIPT"

# Missing repo.toml fails closed.
repo1="$TMP_ROOT/no-repo-toml"
mkdir -p "$repo1"
git -C "$repo1" init -q
out="$(run_expect_fail "$repo1" audit)"
assert_contains "$out" "repo.toml"
assert_contains "$out" "missing"

# Invalid stage fails closed.
repo2="$TMP_ROOT/invalid-stage"
mkdir -p "$repo2"
git -C "$repo2" init -q
cat > "$repo2/repo.toml" <<'EOF'
stage = "unknown"
EOF
out="$(run_expect_fail "$repo2" audit)"
assert_contains "$out" "invalid stage"

# Scaffold for prototype creates required files non-destructively.
repo3="$TMP_ROOT/prototype"
mkdir -p "$repo3"
git -C "$repo3" init -q
cat > "$repo3/repo.toml" <<'EOF'
stage = "prototype"
EOF
run_expect_ok "$repo3" scaffold >/dev/null
[[ -f "$repo3/AGENTS.md" ]] || fail "AGENTS.md not created"
[[ -f "$repo3/README.md" ]] || fail "README.md not created"
[[ -f "$repo3/SPEC.md" ]] || fail "SPEC.md not created"

# Archived scaffold does not create frozen files.
repo4="$TMP_ROOT/archived"
mkdir -p "$repo4"
git -C "$repo4" init -q
cat > "$repo4/repo.toml" <<'EOF'
stage = "archived"
EOF
run_expect_ok "$repo4" scaffold >/dev/null
[[ ! -f "$repo4/AGENTS.md" ]] || fail "AGENTS.md should not be scaffolded for archived"
[[ ! -f "$repo4/README.md" ]] || fail "README.md should not be scaffolded for archived"

echo "ok"
