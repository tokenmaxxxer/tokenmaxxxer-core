---
issue: 284
role: implementation
code_under_review:
  - warrant/hooks/hunt-tier.sh
  - warrant/hooks/tests/run-hunt-tier-tests.sh
  - warrant/directive/warrant-protocol.md
  - docs/issue-284/reports/implementation/2026-08-24-hunt-issue-284-skip-tier.md
loop_state: landed
type: feat
breaking: false
verdict: pass
upstream:
  - path: warrant/hooks/hunt-tier.sh
    sha: 80fb8c289d09e72246f99c1f9e798e8718ad8631
---

# issue-284 — implementation record

## What was done

Added a `tier=skip` floor to `warrant/hooks/hunt-tier.sh`, below the
existing 60/120/180s bands, and updated `warrant/directive/warrant-protocol.md`'s
hunter-dispatch rule prose to state the skip condition explicitly.

1. `warrant/hooks/hunt-tier.sh`: inserted a new branch, evaluated right
   after the `gates_hooks_hit` override and right before the existing
   `docs_only || line_count<=20` (60s) branch:
   ```
   if [ "$docs_only" -eq 1 ] && [ "$line_count" -le 5 ]; then
     echo "tier=skip cap_seconds=0 max_stances=0 reason=docs-only-trivial-diff"
     exit 0
   fi
   ```
   Condition: `docs_only` (every touched path under `docs/`, which already
   covers an issue's own record files at `docs/issue-<n>/reports/...`) AND
   `line_count <= 5`. The pre-existing `gates_hooks_hit` check still runs
   first and unconditionally forces `tier=full`, so a diff cannot dodge the
   composition-bypass guard by also touching a tiny docs file. The output
   vocabulary comment and the header comment were both updated to list
   `skip` alongside `none|docs-only|small|full`.

2. `warrant/directive/warrant-protocol.md`: added a new leading bullet to
   the wall-clock-cap list, ahead of the existing 60s bullet, stating the
   skip condition and its scope (both dispatch transitions, not just a
   budget shrink) and the mandatory skip-record line, matching the
   existing docs-only-fast-path's "never silent" shape:
   > diff <= 5 lines AND every touched path under `docs/` (the issue's own
   > record files included) — skip the hunter dispatch entirely, at both
   > transitions; do not spawn. Append a section to the hunt record naming
   > the reason (`skip, diff<=5-lines-docs-only`) ...

3. `warrant/hooks/hunt-tier.sh` (second pass, post warrant-hunt): a
   background before-landing warrant-hunter dispatch (stance 0, "assume
   the gate just touched is bypassable") found that a 1-line `status:
   proposed` -> `status: approved` self-approval edit to a
   `docs/proposals/*.md` file is docs-only and <=5 lines, so the new skip
   floor exempted it from hunter dispatch entirely — even though that
   exact `status:` field is what `warrant/hooks/scope-gate.sh` reads to
   arm/disarm write-set enforcement (see hunt record cited below). Fixed
   by adding a `proposals_hit` flag (set whenever any touched path has a
   `proposals/` directory segment, mirroring the existing
   `gates_hooks_hit` segment-match style) and gating the skip branch on
   `proposals_hit -eq 0`; a proposals/ path now always falls through to
   the unchanged docs-only (60s) tier or higher, never skip. The
   directive prose bullet (item 2 above) and the header/inline comments
   were updated to state this exclusion explicitly.

4. `warrant/hooks/tests/run-hunt-tier-tests.sh`: extended with a new
   skip-tier case (a 1-line docs-only diff -> `tier=skip cap_seconds=0
   max_stances=0`), a boundary case one line above the new floor (a
   6-line docs-only diff -> unchanged `tier=docs-only cap_seconds=60`),
   a boundary case at/under the line floor but NOT docs-only (a 1-line
   non-docs diff -> stays `tier=docs-only`, confirming `docs_only` is
   required, not line count alone), and a proposals-path guard (a 1-line
   `docs/proposals/*.md` addition -> stays `tier=docs-only`, reproducing
   the hunter's finding as a permanent regression test). The pre-existing
   gates/hooks false-positive-guard case was rebased onto the new
   non-docs-tiny-diff commit so it still isolates a single one-line
   hooks/ change, and the pre-existing "docs path mentioning hooks in its
   own path" case was widened from 1 line to 6 so it continues to
   exercise the docs-only tier (not skip) — it is a regression guard for
   the hooks-substring false positive, not for the new skip floor, and
   keeping it >5 lines keeps those two concerns from entangling.

## Why

The issue's defect: the hunter-dispatch rule shrank the time budget for
small/docs-only diffs but never skipped the dispatch itself, so a 1-line
docs fix still paid two full agent-spawn round trips (same defect class as
core#282's survey-order-gate finding). The fix adds a floor tight enough
(<=5 lines, docs-only) that it cannot plausibly hide a substantive change,
while leaving every existing tier (60/120/180s) and the gates/hooks
regardless-of-size override completely unchanged.

## Upstream basis

GitHub issue #284 (full text quoted in the issue view; acceptance criteria
reproduced above), built on `warrant/hooks/hunt-tier.sh` and
`warrant/directive/warrant-protocol.md` as of commit
`80fb8c289d09e72246f99c1f9e798e8718ad8631` (this branch's base, `HEAD`
before this change).

skill-verdict: other mounted skills: not triggered (single-file shell
conditional + one markdown bullet; no cross-module coupling, no GoF
pattern decision, no data-structure/algorithm choice, and no multi-module
structure decision for `implementation-blueprint` to weigh in on).

## Acceptance evidence (executed)

Per-acceptance-criterion:

1. "hunt-tier.sh returns tier=skip cap_seconds=0 for a <=5-line, docs-only
   diff; unchanged behavior above that" and "no regression in the
   60/120/180s bands":
   ```
   $ bash -n warrant/hooks/hunt-tier.sh && echo "SYNTAX OK: hunt-tier.sh"
   $ bash -n warrant/hooks/tests/run-hunt-tier-tests.sh && echo "SYNTAX OK: run-hunt-tier-tests.sh"
   SYNTAX OK: hunt-tier.sh
   SYNTAX OK: run-hunt-tier-tests.sh

   $ bash warrant/hooks/tests/run-hunt-tier-tests.sh; echo "EXIT=$?"
   ok     empty-diff-tier                    none
   ok     empty-diff-cap                     0
   ok     skip-tier-docs-only-le5-lines      skip
   ok     skip-tier-cap                      0
   ok     skip-tier-max-stances              0
   ok     docs-only-tier-above-skip-floor    docs-only
   ok     docs-only-cap-bounded              cap_seconds=60 <= 180
   ok     docs-only-single-stance            1
   ok     tiny-non-docs-diff-does-not-skip   docs-only
   ok     proposals-path-does-not-skip       docs-only
   ok     gates-hooks-full-tier-despite-small-diff full
   ok     gates-hooks-cap                    180
   ok     gates-hooks-max-stances            2
   ok     hookspec-substring-does-not-trip-override docs-only
   ok     docs-path-mentioning-hooks-stays-docs-only docs-only

   pass=15 fail=0
   EXIT=0
   ```
   15 assertions, 0 failures, 0 skipped. `skip-tier-*` and
   `proposals-path-does-not-skip` are the four new assertions for
   issue-284's new tier (the last one reproduces the warrant-hunt finding
   below as a permanent regression guard); the remaining 11 are the
   pre-existing 60/120/180s-band and gates/hooks-override assertions,
   passing unchanged.

2. "warrant-protocol.md directive text updated to state the skip condition
   explicitly": see the new leading bullet quoted under "What was done"
   item 2, and the diff itself —
   ```
   $ git diff HEAD -- warrant/directive/warrant-protocol.md
   --- a/warrant/directive/warrant-protocol.md
   +++ b/warrant/directive/warrant-protocol.md
   @@ -45,3 +45,4 @@ Before each dispatch, read the frozen write set's size the same way `scope-gat
   +- diff <= 5 lines AND every touched path under `docs/` (the issue's own record files included) — skip the hunter dispatch entirely, at both transitions; do not spawn. Append a section to the hunt record naming the reason (`skip, diff<=5-lines-docs-only`) — the same mandatory-skip-line shape scout uses, so a skip is never silent.
    - diff <= 20 lines, or every touched path under `docs/` — 60s, one stance.
   ```

3. Regression check on the two sibling warrant-hunt test suites (neither
   file was touched by this change, run to confirm no incidental
   breakage from the hunt-tier.sh edit):
   ```
   $ bash warrant/hooks/tests/run-hunt-guard-tests.sh; echo "EXIT=$?"
   9 passed, 0 failed
   EXIT=0

   $ bash warrant/hooks/tests/run-directive-hunt-path-tests.sh; echo "EXIT=$?"
   pass=5 fail=0
   EXIT=0
   ```

No SKIPPED lines were produced by any of the above runs.

4. Before-landing warrant-hunt (background dispatch, tier size:full/180s,
   stance 0 "assume the gate just touched is bypassable" — this diff
   touches `warrant/hooks/hunt-tier.sh`, itself a hooks/ path, so it
   earned the full tier regardless of its own small size). Full hunt
   record: `docs/issue-284/reports/implementation/2026-08-24-hunt-issue-284-skip-tier.md`.
   Reproduction (fresh tmp repo, a `docs/proposals/*.md` `status:
   proposed` -> `status: approved` commit — full script in the hunt
   record's "Reproduce" section), run against `hunt-tier.sh` before and
   after the fix:
   ```
   before the fix:
   tier=skip cap_seconds=0 max_stances=0 reason=docs-only-trivial-diff

   after the fix (re-run against the same fixture commits):
   tier=docs-only cap_seconds=60 max_stances=1 reason=docs-only-or-tiny-diff
   ```

## What did not work

The first cut of the skip-tier condition (`docs_only && line_count<=5`,
with no further carve-out) let a `docs/proposals/*.md` `status:`
frontmatter flip — the exact field `scope-gate.sh` reads to arm/disarm
write-set enforcement — land in `tier=skip` and dodge hunter dispatch
entirely. Caught by the before-landing warrant-hunter before this record
was finalized; fixed by excluding any diff touching a `proposals/` path
from the skip tier (see "What was done" item 3 and the hunt record).

## Open findings

None — the one warrant-hunt finding above was fixed in this same session
before landing (see "What did not work" and the hunt record's
"Resolution" section).

## Next steps

None — record is terminal (`loop_state: landed`).
