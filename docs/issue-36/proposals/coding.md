# Build proposal — issue-36

subject: issue-36
role: coding

## Request (paraphrased)

Strip "which role wakes next" routing content out of the canonical
contract (`core/contract/role-handoff-contract.md`), leaving routing
ownership with the host (on-the-record, `docs/specs/wake-routing.md`,
step 1 of this migration already landed there). Keep the contract
self-sufficient about record FORMAT and STATES. Contract-text-only.

## Constraints

- Single file write surface: `core/contract/role-handoff-contract.md`.
- No behavioral change — text only.
- Section 3's concurrency-is-normal and human-consulted properties
  must survive as protocol properties, not be deleted along with the
  table.
- Section 15 keeps record semantics (`resolved_findings`,
  `finding-response`, `findings-resolved` state); only its routing
  sentence goes.
- Section 19's approval gate stays; routing-enumeration phrasing (if
  any) defers to the host doc.
- README repointed if it restates the table (surveyed: it does not).

## What will be done — clause checklist

1. Replace section 3's WAKES-ON table (`role-handoff-contract.md:88-98`)
   with a short paragraph stating: records carry the `loop_state`
   values defined in this contract; which role a given state summons
   is the host's (on-the-record's) concern, documented and enforced at
   `docs/specs/wake-routing.md`.
2. Keep section 3's intro sentence on concurrent wakes being the normal
   case (`:82-86`), rephrased only enough to stop presupposing the
   table.
3. Keep the "Round-end value-gates edge" and "Pre-work approval-gate
   edge" paragraphs (`:116-126`) as human-consulted-judgment-point
   descriptions; strip any "wakes the human" phrasing that reads as a
   routing claim rather than a gate description, keeping the gate
   itself.
4. Remove the "Resolved-finding re-verify edge" paragraph (`:100-105`)
   from section 3 (routing content); do not relocate its prose here —
   the host doc already carries this edge per the issue.
5. Rewrite the "Who evaluates these rows" paragraph (`:107-114`) so it
   no longer refers to "the table above" — state plainly that a human
   (or future watcher) reads the board against the host's routing
   rules, not against a table in this document.
6. In section 15 (`:507-537`), delete the "Wake edge" bullet's routing
   sentence ("The finder is re-woken to re-verify, per section 3's
   resolved-finding edge") while keeping the finding-raised ->
   findings-resolved state-transition sentence and the human-consulted
   property.
7. Confirm section 19 needs no routing-phrasing strip (surveyed: none
   found) — leave it untouched beyond any incidental cross-reference
   fix from clause 8.
8. Fix cross-references to section 3's old content (`:104, 110, 162,
   174, 183, 199, 244, 249, 345, 493`) so none of them point at deleted
   table rows or the removed re-verify-edge paragraph; section-number
   pointers that only say "see section 3" need no edit.
9. README.md: surveyed, no WAKES-ON table restatement found — no edit
   required; state this explicitly in the coding record rather than
   silently skipping.

## Out of scope

- The nine rulebooks' own WAKES-ON restatements (issue names this as a
  separate follow-up).
- Any change to `docs/specs/wake-routing.md` itself — that file lives
  in the host (on-the-record) repo, not here.
- Any behavioral/tooling change (no code, no tests).

## Alternatives considered

1. **Leave a condensed WAKES-ON table in section 3 alongside the
   host-doc pointer**, instead of removing it outright. Not chosen:
   a condensed table would drift from the host's table over time and
   recreate the dual-source-of-truth problem step 1 of this migration
   was meant to close.
2. **Move section 15's re-verify sentence into section 3's new
   paragraph instead of deleting it outright.** Not chosen: the issue
   is explicit that host doc already carries this edge; keeping any
   copy in the contract reintroduces the two-copies drift risk this
   issue exists to remove.

## Failure signal

If this proposal is wrong, the observable signal is: a future reader
of the contract alone (no host-repo access) cannot answer "does a
`findings-resolved` state cause a re-wake" from this document, and
wrongly concludes there is no re-verify mechanism at all — i.e., the
contract stops being self-sufficient about record FORMAT/STATES, which
is the one property this issue requires preserving.

## How success will be judged

- `grep -n "WAKES-ON"` against the edited file shows no table rows and
  no by-role enumeration remaining, only section/property references.
- Section 3, 15, and 19 each still parse as complete sections (no
  dangling cross-references to deleted content).
- The contract still states, self-sufficiently, what `loop_state`
  values exist and what a `findings-resolved` state means, without
  needing the host doc to explain the states themselves — only who
  gets woken by them.
