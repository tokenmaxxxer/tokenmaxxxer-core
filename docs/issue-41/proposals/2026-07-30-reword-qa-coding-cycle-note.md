## Build proposal — issue #41

files:
- `core/contract/role-handoff-contract.md` (lines 206-208 only)

### Request (paraphrased)

The qa↔coding cycle-termination bullet still names "qa" as who gets woken
and cites section 3 for the routing, but section 3 no longer holds a
routing table (removed under #36). Reword so the bullet keeps its
termination semantics without naming which role gets woken, and repoint
to the host's `docs/specs/wake-routing.md` — the same pattern #36/#38
already applied to every other routing-shaped mention in this file.

### Constraints

- One file, few-line change (lines 206-208).
- Keep the termination semantics intact: a wake that produces no new
  board change ends the cycle.
- `docs/proposals/*` historical records untouched.
- `docs/specs/wake-routing.md` itself untouched (host repo/role owns it).
- Do not touch the verify↔coding termination bullet (section 6, ~217+) —
  out of scope for this issue.

### What will be done

Replace:

> A `finding` from qa produces a `finding-response` from coding; coding's
> fix produces a new commit, which wakes qa again per section 3. This
> cycle terminates when a wake produces no new board change...

with wording that keeps "a `finding` from qa produces a
`finding-response` from coding; coding's fix produces a new commit" (the
factual, self-contained description of the two named participants stays,
since #38 already judged that part is not a routing pointer), but drops
"wakes qa again per section 3" and instead says the commit produces a
board change that may wake the next role per `docs/specs/wake-routing.md`
— without naming which role. The rest of the bullet (the termination
condition itself: qa observes the fix and either verifies it or re-opens
with a new finding) is left as-is, since it already only names qa in its
role as this bullet's other explicitly-named participant, matching how
#38 treated the surrounding named-participant language.

### Out of scope

- Any other file.
- The verify↔coding termination bullet.
- Editing `docs/specs/wake-routing.md`.
- Any code execution — this is a phase-1-only proposal per contract
  discipline; phase 2 (the actual edit) waits for the approver's APPROVE.

### How you'll know it worked

After phase 2: `grep -n "wakes qa again per section 3"
core/contract/role-handoff-contract.md` returns nothing; the bullet still
reads as a complete, self-consistent termination rule when read in
isolation; `grep -n "wake-routing.md" core/contract/role-handoff-contract.md`
shows one more hit than before.
