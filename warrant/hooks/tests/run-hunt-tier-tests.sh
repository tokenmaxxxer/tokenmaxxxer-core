#!/usr/bin/env bash
# warrant/hooks/hunt-tier.sh, exercised as a real subprocess against fixture
# git repos.
#
# issue-214: warrant-hunt budget must be proportional to the diff. This
# asserts the three acceptance shapes: a docs-only diff maps to the
# single-stance tier with cap_seconds <= 180, a gates/hooks diff maps to the
# full tier regardless of size (the composition-bypass regression guard),
# and an empty diff (no changes) maps to no hunt at all.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. "$HERE/../../../core/hooks/tests/_tmp.sh"
TIER="$HERE/../hunt-tier.sh"

pass=0
fail=0

report() {
  if [ "$2" = "$1" ]; then
    pass=$((pass + 1)); printf 'ok     %-34s %s\n' "$3" "$2"
  else
    fail=$((fail + 1)); printf 'FAIL   %-34s want=%s got=%s\n' "$3" "$1" "$2"
  fi
}

field() {
  # extract key=value from a "tier=... cap_seconds=... max_stances=... reason=..." line
  printf '%s\n' "$1" | tr ' ' '\n' | grep "^$2=" | cut -d= -f2-
}

# --- empty diff: no changes between base and head -> no hunt ---
mktd
git init -q "$td"
git -C "$td" config user.email t@t.example
git -C "$td" config user.name t
echo one > "$td/f.txt"
git -C "$td" add f.txt
git -C "$td" commit -q -m base
base_sha="$(git -C "$td" rev-parse HEAD)"

out="$(cd "$td" && bash "$TIER" "$base_sha" "$base_sha")"
report none "$(field "$out" tier)" empty-diff-tier
report 0 "$(field "$out" cap_seconds)" empty-diff-cap

# --- docs-only diff: small change entirely under docs/ ---
mkdir -p "$td/docs"
echo "hello" > "$td/docs/note.md"
git -C "$td" add docs/note.md
git -C "$td" commit -q -m docs-change
docs_sha="$(git -C "$td" rev-parse HEAD)"

out="$(cd "$td" && bash "$TIER" "$base_sha" "$docs_sha")"
tier="$(field "$out" tier)"
cap="$(field "$out" cap_seconds)"
report docs-only "$tier" docs-only-tier
if [ "$cap" -le 180 ] 2>/dev/null; then
  pass=$((pass + 1)); printf 'ok     %-34s cap_seconds=%s <= 180\n' docs-only-cap-bounded "$cap"
else
  fail=$((fail + 1)); printf 'FAIL   %-34s cap_seconds=%s > 180\n' docs-only-cap-bounded "$cap"
fi
report 1 "$(field "$out" max_stances)" docs-only-single-stance

# --- gates/hooks diff: a ONE-line change inside a hooks/ path must still
#     be full tier, not the docs-only/small tier its size alone would earn ---
mkdir -p "$td/warrant/hooks"
echo "echo hi" > "$td/warrant/hooks/example.sh"
git -C "$td" add warrant/hooks/example.sh
git -C "$td" commit -q -m hooks-change
hooks_sha="$(git -C "$td" rev-parse HEAD)"

out="$(cd "$td" && bash "$TIER" "$docs_sha" "$hooks_sha")"
report full "$(field "$out" tier)" gates-hooks-full-tier-despite-small-diff
report 180 "$(field "$out" cap_seconds)" gates-hooks-cap
report 2 "$(field "$out" max_stances)" gates-hooks-max-stances

# --- false-positive guard: a path merely CONTAINING "hooks" as a substring
#     (not a hooks/ directory segment) must NOT trip the override ---
mkdir -p "$td/hookspec"
echo "not a hooks dir" > "$td/hookspec/plain.txt"
git -C "$td" add hookspec/plain.txt
git -C "$td" commit -q -m hookspec-change
hookspec_sha="$(git -C "$td" rev-parse HEAD)"

out="$(cd "$td" && bash "$TIER" "$hooks_sha" "$hookspec_sha")"
report docs-only "$(field "$out" tier)" hookspec-substring-does-not-trip-override

# --- before-landing false-positive guard: a docs/ report path that merely
#     MENTIONS "hooks" in its own path (a report ABOUT hooks) must not
#     cancel the docs-only fast path -- it is still wholly under docs/ ---
mkdir -p "$td/docs/issue-1/reports/hooks"
echo "notes" > "$td/docs/issue-1/reports/hooks/notes.md"
git -C "$td" add docs/issue-1/reports/hooks/notes.md
git -C "$td" commit -q -m docs-report-about-hooks
docs_report_sha="$(git -C "$td" rev-parse HEAD)"

out="$(cd "$td" && bash "$TIER" "$hookspec_sha" "$docs_report_sha")"
report docs-only "$(field "$out" tier)" docs-path-mentioning-hooks-stays-docs-only

echo
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
