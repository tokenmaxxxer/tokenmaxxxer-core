# Current-state survey — issue-36

subject: issue-36
role: coding

## Scope of the write surface

Single file: `core/contract/role-handoff-contract.md`. No code, no tests,
no config — contract-text-only, matching the issue's stated scope.

## Scout skip record

Skip condition: the deliverable is a textual edit to an internal
governance document, not a product-shaped surface — there is no
category of best-in-class external product to scout against. The
issue also names its own precedent directly (on-the-record#95/PR#96,
`docs/specs/wake-routing.md`), which is the only comparable prior art
and is already fully specified in the issue text. Scouting skipped;
this is the one-line reason.

## Surfaces the proposal will write to, with evidence pointers

- **Section 3 "WAKES-ON: who wakes when the board changes"**
  (`core/contract/role-handoff-contract.md:80-126`). Contains:
  - the WAKES-ON table itself, one row per role
    (`role-handoff-contract.md:88-98`).
  - "Resolved-finding re-verify edge" paragraph
    (`role-handoff-contract.md:100-105`) — the finder re-wakes on
    `findings-resolved`. This is the piece the issue says moves to the
    host doc; section 15 keeps the *record* semantics
    (`resolved_findings`, `findings-resolved` state) — only the
    "who gets woken" sentence goes.
  - "Who evaluates these rows" paragraph (`:107-114`) — describes a
    human reading the table; needs to become host-doc-agnostic.
  - "Round-end value-gates edge" and "Pre-work approval-gate edge"
    paragraphs (`:116-126`) — these describe *when* a human is
    consulted (value gates, approval gate), not *which role* is woken.
    The issue's instruction to keep "concurrency is normal" and
    "human-consulted" as protocol properties applies to these two
    paragraphs as well as the intro (`:82-86`).

- **Section 15 "Finding-resolution handshake"**
  (`role-handoff-contract.md:507-537`). The "Wake edge" bullet
  (`:529-533`) states the finder-re-wakes-on-`findings-resolved` rule
  redundantly with section 3's paragraph above. Issue: record
  semantics (finding record, `resolved_findings` list, `finding-response`
  entry, `findings-resolved` `loop_state`) stay; only the routing
  sentence ("The finder is re-woken... per section 3's resolved-finding
  edge") goes.

- **Section 19 "Pre-work approval gate"**
  (`role-handoff-contract.md:637+`). Confirmed by grep: no WAKES-ON
  table restatement or role-enumeration inside section 19's own text —
  the approval gate (`scope-proposed` -> human review -> `scope-approved`)
  is stated as a state transition, not as "who gets woken." No routing
  phrasing found here to strip; the issue's instruction ("keep the gate,
  defer routing phrasing to host doc") is already close to true and
  needs only a defensive check, not a rewrite. **Unknown until edit
  time:** section 19 does say elsewhere (`:657` "opens the PR") — not
  a routing claim, no change needed.

- **Cross-references to "WAKES-ON" / section 3 elsewhere in the same
  file** (`grep -n WAKES-ON`): lines 104, 110, 162, 174, 183, 199, 244,
  249, 345, 493. Each is a pointer ("see section 3") or a structural
  claim ("verify's WAKES-ON edge exists") rather than a restatement of
  the table's rows — surveyed individually; none needs edits beyond
  the section-3 rewrite itself, since they cite the section by number,
  not by content. Confirmed no other section quotes routing rows
  verbatim.

- **README.md**: `grep -n "WAKES-ON|wake"` — one hit at `README.md:26`,
  generic phrasing ("A role wakes on an issue, works on branch..."),
  not a restatement of the table or a claim about routing ownership.
  No repoint needed there; documented as an unknown resolved to "no
  change."

- **docs/issue-12/reports/coding.md:65** — a past role's own record
  mentioning "the standard WAKES-ON table." This is another role's
  report file, out of this role's write ownership (contract v3 s10
  NEVER-OVERWRITE); left untouched.

## Unknowns

- Exact section-3 heading text after the rewrite (issue does not
  dictate one). Resolved at build time as
  "## 3. Record states; routing lives at the host" or similar —
  a wording choice, not a design decision requiring approval.
- Whether `docs/specs/wake-routing.md` exists in *this* repo. Checked:
  it does not (`find docs/specs` shows only `approvers.md`); the issue
  confirms it lives in the host (on-the-record) repo, not here — the
  contract will reference it by that path without asserting it exists
  locally.
