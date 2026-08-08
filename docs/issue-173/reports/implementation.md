---
code_under_review:
  - core/hooks/lib/gate-lib.sh
  - core/hooks/tests/stub-check.sh
  - core/hooks/tests/compliance-check.sh
  - core/hooks/tests/run-fleet-scan-tests.sh
loop_state: build_complete
---

# Implementation record — issue-173

## What was done

Implemented the approved phase-1 proposal
(`docs/issue-173/proposals/2026-08-08-canon-duplication-stub-distinction.md`,
PR #174): `compliance-check.sh --canon-duplication` no longer flags every
file named `directive.sh` as a vendored copy by filename alone.

- Added `gate_is_role_directive_stub <file>` to `core/hooks/lib/gate-lib.sh`,
  extracted verbatim (logic-preserving) from `stub-check.sh`'s inline
  directive.sh structural check: sources `canon-forms.txt`, verifies the
  file sources `role-directive.sh`, calls `core_role_directive`, and has no
  other line beyond a registered `canon-forms.txt` shape. Returns 0 (stub)
  or 1 (not), printing the fail reason on stdout for a 1 return.
- `core/hooks/tests/stub-check.sh` now sources `gate-lib.sh` and calls
  `gate_is_role_directive_stub` in place of its inline block — same output
  messages, same exit behavior.
- `core/hooks/tests/compliance-check.sh`'s `--canon-duplication` loop now
  special-cases `name = directive.sh`: for each hit, calls
  `gate_is_role_directive_stub`; a sanctioned stub passes ("ok" line, no
  vendored-copy FAIL), a non-stub still fails with the existing
  vendored-copy message. Every other manifest name keeps the current
  unconditional filename-match FAIL, unchanged.
- Added the stub-vs-vendored red-green pair to
  `core/hooks/tests/run-fleet-scan-tests.sh`: a synthetic rulebook with a
  correct single-call `directive.sh` stub scans clean (exit 0, no
  vendored-copy flag) under `--canon-duplication`; a synthetic rulebook
  with a full pre-promotion `directive.sh` body still flags (exit 1,
  vendored-copy message present).

## Why

Per the approved proposal's Rationale: reuse `stub-check.sh`'s existing
structural classification (line-shape check against `canon-forms.txt`)
through one shared `gate-lib.sh` function, rather than duplicating the
classification inside `compliance-check.sh` (a second independently
maintained copy — the exact drift class `canon-manifest.txt` reuse already
exists to prevent) or a weaker size/marker heuristic (would accept a stub
that regrew boilerplate around a `core_role_directive` call, the exact
failure `stub-check.sh` exists to catch).

## Upstream / basis

Approved proposal: `docs/issue-173/proposals/2026-08-08-canon-duplication-stub-distinction.md`
Survey: `docs/issue-173/reports/implementation/survey.md`
Approval: issue-173 comment "APPROVE issue-173/implementation" by
JiwonJung94 (approvers.md-listed; PR #174 author == approver, single-account
mode, exact string match).

## Verification run (generation-time confirmation, not a separate pass)

- `core/hooks/tests/run-fleet-scan-tests.sh`: 13 passed, 0 failed (includes
  the new stub-vs-vendored pair; live 43-repo network check ran, passed).
- `core/hooks/tests/run-gate-lib-tests.sh`: 62 passed, 0 failed (existing
  stub-check/compliance-check coverage unaffected).
- `core/hooks/tests/run-stub-canon-forms-tests.sh`: 1 passed, 2 failed —
  confirmed pre-existing and unrelated to this change: `directive.sh` is
  also a `canon-manifest.txt` entry, so `stub-check.sh`'s first,
  unconditional-filename-match loop (untouched by this proposal — it
  belongs to the earlier issue-66 mechanism, not the `--canon-duplication`
  surface this issue scopes) already flags any `directive.sh` hit before
  the second, structural loop this proposal touches ever runs. Reproduced
  identically on `git stash` (pre-change tree) with the same 2 failures —
  not introduced by this work, and outside the frozen write set (`files:`
  in the approved proposal does not include `stub-check.sh`'s first loop's
  filename list). Not fixed here; a candidate follow-up issue, not a
  scope-exceeded stop, since it was already broken before this change.
- `bash -n` syntax check on all four modified shell files: clean.
- Manual: `compliance-check.sh --canon-duplication` against a synthetic dir
  with only a sanctioned stub exits 0; against one with a full vendored
  body exits 1 (exercised via the new automated red-green pair above,
  same as the proposal's "How you'll know it worked" manual checks).

## Doc-placement ladder

- [x] No env var / config key / new dependency / migration / setup step
  introduced — handbook update not applicable.
- [x] Library-or-format choice recorded: proposal's own `## Rationale`
  section already carries the alternative-and-reason (shared `gate-lib.sh`
  function vs. duplicated logic vs. size/marker heuristic); no additional
  `docs/issue-173/decisions/` entry needed beyond the proposal itself.
  No changed public signature or wire format outside this repo's own
  shell functions.
- [x] No benchmark/investigation numbers produced — no
  `docs/issue-173/reports/` entry beyond this record.

## What did not work

None — the extraction and call-site changes matched the proposal on the
first pass. A newly-authored test fixture needed one correction before it
exercised the right shape: the first draft of the red-green pair's
sanctioned-stub fixture used a `ROLE="implementation"` variable assignment
and a `set -uo pipefail` line that are not part of the real single-call
stub shape (`role-directive.sh`'s own documented usage passes four literal
string arguments directly to `core_role_directive`, no intermediate
variable, no `set` line) — the fixture correctly failed the structural
check for a fixture-authoring reason, not an implementation defect. Fixed
by matching the fixture to `role-directive.sh`'s documented usage exactly.

## Rationale for deviations

One addition beyond the frozen write set: `docs/handbooks/fleet-scan-tests.md`
(new file). `handbook-trigger-gate.sh` mechanically refused the landing
commit because it touches `core/hooks/tests/run-fleet-scan-tests.sh` (an
operational-surface `run-*.sh` script) with no corresponding
`docs/handbooks/` update in the same commit (contract §21), and no
handbook for this test harness existed yet (a pre-existing gap — every
sibling `run-*-tests.sh` harness already has one). Added the minimal
handbook the gate requires, documenting `run-fleet-scan-tests.sh` and this
issue's new red-green pair, so the approved work could land at all. All
functional code changes stayed exactly inside the approved write set;
this is the one file added, and it is documentation of the write set's
own test coverage, not a new decision.

## Open findings

None outstanding against this change. Hunt dispatched below.

## Hunt

Before-landing dispatch: diff size 143 insertions + 58 deletions across 4
non-docs files (`git diff --stat`) → tier 120s (21-200 line band). Stance
index `(.warrant-hunt.count mod 5)` = 1 mod 5 = 1: "assume this change and
another plugin's rule cancel each other — find the pair." Record appended
below once the hunter returns.

Result: FINDING. `stub-check.sh`'s own `CANON_GATES` manifest loop
(unchanged by this transition) still unconditionally flags any
`directive.sh` file as vendored drift, contradicting the very next block
in the same script — the structural `gate_is_role_directive_stub` call —
which correctly classifies the identical file as an "ok" sanctioned stub.
Full hunter report:
`docs/reports/2026-08-08-hunt-canon-duplication-stub-distinction.md`.

closed_checks:
- name: stub-check.sh two-loop contradiction on directive.sh
  code_under_review: (see frontmatter above)
  resolution: confirmed pre-existing, not introduced by this transition —
    both loops (the unconditional `CANON_GATES` filename match and the
    structural directive.sh check) already existed and already
    contradicted each other before this change (verified via `git stash`
    on the pre-change tree: `run-stub-canon-forms-tests.sh` fails
    identically, 1 passed/2 failed, on both trees — see this record's
    Verification run section). Out of scope for this proposal: the
    approved write set's `files:` list gives `compliance-check.sh`'s
    `--canon-duplication` mode the stub-aware exclusion (per the issue's
    acceptance text, which names that surface specifically) but does not
    extend it to `stub-check.sh`'s own first loop — extending it there is
    a second, separate decision (whether `stub-check.sh`'s absence-based
    manifest loop should also special-case `directive.sh`, duplicating
    logic its own second loop already has) not covered by the approved
    proposal's `## What will be done`. Not fixed here per the
    SCOPE-EXCEEDED rule (finish what the proposal covers, stop, report);
    candidate follow-up issue, not a blocker on this transition.

## next steps

None — this closes the issue's acceptance for this repo's write set. The
issue's second acceptance line (pilot repo re-scans clean, recorded on
#171) is out of scope for this proposal per its own Out-of-scope section
and belongs to #171's own session.

## resolution path

N/A — no open findings.
