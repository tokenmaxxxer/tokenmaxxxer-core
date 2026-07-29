## Current-state survey — issue #41

Scout skip: pure textual reword of one already-decided pattern (repoint to
`docs/specs/wake-routing.md`, established by #36/#38) — no design decision
open. Skip condition: "spec literally leaves no design decision open."

### Write set

- `core/contract/role-handoff-contract.md:206-208` — the qa↔coding
  cycle-termination bullet. Current text: "coding's fix produces a new
  commit, which wakes qa again per section 3." Names the role (qa) and
  cites section 3, which no longer holds a routing table (removed under
  #36). This is the last residual routing phrase the #38 sweep
  deliberately left as-is (`docs/issue-38/reports/coding/survey.md:37`),
  reasoning it was a factual statement about the cycle's own two named
  participants rather than a routing pointer — issue #41 overrides that
  call and asks for the reword anyway.

### Prior art in this repo (#36, #38)

- #36 established the pattern: strip WHICH-ROLE detail from this contract,
  repoint to the host's `docs/specs/wake-routing.md`
  (`docs/issue-36/reports/coding.md:20`).
- #38 applied the same repoint at four other sites (lines ~91-93, 518-522,
  etc. — see `docs/issue-38/reports/coding.md:28-54`), leaving lines
  206-208 untouched as the one deliberate exception.
- `docs/specs/wake-routing.md` itself lives in the host repo/role, not
  here — never edited by this role (confirmed: `git show
  main:docs/specs/wake-routing.md` → does not exist in this repo).

### What changes, what doesn't

- Changes: the clause naming "qa" as who gets woken and citing "section 3"
  → replaced with a repoint to `docs/specs/wake-routing.md`, keeping the
  termination semantics (a wake producing no new board change ends the
  cycle) intact.
- Unchanged: `docs/proposals/*` historical records (per issue text);
  section 217's verify↔coding termination bullet (issue names only the
  qa↔coding bullet at 206-208); `docs/specs/wake-routing.md` itself.
