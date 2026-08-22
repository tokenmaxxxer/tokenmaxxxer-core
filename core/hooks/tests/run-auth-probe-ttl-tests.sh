#!/usr/bin/env bash
# directive.sh's `gh auth status` precondition probe is a network call
# (~4s measured, issue-269). It must be TTL-cached under the temp dir,
# keyed by repo root: a passing probe within CORE_AUTH_PROBE_TTL seconds
# (default 300; 0 disables caching) must not re-invoke gh, but a failed
# probe must never be served from cache — auth breakage must never hide
# behind a stale success.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
HOOKS="$(cd "$HERE/.." && pwd -P)"

pass=0
fail=0
report() { # <want> <got> <name>
  if [ "$2" = "$1" ]; then
    pass=$((pass + 1)); printf 'ok     %-60s %s\n' "$3" "$2"
  else
    fail=$((fail + 1)); printf 'FAIL   %-60s want=%s got=%s\n' "$3" "$1" "$2"
  fi
}

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# fake git repo (so directive.sh's git-repo/origin precondition checks pass
# and don't distract from the gh-invocation count).
repo="$work/repo"
mkdir -p "$repo"
git -C "$repo" init -q
git -C "$repo" remote add origin https://example.invalid/x/y.git

setup_fake_gh() { # <bindir> <counter-file> <exit-code>
  local bindir="$1" counter="$2" code="$3"
  mkdir -p "$bindir"
  : > "$counter"
  cat > "$bindir/gh" <<EOF
#!/usr/bin/env bash
echo x >> "$counter"
exit $code
EOF
  chmod +x "$bindir/gh"
}

run_directive() { # <bindir> <tmpdir-for-cache>
  local bindir="$1" cachehome="$2"
  PATH="$bindir:$PATH" CLAUDE_PROJECT_DIR="$repo" TMPDIR="$cachehome" \
    CLAUDE_ROLE=implementation ${4:-} \
    bash "$HOOKS/directive.sh" >/dev/null 2>&1
}

count_lines() { # <file>
  [ -f "$1" ] && wc -l < "$1" | tr -d ' ' || echo 0
}

# --- Case 1: second run within default TTL makes zero gh calls. ---
bin1="$work/bin1"; counter1="$work/counter1"; cache1="$work/cache1"
mkdir -p "$cache1"
setup_fake_gh "$bin1" "$counter1" 0
PATH="$bin1:$PATH" CLAUDE_PROJECT_DIR="$repo" TMPDIR="$cache1" CLAUDE_ROLE=implementation bash "$HOOKS/directive.sh" >/dev/null 2>&1
first_count="$(count_lines "$counter1")"
PATH="$bin1:$PATH" CLAUDE_PROJECT_DIR="$repo" TMPDIR="$cache1" CLAUDE_ROLE=implementation bash "$HOOKS/directive.sh" >/dev/null 2>&1
second_count="$(count_lines "$counter1")"
report 1 "$first_count" "cache-miss run: exactly one gh invocation"
report "$first_count" "$second_count" "cache-hit run (within TTL): zero additional gh invocations"

# --- Case 2: CORE_AUTH_PROBE_TTL=0 always probes. ---
bin2="$work/bin2"; counter2="$work/counter2"; cache2="$work/cache2"
mkdir -p "$cache2"
setup_fake_gh "$bin2" "$counter2" 0
PATH="$bin2:$PATH" CLAUDE_PROJECT_DIR="$repo" TMPDIR="$cache2" CORE_AUTH_PROBE_TTL=0 CLAUDE_ROLE=implementation bash "$HOOKS/directive.sh" >/dev/null 2>&1
PATH="$bin2:$PATH" CLAUDE_PROJECT_DIR="$repo" TMPDIR="$cache2" CORE_AUTH_PROBE_TTL=0 CLAUDE_ROLE=implementation bash "$HOOKS/directive.sh" >/dev/null 2>&1
ttl0_count="$(count_lines "$counter2")"
report 2 "$ttl0_count" "CORE_AUTH_PROBE_TTL=0: two runs make two gh invocations (cache disabled)"

# --- Case 3: a failed probe is never served from cache; every run re-probes. ---
bin3="$work/bin3"; counter3="$work/counter3"; cache3="$work/cache3"
mkdir -p "$cache3"
setup_fake_gh "$bin3" "$counter3" 1
PATH="$bin3:$PATH" CLAUDE_PROJECT_DIR="$repo" TMPDIR="$cache3" CLAUDE_ROLE=implementation bash "$HOOKS/directive.sh" >/dev/null 2>&1
PATH="$bin3:$PATH" CLAUDE_PROJECT_DIR="$repo" TMPDIR="$cache3" CLAUDE_ROLE=implementation bash "$HOOKS/directive.sh" >/dev/null 2>&1
fail_count="$(count_lines "$counter3")"
report 2 "$fail_count" "failed probe: second run re-probes instead of serving a cached failure"

echo
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
