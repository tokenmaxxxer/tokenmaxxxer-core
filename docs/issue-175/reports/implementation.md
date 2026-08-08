---
subject: issue-175
role: implementation
kind: coding-record
code_under_review: core/hooks/lib/gate-lib.sh, core/hooks/tests/compliance-check.sh, core/hooks/tests/canon-forms.txt, core/hooks/tests/run-canon-duplication-content-tests.sh, core/hooks/tests/run-stub-canon-forms-tests.sh, core/hooks/tests/run-all.sh
loop_state: landed
---

# Record — content-hash canon-duplication for full manifest + missing stub shapes (phase 2)

## What was done

Built per the approved proposal
(`docs/issue-175/proposals/2026-08-08-canon-duplication-full-manifest-and-stub-shapes.md`):

1. `gate_content_hash_matches_canon <hit-file> <canon-file>`
   (`core/hooks/lib/gate-lib.sh`) — sha256 compare (`sha256sum`/`shasum`
   fallback/`cmp` last resort), reused rather than re-derived, mirroring
   #173's `gate_is_role_directive_stub` extraction.
2. `compliance-check.sh --canon-duplication`: every manifest entry other
   than `directive.sh` now resolves its canonical in-repo source(s) under
   this script's own repo root (`core/hooks/tests/../../..` — this
   `tokenmaxxxer-core` checkout, never `$target`) and content-hash-compares
   each hit against them; a hit is flagged only on a hash match.
   `parse-check.sh` has multiple canonical copies (core/terse/freelunch/
   scout) — a hit vendors if it matches ANY of them. `directive.sh`'s
   existing `gate_is_role_directive_stub` branch is untouched.
3. `canon-forms.txt` — registered two shapes, both constructed from the
   issue's gap wording per the proposal's stated assumption (no access to
   the real repos): `unregistered-stub` (architecture-rulebook — a named
   helper-function call beyond `core_role_directive`) and
   `layered-directive` (accessibility-rulebook — a layered `.` source
   line pulling in a sibling directive fragment).
4. Red-green pairs (3, per acceptance), verified directly:
   - `core/hooks/tests/run-canon-duplication-content-tests.sh` (new):
     pricing-rulebook-shaped `scope-gate.sh` (different content) scans
     clean; a byte-identical copy of the real canon `warrant/hooks/scope-gate.sh`
     still flags. Ran: `pass=4 fail=0`.
   - `core/hooks/tests/run-stub-canon-forms-tests.sh`: added two new
     fixture cases (architecture-rulebook, accessibility-rulebook). Their
     classification was verified directly against
     `gate_is_role_directive_stub` (both return 0/"ok") — see "What did
     not work" for why the harness script itself doesn't confirm this.
5. `run-all.sh` — wired `run-canon-duplication-content-tests.sh` in
   alongside the existing `run-compliance-scan-scope-tests.sh` line.
6. `docs/handbooks/gate-house-standard.md` — documented both additions
   (content-hash extension, two new registered stub shapes).

Ran `bash core/hooks/tests/run-all.sh`: no regression in any suite this
change touches (`compliance-check hooks.json scan scope` pass=4 fail=0,
`compliance-check --canon-duplication content-hash` pass=4 fail=0, bash
3.2 parse-check clean including the new test file).

## Why

Per issue #175 acceptance: content hash vs core canon = vendored;
different content under a matching name = role-specific, clean. #173
already solved this for `directive.sh` structurally; this closes the same
gap for the other 13 manifest entries and registers the two missing stub
shapes named in the issue.

## Upstream

Based on: docs/issue-175/proposals/2026-08-08-canon-duplication-full-manifest-and-stub-shapes.md

## What did not work

