---
kind: coding-survey
subject: issue-38
produced_by: coding
loop_state: surveyed
---

# Current-state survey: residual WAKES-ON/routing prose in role-handoff-contract.md

## Scope

Issue #38 is the step-2 follow-up to #36 (which removed section 3's
by-role routing table and section 15's routing edge, repointing both to
`docs/specs/wake-routing.md`; see `f0de33c`, `6f32860`). This survey covers
every remaining WAKES-ON/wake/routing mention in
`core/contract/role-handoff-contract.md` on `main` as of `19a953e`, outside
the #36 write set (section 3 and section 15), and classifies each as
pure record/visibility semantics (keep) or role-summoning prose (strip or
repoint).

## Method

`grep -n "WAKES-ON\|wakes\|Wakes\|wake"
core/contract/role-handoff-contract.md` (evidence: full match list below,
each line inspected in context).

## Findings (line numbers as of `19a953e`)

| line(s) | text | classification | evidence |
|---|---|---|---|
| 11, 82, 84, 104, 106, 110, 112 | "wakes from" / "loop wakes" / round-end and pre-work gate edges | pure record/visibility semantics — these describe the record's own state machine and the human-consulted gate edges (section 8's judgment seat), never which OTHER role answers | core/contract/role-handoff-contract.md:11,82,84,104,106,110,112 |
| 91-93 | "Which role a given state summons — the by-role WAKES-ON routing table — is the host's... concern" | already repoints to host (this is #36's own repointer text, section 3 header) | :91-93 |
| **150** | ux-design DEPENDS-ON entry: "its WAKES-ON edge after product, and that it feeds coding on reaching `loop_state: reviewed`" | **role-summoning** — names ux-design's predecessor (product) and successor (coding) by name | :149-151 |
| **162-163** | verify DEPENDS-ON entry: "its WAKES-ON edges, and a blocking-finding channel back to coding" | **role-summoning** — "back to coding" names the destination role | :161-164 |
| **171** | reflect DEPENDS-ON entry: "its WAKES-ON edge after verify/review conclude" | **role-summoning** — names reflect's predecessors (verify, review) by name | :169-171 |
| **187** | finding back-edge section: "The addressed role's WAKES-ON list covers findings addressed to it (each row in section 3 already includes its role's finding trigger)" | **stale + role-summoning-adjacent** — cites section 3's per-role rows, which #36 deleted; the "each row" no longer exists, so this is also now a factual error, not just a routing leak | :187-188 |
| 199-217 | loop-termination prose ("a wake is consumed", "wakes qa again per section 3", qa/verify cycle termination) | pure record/visibility semantics — describes what constitutes consumption of a wake already received, not who is summoned; "wakes qa again per section 3" is a factual statement about the qa↔coding cycle's own two participants (both named by the section itself, not by a routing table) and section 3 no longer names a destination for it either — kept as-is | :199-217 |
| 232 | "no other role's WAKES-ON check can see it" | pure visibility semantics — no role named | :232 |
| 253 | "before any building role's first wake on that subject" | pure gate-sequencing semantics — no role named | :253 |
| 308 | "A role wakes, checks out main, works on its own branch" | pure per-role mechanical description, generic to all nine roles, no destination named | :308 |
| 334 | "WAKES-ON (section 3) evaluates against main plus the issue backlog" | pure record/visibility semantics — repoints by reference to section 3, which already repoints to the host doc | :334 |
| 482 | "WAKES-ON and DEPENDS-ON filter on the declared value only" | pure record/visibility semantics | :482 |
| 492 | "wake fired" | pure record/visibility semantics | :492 |
| 520-522 | section 15: "Who gets woken by `findings-resolved` is the host's... concern — see `docs/specs/wake-routing.md`" | already repointed (#36 write set) | :518-522 |
| 700-701, 814 | "re-wakes", "wake" (handbook write-time) | pure record/visibility semantics, no role named | :700-701, 814 |

## Unknowns

None — every WAKES-ON/wake/routing occurrence in the file was enumerated
by the grep above and classified; no occurrence was left unclassified.

## Conclusion

Four sites carry role-summoning prose outside the #36 write set: lines
150, 162-163, 171, and 187 (the last also factually stale, citing a
section-3 table #36 already removed). All four sit in section 4's
DEPENDS-ON entries and section 5's finding back-edge, describing what a
role's own contract entry enforces "structurally" — the fix is to keep
the structural requirement (a WAKES-ON edge/channel must exist) while
repointing the WHICH-ROLE detail to `docs/specs/wake-routing.md`, mirroring
the pattern #36 already established at lines 91-93 and 520-522. No other
line in the file needs to change.
