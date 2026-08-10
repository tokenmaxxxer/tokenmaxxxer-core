Subject: issue-189

# Current-state survey — rejection/withdrawal as a first-class lifecycle

## Background / context

The deployed surface (`core/`, `warrant/`) only encodes the positive path
end to end: a proposal moves `proposed -> approved -> landed`, a role's
record moves toward a terminal `loop_state`, an issue closes by merge. Every
one of those tracks has no symmetric negative branch. The live incident
(2026-08-10, `thaki-agent-security-controller`, issues #272/#270) is one
instance of that asymmetry: a proposal author wrote `status: withdrawn` —
a legitimate real-world act — and `warrant/hooks/scope-gate.sh`'s
`KNOWN_STATES = ("proposed", "approved", "landed")` (line 39) had no bucket
for it, so it fell into `malformed`, and the fail-closed posture (correct
for a genuinely unreadable file) stood the whole session's Bash/Read/Edit
down for a state that was never unreadable — it was just unmodeled.

on-the-record #573 is about to make this worse, not better: its
`verdict: contradicts` + `finding` + brokered-remediation architecture is a
rejection-issuing consumer, and it will call into a substrate that today has
no rejection vocabulary to call into.

## Problem stated without any solution attached (JTBD tuple)

- **Job performer**: an autonomous role session (product-discovery,
  architecture, implementation, qa, and #573's expert-review roles), and the
  human operator reading the board afterward.
- **Job**: register that a unit of work — a proposal, a review, an entire
  session — ended in a **negative** outcome (voluntarily withdrawn by its
  author, or refused by a reviewer/gate) in a form later steps and other
  sessions can mechanically read, the same way they already mechanically
  read `approved`/`landed`.
- **Circumstance**: work in this repository is deployed as *gates that
  parse fixed vocabularies* (`KNOWN_STATES`, the `APPROVE issue-<n>/<role>`
  token, `loop_state` enums) rather than as free text a human triages by
  eye; every one of those vocabularies today enumerates only the states a
  successful run passes through.
- **Desired outcome**: a negative outcome is exactly as legible to a gate,
  a downstream session, and the human as a positive one — no session dies
  from a state it cannot recognize, no rejection is only a `gh pr close`
  and a prose comment nobody downstream can parse, and #573's `verdict:
  contradicts` shapes have a substrate state to attach to instead of
  inventing their own.

The issue text as filed already names a solution shape (add `withdrawn`/
`rejected` tokens, a canonical rejection act, board vocabulary, issue
close-reason usage) — that is accepted per the issue's own sequencing
directive as the mechanism family for later steps, but this survey keeps
the problem stated independently of it: the job is "make a negative
outcome legible to the same machinery that already reads positive
outcomes," not "add these four specific fields." The four candidates are
evaluated as *candidate mechanisms* against that job, not assumed correct
because they were proposed.

## Opportunity-solution tree placement

- **Outcome**: rejection-driven work (voluntary withdrawal, reviewer
  refusal, gate-mediated no-go) does not brick, silently vanish, or become
  unparseable anywhere on the deployed surface — matching the legibility
  the positive path already has.
- **Opportunity**: the deployed surface's four state-carrying vocabularies
  (proposal `status`, approval act, role `loop_state`, GitHub issue/PR
  closure) each model only the positive branch of what is otherwise a
  binary (or ternary, with "still open") outcome space.
- **Candidate solutions** (not yet designed this step, per the issue's own
  "do not design mechanisms yet" instruction): (a) extend `KNOWN_STATES`
  with `withdrawn`/`rejected`; (b) a canonical machine-readable rejection
  act paired with the existing `APPROVE issue-<n>/<role>` token; (c) a
  `refused`/`rejected`-family addition to per-kind `loop_state` vocabulary
  in contract §2; (d) using GitHub's `state_reason` (`completed` vs
  `not_planned`) on issue/PR closure instead of closure alone.
- **Discriminating assumption test**: the one part of (a) that is not
  deferred — accepting `status: withdrawn` in `scope-gate.sh` — is
  specified below as the emergency-fix scope, because the consumer-repo
  blockage is a live incident, not a hypothesis to test first. The
  remaining candidates stay in "candidate solutions," pending the
  pre-registered hypothesis test in the next section.

## Scout: skip record

Skipped. Skip condition: for the audit itself, there is no design decision
open to scout — the four candidate gaps are graded against code already
deployed in this repository, not against an external field of comparable
products. For the one piece of code this step *does* touch (the
`KNOWN_STATES` emergency fix), the shape is fully fixed by the existing
tuple `scope-gate.sh` already defines (line 39) — adding one string to an
existing three-string tuple has no design decision an exemplar sweep could
inform. The lifecycle-wide mechanism design (candidates b/c/d above) is
explicitly deferred past this step, so there is nothing yet to scout either;
a re-scout trigger applies when that design step opens.

## Audit: full deployed surface, per-gap evidence and grading

Grading scale: **CONFIRMED** (reproduced/read directly in deployed code),
**REFUTED** (code contradicts the candidate), **PARTIAL** (mechanism
exists but is incomplete/inconsistent).

### Candidate 1 — proposal status vocabulary has no withdrawn/rejected

**CONFIRMED.** `warrant/hooks/scope-gate.sh:39`:
```
KNOWN_STATES = ("proposed", "approved", "landed")
```
Any `status:` value outside this tuple (and not `approved`) is appended to
`malformed` (lines ~139-146) and the gate refuses to stand down cleanly —
it prints a "cannot be read" refusal and `sys.exit(1)`, which is the exact
failure mode that bricked the consumer-repo sessions. `withdrawn` and
`rejected` are both plausible real-world proposal-author acts (voluntary
withdrawal; reviewer refusal recorded on the file itself) with no home in
this tuple.

### Candidate 2 — approval has a canonical token, rejection does not

**CONFIRMED.** `core/hooks/approval-gate.sh:258`: `challenge = "APPROVE
issue-%s/%s" % (issue_num, role)` is the one canonical machine-readable
grant. The same file (line 281) reads PR review states `("APPROVED",
"CHANGES_REQUESTED", "DISMISSED")` — but only to detect that a *prior*
approval was superseded/revoked (line 283's `pr_approved` check), never to
recognize `CHANGES_REQUESTED` as a first-class, independently meaningful
rejection act with a captured reason. No `REJECT issue-<n>/<role>` (or
equivalent) counter-token exists anywhere in `core/` or `warrant/`.
Separately, `core/hooks/gh-guard.sh:81,85` **denies role sessions from
ever issuing** `gh pr close/merge/reopen` or `gh issue close/reopen/edit`
themselves (contract-correct: those are human-only acts) — but that
means the *human's* refusal act (closing a PR, or leaving
`CHANGES_REQUESTED`) is still free-text/GitHub-native with no
project-defined canonical shape a gate parses, unlike `APPROVE
issue-<n>/<role>`'s exact-string contract.

### Candidate 3 — a session ending refused has no board loop_state

**CONFIRMED.** `core/contract/role-handoff-contract.md` §2's per-kind
`loop_state` vocabulary table (lines 64-87) enumerates only forward/
terminal-success states per kind (e.g. `idle,scoped,probing,verdict` for
feasibility; `hypothesis-registered,measuring,...,validated/invalidated/
inconclusive` for product, per this session's own role directives).
Grepping the full contract and every gate script for `refused`,
`rejected`, or `withdrawn` as a *loop_state value* (as opposed to a prose
word describing a gate's own denial) returns nothing — no kind's row
carries a refusal terminal. This directly matches on-the-record #476's
already-named finding class ("null results read as failure") cited in the
issue body: a role that stops because its work was refused has no
`loop_state` to write that isn't silence or an ad hoc value a downstream
gate won't recognize (`run-role-gates-tests.sh` enumerates the terminal
spellings it *does* accept — `landed, closed, done, complete,
phase_2_complete` — none of them mean "refused").

### Candidate 4 — issue closure doesn't distinguish completed vs rejected

**CONFIRMED, and broader than stated.** `core/hooks/gh-guard.sh:85`
denies role sessions `gh issue (create|close|reopen|edit|transfer|delete)`
outright — issue closure is deliberately human-only (correct: "Human
decisions are GitHub acts only," contract v3). But nothing in the deployed
surface *reads* GitHub's own `state_reason` field
(`completed`/`not_planned`) anywhere — `approval-gate.sh:240` checks only
`issue.state == 'open'`/`'closed'`, collapsing "shipped" and "abandoned"
into one bit. So the gap is not "roles should set close reason" (they
correctly cannot) — it's that **no downstream reader distinguishes the two
kinds of closed** even though GitHub already carries the distinction for
free. A role or gate resuming work, or #573's brokered remediation reading
issue history, cannot currently tell "this issue's proposal was accepted
and shipped" from "this issue was killed" without parsing prose.

### Additional gaps found (not in the issue's four candidates)

5. **`state.sh` open-unit reporting silently drops non-open, non-approved
   statuses.** (`warrant/hooks/state.sh`, the `if status in ("proposed",
   "approved")` filter, line ~46 in the embedded python.) Once `withdrawn`/
   `rejected` exist as valid `KNOWN_STATES`, a withdrawn proposal
   correctly stops appearing as an *open* unit — but nothing surfaces that
   it *was* withdrawn to a session starting fresh on that branch; the
   session simply sees no open units and has no record a prior attempt
   existed and why it stopped. **PARTIAL** — not broken by the emergency
   fix, but a legibility gap the full lifecycle work should close (a
   session re-approaching a subject after a withdrawal should be able to
   read that history, not just its absence).

6. **`deny-only-check.sh` and the board-gate forged-write tests already
   assume a closed loop_state vocabulary** (`core/hooks/tests/deny-only-
   check.sh:72` hardcodes `loop_state: scope-approved` as its forged-write
   probe). Extending the vocabulary with refusal states is safe against
   this test (it is a probe, not an enumeration gate) but confirms the
   test suite itself has no red/green pair yet for a `refused`-family
   `loop_state` — the full lifecycle work will need to add one, mirroring
   the existing terminal-spelling coverage in `run-role-gates-tests.sh`
   (lines 297-333). **CONFIRMED absence, not yet a defect** — flagged so
   step 2/3 don't have to rediscover it.

7. **`approval-gate.sh` treats `CHANGES_REQUESTED` and `DISMISSED`
   identically** (line 281's tuple, line 283's check) — both only ever
   revoke a prior grant. A reviewer who dismisses their own review isn't
   distinguished from one who explicitly requested changes, even though
   these are different human intents (soft withdrawal of opinion vs.
   active rejection). **PARTIAL** — worth folding into the canonical
   rejection-act design (candidate 2's fix) rather than treated as a
   separate mechanism.

### Not confirmed as gaps

No surface was found where the audit *refutes* one of the issue's four
candidates — all four are real, reproducible gaps in currently deployed
code, evidenced above with file:line citations.

## Alignment constraint check — on-the-record #573

#573 is out-of-repo (a different subject repo) and not fetchable here, so
this survey records the constraint as stated in the issue rather than
re-deriving it: #573's merged architecture defines `verdict: contradicts`
+ an actionable `finding` object, write_scope-routed remediation records,
and issue-timeline rejection events, and this issue's vocabulary/token/
board work is the substrate those surfaces are expected to consume, not a
parallel invention. Concretely, that means: whatever `loop_state` refusal
value(s) get added under candidate 3 should be nameable from a `verdict:
contradicts` result without #573 inventing its own parallel state; and
whatever canonical rejection token/act gets designed under candidate 2
should be usable as the act that *produces* a `finding` object, not a
second finding-shaped record living beside it. This is a naming/shape
constraint on step 2 (architecture), not something this survey can verify
against #573's actual merged code from inside this repo.
