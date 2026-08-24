#!/usr/bin/env bash
# warrant/hooks/hunt-tier.sh, exercised as a real subprocess against fixture
# git repos.
#
# issue-214: warrant-hunt budget must be proportional to the diff. This
# asserts the acceptance shapes: a docs-only diff maps to the single-stance
# tier with cap_seconds <= 180, a gates/hooks diff maps to the full tier
# regardless of size (the composition-bypass regression guard), and an
# empty diff (no changes) maps to no hunt at all.
#
# issue-284: a <=5-line diff wholly under docs/ maps to tier=skip,
# cap_seconds=0 (the dispatch itself is skipped, not merely shrunk) —
# unchanged behavior for every diff above that floor.
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

# --- skip tier: a <=5-line diff entirely under docs/ (issue-284) ---
mkdir -p "$td/docs"
echo "hello" > "$td/docs/tiny.md"
git -C "$td" add docs/tiny.md
git -C "$td" commit -q -m docs-tiny-change
skip_sha="$(git -C "$td" rev-parse HEAD)"

out="$(cd "$td" && bash "$TIER" "$base_sha" "$skip_sha")"
report skip "$(field "$out" tier)" skip-tier-docs-only-le5-lines
report 0 "$(field "$out" cap_seconds)" skip-tier-cap
report 0 "$(field "$out" max_stances)" skip-tier-max-stances

# --- docs-only diff: change entirely under docs/ but ABOVE the skip
#     tier's 5-line floor -> unchanged 60s/docs-only tier ---
mkdir -p "$td/docs"
printf 'line1\nline2\nline3\nline4\nline5\nline6\n' > "$td/docs/note.md"
git -C "$td" add docs/note.md
git -C "$td" commit -q -m docs-change
docs_sha="$(git -C "$td" rev-parse HEAD)"

out="$(cd "$td" && bash "$TIER" "$skip_sha" "$docs_sha")"
tier="$(field "$out" tier)"
cap="$(field "$out" cap_seconds)"
report docs-only "$tier" docs-only-tier-above-skip-floor
if [ "$cap" -le 180 ] 2>/dev/null; then
  pass=$((pass + 1)); printf 'ok     %-34s cap_seconds=%s <= 180\n' docs-only-cap-bounded "$cap"
else
  fail=$((fail + 1)); printf 'FAIL   %-34s cap_seconds=%s > 180\n' docs-only-cap-bounded "$cap"
fi
report 1 "$(field "$out" max_stances)" docs-only-single-stance

# --- skip-tier boundary guard: a <=5-line diff NOT entirely under docs/
#     must NOT skip -- only docs-only diffs may earn tier=skip ---
echo "code" > "$td/f.txt"
git -C "$td" add f.txt
git -C "$td" commit -q -m non-docs-tiny-change
nondocs_sha="$(git -C "$td" rev-parse HEAD)"

out="$(cd "$td" && bash "$TIER" "$docs_sha" "$nondocs_sha")"
report docs-only "$(field "$out" tier)" tiny-non-docs-diff-does-not-skip

# --- skip-tier proposals guard: a <=5-line diff wholly under docs/ but
#     touching a proposals/ path must NOT skip -- scope-gate.sh reads a
#     proposal's status: frontmatter to arm/disarm write-set enforcement,
#     so even a 1-line status flip there is gating-relevant, not trivial ---
mkdir -p "$td/docs/proposals"
echo "status: approved" > "$td/docs/proposals/2026-08-24-example.md"
git -C "$td" add docs/proposals/2026-08-24-example.md
git -C "$td" commit -q -m proposal-status-flip
proposal_sha="$(git -C "$td" rev-parse HEAD)"

out="$(cd "$td" && bash "$TIER" "$nondocs_sha" "$proposal_sha")"
report docs-only "$(field "$out" tier)" proposals-path-does-not-skip

# --- gates/hooks diff: a ONE-line change inside a hooks/ path must still
#     be full tier, not the docs-only/small tier its size alone would earn ---
mkdir -p "$td/warrant/hooks"
echo "echo hi" > "$td/warrant/hooks/example.sh"
git -C "$td" add warrant/hooks/example.sh
git -C "$td" commit -q -m hooks-change
hooks_sha="$(git -C "$td" rev-parse HEAD)"

out="$(cd "$td" && bash "$TIER" "$nondocs_sha" "$hooks_sha")"
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
printf 'note1\nnote2\nnote3\nnote4\nnote5\nnote6\n' > "$td/docs/issue-1/reports/hooks/notes.md"
git -C "$td" add docs/issue-1/reports/hooks/notes.md
git -C "$td" commit -q -m docs-report-about-hooks
docs_report_sha="$(git -C "$td" rev-parse HEAD)"

out="$(cd "$td" && bash "$TIER" "$hookspec_sha" "$docs_report_sha")"
report docs-only "$(field "$out" tier)" docs-path-mentioning-hooks-stays-docs-only

echo
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
