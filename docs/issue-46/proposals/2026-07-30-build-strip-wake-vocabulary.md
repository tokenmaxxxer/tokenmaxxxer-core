---
kind: build-proposal
subject: issue-46
produced_by: coding
loop_state: proposed
upstream:
  - path: docs/issue-46/reports/coding/survey.md
    sha: <set at commit>
---

## Request

Remove the wake/WAKES-ON vocabulary and the dangling
`docs/specs/wake-routing.md` pointers from
`core/contract/role-handoff-contract.md`, replacing them with prose that
states routing ("which role runs next") is the orchestrating session's
judgment, made by reading board records (`loop_state` and the rest of
this contract's record format) directly — never an encoded table. Record
FORMAT/STATE semantics (the `loop_state` vocabulary itself, section 7's
authority rule, section 19's `scope-proposed`/`scope-approved` mechanics)
are unchanged.

`protocol.md`/`protocol.ko.md` (issue item 1) live in the `on-the-record`
repo, not here — out of scope for this proposal; see survey's "Scope
check". This proposal is item 3's part of the issue: the wake references
inside `tokenmaxxxer-core`'s own contract.

## Constraints

- Scope is `core/contract/role-handoff-contract.md` only.
- Keep every structural fact this contract states — a role's contract
  entry still names when its loop is triggered, a `finding` still reaches
  its `addressed_to` role, the round-end/approval edges are still
  human-consulted-not-automated. Only the *routing-mechanism* naming
  (`WAKES-ON` table, `docs/specs/wake-routing.md`) and the "wake" word as
  the event's name are removed.
- Do not invent a new routing mechanism or doc to replace
  `wake-routing.md` — the issue is explicit that routing is the
  orchestrator's judgment call, not a table.
- `README.md:26`'s one informal "wakes" mention is out of scope for this
  proposal (not part of the live contract surface item 3 names); left for
  a future prose sweep if the human wants it.

## What will be done

files: `core/contract/role-handoff-contract.md`

- [ ] Section header/intro (lines 11, 82-95, section 3 title): reword
  "wakes from" / "Each role's loop wakes when..." / "the by-role WAKES-ON
  routing table — is the host's (on-the-record's) concern, documented and
  enforced at `docs/specs/wake-routing.md`" to state a role's loop enters
  when the board reaches a trigger condition, and which role enters is the
  orchestrating session's judgment from reading the board directly — no
  table, no host-doc pointer. Rename section 3's title away from "routing
  lives at the host".
- [ ] Lines 97-114 (who evaluates state changes; round-end and pre-work
  approval-gate edges): reword "reads the board against the host's
  routing rules and opens the role that rule names" to "reads the board
  and opens the role its judgment names"; keep "human (or a future
  automated watcher...)" and every human-consulted-never-automated
  statement verbatim — only the routing-table clause changes.
- [ ] Lines 150, 163-164, 172 (ux-design/verify/reflect DEPENDS-ON
  entries): drop "its WAKES-ON edge, routed per
  `docs/specs/wake-routing.md`"; keep "a `<kind>` exists per subject" and
  restate that when it acts is the orchestrator's call, not this
  contract's.
- [ ] Lines 188-189 (finding back-edge, section 5): drop "part of that
  role's WAKES-ON triggers, routed per `docs/specs/wake-routing.md`";
  state findings addressed to a role are visible on the board for the
  orchestrator to act on.
- [ ] Lines 200-224 (loop termination, section 6, qa/verify cycle
  termination): reword every "wake" occurrence to "role-entry" / "entry"
  (e.g. "A wake is consumed by..." -> "A role-entry is consumed by...";
  "may wake the next role per `docs/specs/wake-routing.md`" -> "may
  prompt the orchestrator to open the next role"); keep the termination
  logic (what counts as a valid consumption) unchanged.
- [ ] Line 234 (section 7, `loop_state` authority): reword "no other
  role's WAKES-ON check can see it" to "no other role, or the
  orchestrator reading the board, can see it".
- [ ] Line 310 (section 10): reword "A role wakes, checks out `main`..."
  to "A role enters, checks out `main`...".
- [ ] Line 339 (section 10, "the board is what is merged"): reword
  "WAKES-ON (section 3) evaluates against `main`..." to "Routing
  judgment (section 3) is made against `main`...".
- [ ] Line 487 (section 14): reword "WAKES-ON and DEPENDS-ON filter on the
  declared value only" to "Routing judgment and DEPENDS-ON both read the
  declared value only".
- [ ] Line 497 (section 14): reword "a passing structural check (kind
  matched, sha matched, wake fired)" to "(kind matched, sha matched, the
  role entered)".
- [ ] Line 525 (section 15): drop "is the host's (on-the-record's) concern
  — see `docs/specs/wake-routing.md`"; state it is the orchestrator's
  judgment call, same as section 3.
- [ ] Lines 707-711 (section 19, "Re-wakes are unaffected"): reword to
  "Later entries are unaffected" / "A later role-entry on a subject
  whose PR already carries the Approve...".
- [ ] Verify: `grep -niE "wake" core/contract/role-handoff-contract.md`
  after the edit returns zero hits.

## Out of scope

- `protocol.md`/`protocol.ko.md` in the `on-the-record` repo (issue item
  1) — different repo, different issue.
- `README.md:26`'s informal "wakes" mention.
- Any rulebook that adopts this contract (separate proposal per repo,
  per the contract's own header).
- Inventing a replacement routing doc/table — explicitly against the
  issue's stated direction.

## How you'll know it worked

`grep -niE "wake" core/contract/role-handoff-contract.md` returns no
matches, while every structural fact currently expressed via "wake"
language (trigger conditions, findings visibility, human-consulted edges,
loop termination rules) is still stated, just without wake/WAKES-ON
naming or a pointer to the now-nonexistent `docs/specs/wake-routing.md`.

## Alternatives considered

- **Also file/edit `protocol.md`/`protocol.ko.md` in the on-the-record
  repo from this session.** Not chosen: contract v3 s9/s10 bind a role
  session to its own issue's branch/tree in the one target repo it was
  opened against; this session was opened against `tokenmaxxxer-core`,
  not `on-the-record`. Cross-repo writes are a different issue, filed
  separately.
- **Replace `WAKES-ON`/wake-routing.md pointers with a new named
  mechanism (e.g. "orchestration contract") instead of plain prose.** Not
  chosen: the issue explicitly frames routing as "오케스트레이터의 판단"
  (judgment, not a mechanism); inventing a new named layer would
  reproduce the exact problem being removed under a different name.

## Failure signal

If a future contract change reintroduces a routing-table pointer (a new
`docs/specs/*.md` reference naming which role a state summons) without a
corresponding update here, `grep -rn "wake-routing\|WAKES-ON"
core/contract/role-handoff-contract.md` returning a hit is the concrete
signal this proposal's removal did not hold.