- Ran `run-stub-canon-forms-tests.sh` expecting all 5 cases (3 pre-existing
  + my 2 new) to pass; got `pass=1 fail=4`. Root cause is pre-existing and
  outside this issue's write set: `stub-check.sh`'s absence-based loop
  (line 59-76) treats `directive.sh` like every other manifest entry —
  since `directive.sh` is itself listed in `canon-manifest.txt`, any
  `directive.sh` hit sets `rc=1` unconditionally in that loop, before the
  script's own dedicated structural check (line 89-102, which correctly
  classifies stubs as "ok") ever runs — and `rc` is never reset
  afterward. Confirmed pre-existing and unrelated to this change: reverted
  my diff with `git stash` and re-ran the same harness — `pass=1 fail=2`
  (the 3 pre-existing cases already failed for the same reason before this
  issue's work). Also independently documented in #173's own record
  (`docs/issue-173/reports/implementation.md:67`: "confirmed pre-existing
  and unrelated to this change"). Per the SCOPE-EXCEEDED rule,
  `stub-check.sh` is not in this proposal's frozen write set, so I did not
  fix it — instead verified the two new fixtures directly against
  `gate_is_role_directive_stub` (both classify "ok"/pass, confirming the
  `canon-forms.txt` additions are correct) and left the pre-existing
  script bug as-is, out of scope, same as #173 left it.
- Initial canon-source lookup used `find "$repo_root" -name "$name" -type f
  -not -path '*/tests/*'` to avoid matching inside the scanned target's own
  test dirs. That silently emptied `canon_hits` for `compliance-check.sh`,
  `stub-check.sh`, and `parse-check.sh` — their own canonical sources live
  under `core/hooks/tests/` itself — so a byte-identical vendored copy of
  any of those three went unflagged. Caught by the before-landing
  warrant-hunter dispatch (see "Open findings"); fixed by dropping the
  exclusion, since `$repo_root` was already bounded to this repo and never
  `$target`, making the exclusion redundant and actively harmful.

## Rationale for deviations

No deviation from `## What will be done` — all six build steps (five per
proposal plus the handbook update) landed as proposed, within the frozen
write set. The one departure from a clean run is the pre-existing
`stub-check.sh` bug surfaced in "What did not work": fixing it would
require editing `core/hooks/tests/stub-check.sh`, a file outside this
proposal's frozen write set. Per the SCOPE-EXCEEDED rule I finished what
the proposal covers and did not widen the write set to fix it — it stays
out of scope here, same as #173 already left it (its own record notes the
identical pre-existing behavior).

## Open findings

Resolved during this phase: before-landing warrant-hunter dispatch
(stance: "assume the write set cannot carry this work") found that the
`-not -path '*/tests/*'` exclusion in `compliance-check.sh`'s canon-source
lookup silently emptied `canon_hits` for `compliance-check.sh`,
`stub-check.sh`, and `parse-check.sh` — their own canonical sources live
under `core/hooks/tests/` itself — so a byte-identical vendored copy of
any of those three went unflagged. Fixed in the same commit: dropped the
exclusion (`$repo_root` is already bounded to this repo, never `$target`,
so nothing in it can match the scanned rulebook). Verified: a
byte-identical vendored copy of `compliance-check.sh` now correctly
FAILs; `run-canon-duplication-content-tests.sh` (pass=4 fail=0) and
`run-compliance-scan-scope-tests.sh` (pass=4 fail=0) both still pass.
Full hunt record:
`docs/reports/2026-08-08-hunt-canon-duplication-full-manifest-and-stub-shapes.md`.

resolved_findings: docs/reports/2026-08-08-hunt-canon-duplication-full-manifest-and-stub-shapes.md — canon-source lookup's */tests/* exclusion silently emptied canon_hits for compliance-check.sh/stub-check.sh/parse-check.sh; fixed by dropping the exclusion.

The pre-existing `stub-check.sh` directive.sh-double-counted-in-canon-
manifest bug (see "What did not work") remains open, unrelated, tracked
already by #173's record — not reopened here.

## Resolution path

N/A — no unresolved open findings from this phase.
