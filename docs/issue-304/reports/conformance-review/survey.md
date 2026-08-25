# issue-304 — conformance-review current-state survey

## Scout skip record

Skip condition: **spec leaves no design decision open**. This is a
conformance-review pass, not a build — the verification methodology,
sampling criteria, verdict taxonomy, and record shape are all fixed in
advance by the mounted `conformance-review-*` skill set and the
role-handoff contract. There is no product/design choice to research
prior art for. Scouting (stage 1 sweep / stage 2 deepening / scout-brief)
is skipped in full; this line is the mandatory skip record.

Sampling-derivation skill: **not applicable, not invoked**. The issue's
own Acceptance section already states full enumeration ("for each of the
4 files"), not a sample — per requirement-extraction rule 4, a
already-stated derivation is used verbatim rather than re-derived, and
here the stated derivation is "all 4," which is small enough for full
inspection anyway. No stratification decision exists to make.

## Subject

Issue #304 (F19/F20 from the #301 sweep): `gate-lib.sh`'s
`gate_kill_switch_active` was already fixed (issue-72) to fail-active on
an unrecognized kill-switch value, but `role-directive.sh` and three
sibling `*-directive.sh` hooks (`proposal-shape-directive.sh`,
`record-shape-directive.sh`, `survey-order-directive.sh`) still carried
the pre-fix inline case statement, where a typo silently disabled the
hook. Ask: replace the 4 inline copies with the shared helper, add a
drift test.

Delivered by a separate role/session on branch `issue-304/implementation`,
now open as **PR #307** ("issue-304: propagate fixed
gate_kill_switch_active into 4 directive hooks (F19/F20)"), authored by
JiwonJung94, carrying a `Closes #304` trailer and
`docs/issue-304/reports/implementation.md` (loop_state: landed, verdict:
pass). That role used the build-now bypass (`CORE_BUILD_NOW=1`,
contract v3 s19a — its own record states this explicitly), so it
delivered directly with no phase-1 proposal round of its own. This
conformance-review session's own environment does **not** carry
`CORE_BUILD_NOW=1` (checked: empty), so the two-phase default applies
here regardless of what the implementation role did — phase 2 (the
actual review + this role's record) opens only after an Approve on
*this* role's PR.

## Requirement extraction (conformance-review-requirement-extraction applied)

Dimension-tagged, one-obligation-per-line, bundled clauses split:

1. [functional] `core/hooks/lib/role-directive.sh`: pre-fix inline
   kill-switch case statement replaced by a call to
   `gate_kill_switch_active`.
2. [functional] `core/hooks/proposal-shape-directive.sh`: same
   replacement.
3. [functional] `core/hooks/record-shape-directive.sh`: same
   replacement.
4. [functional] `core/hooks/survey-order-directive.sh`: same
   replacement.
5. [error-handling] A drift test exists that fails if the pre-fix
   hand-rolled off-spelling case branch (`*) exit 0 ;;` /
   `*) return 0 ;;`) reappears in any of the 4 files above.
6. [functional] Acceptance gate `core/hooks/tests/run-directive-shape-tests.sh`
   passes overall, re-executed independently by this review (not just
   trusted from the implementation record's pasted output).
7. [edge-case] (×4, one per file) empty state — kill-switch env var
   unset — hook stays active, unchanged from pre-fix baseline behavior
   on the active path.
8. [edge-case] (×4, one per file) a typo value in the kill-switch env
   var keeps the hook ACTIVE (previously: silently disabled — this is
   the actual bug being fixed).
9. [functional] (×4, one per file) the exact on-spelling `1` in the
   kill-switch env var disables the hook (regression check — fixing the
   typo case must not break the real off-switch).
10. [process/evidence] Acceptance provenance must be "executed-live" —
    an actual command and its real pasted output in the record, not an
    asserted/typed-up pass count. Applies to this review's own record
    too (verify-at-landing), not only to the implementation record.
11. [scope-boundary] **UNVERIFIABLE-AS-WRITTEN**: "no added
    overhead/load" (operator-frozen constraint) — no observable
    threshold or measurement is stated (overhead measured how, against
    what baseline, what counts as "added"). Will be recorded as
    Unverifiable rather than inventing a numeric bar.
12. [scope-boundary] **UNVERIFIABLE-AS-WRITTEN**: "no new
    conflict/stall surfaces" — same issue, no observable success
    condition given.
13. [scope-boundary] "systemic for every consumer session against any
    target repo; no consumer-tree residue" — cannot be executed against
    "any target repo" from inside this one repo. Checkable only as a
    proxy by Analysis: does the diff stay confined to this repo's own
    plugin tree (`core/hooks/**`) plus this role's own `docs/issue-304/`
    area, introducing nothing a consumer repo would need to carry
    itself?
14. [process] "unavoidable trade-offs measured and stated in the
    record" — checked by Inspection against
    `docs/issue-304/reports/implementation.md`'s own text.

Not listed as a checkable requirement: the issue's
`infrastructure/no-direct-requirement` tag is a classification label on
the issue itself (why no product/UX review dimension applies here), not
an obligation to verify.

## Verification method selection (conformance-review-verification-method-selection applied)

- Requirements 1–4, 6, 9: **Test** — `run-directive-shape-tests.sh`
  already covers these; per rule 4, reuse and re-execute it rather than
  hand-deriving a parallel manual check.
- Requirement 5: **Inspection** (the static joined-line grep guard,
  read directly) + **Test** (the drift test's own pass/fail line).
- Requirements 7–8: **Test** — same gate, the per-file
  unset/typo/on-spelling behavioral assertions.
- Requirement 10: **Inspection** of the implementation record's
  Acceptance evidence section, cross-checked against this review's own
  independent re-run.
- Requirement 11–12: stay **Unverifiable** — no realistic reproduction
  target for "overhead/load" or "conflict/stall surfaces" is stated;
  Analysis would require inventing the threshold the issue itself
  omits.
- Requirement 13: **Analysis** — trace the diff's file scope against
  the repo model; the multi-repo "any target repo" condition cannot be
  reproduced in this session (rule 2).
- Requirement 14: **Inspection** of the implementation record's prose.

## What phase 2 will actually do

Re-execute `core/hooks/tests/run-directive-shape-tests.sh` independently
(not trust the implementation record's pasted output alone), inspect the
4 changed hook files and the drift-guard regex, trace diff scope for the
consumer-tree-residue proxy, and record one verdict per requirement above
in `docs/issue-304/reports/conformance-review.md` using the existing
skeleton's frontmatter and headings — Present/Surface/Absent/Incorrect/
Unverifiable per requirement, with file/line/sha citations
(conformance-review-traceability-and-evidence).
