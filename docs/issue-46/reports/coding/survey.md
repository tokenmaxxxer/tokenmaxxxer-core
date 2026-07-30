---
kind: coding-record
subject: issue-46
produced_by: coding
loop_state: proposed
upstream: []
---

# Current-state survey — issue-46

## Scope check (before the sweep)

The issue's item 1 names `protocol.md`/`protocol.ko.md` as targets. Those
files do not exist anywhere in this repository (`git ls-files | grep -i
protocol` returns nothing); they live in the `on-the-record` repository
(confirmed at `/home/jwjung/tokenmaxxxer/on-the-record/protocol.md`, a
different git repo with its own issue tracker and branch). This coding
session is scoped to `tokenmaxxxer-core` on branch `issue-46/coding` only —
contract v3 s9/s10 bind a role session to one issue's branch/tree in one
target repo. Editing `protocol.md`/`protocol.ko.md` is therefore **out of
scope for this proposal**; it is a separate issue against the
`on-the-record` repo. This proposal covers item 3 only: the wake references
that live inside this repo's own contract, which is exactly what item 3
asks the survey to enumerate.

## Skip record (scout-directive)

Scouting skipped — bugfix-shaped: this is a literal-text removal of a
now-dangling reference, following the established pattern of two prior
rounds in this same repo (issue-36's `docs/issue-36/proposals/coding.md`
introduced the `docs/specs/wake-routing.md` repoint; issue-38's
`docs/issue-38/proposals/2026-07-30-build-strip-residual-wake-routing.md`
extended it to the remaining sites). No product-shaped or design decision
is open here; the issue text and prior precedent fully determine the
edit shape.

## Sweep: every `wake`/`WAKES-ON` hit in this repo

`grep -rniE "wake" core/ README.md freelunch/ scout/ terse/` (docs/
excluded — those are per-issue records, not live contract surface) finds
hits in exactly two places:

- `README.md:26` — one descriptive line, "a role wakes on an issue" —
  informal restatement, not a routing mechanism.
- `core/contract/role-handoff-contract.md` — the entire live surface. 84
  matching lines. `core/hooks/` and its `tests/` (gh-guard, approval-gate,
  board-gate) have zero wake references — confirmed no gate or test
  encodes routing logic.

`docs/specs/wake-routing.md` (the file `role-handoff-contract.md` points
to 4 times) does not exist in this repo (`find docs/specs -iname
"*wake*"` returns nothing) — it was always the *host's* doc (on-the-record),
never checked into `tokenmaxxxer-core`. Now that on-the-record #120 deleted
the wake system including that doc, every one of those 4 pointers is a
dangling reference to a file that no longer exists anywhere — this is
exactly the failure signal issue-38's proposal named in its own "Failure
signal" section, now realized.

## Classification of the 84 hits in `role-handoff-contract.md`

**Group A — names `docs/specs/wake-routing.md` directly (dangling, must
change).** Lines 93, 150, 164, 172, 189, 209, 525 (7 sites): each states
"routed per `docs/specs/wake-routing.md`" or equivalent. Per issue item 1's
principle ("다음에 어느 역할이 도는지는 오케스트레이션 대화가 보드 기록을
직접 읽고 내리는 판단"), these become "the orchestrating session's
judgment, reading the board records directly" — no host-doc pointer, no
routing table.

**Group B — `WAKES-ON` as a named mechanism/table (must change).** Lines
91 ("the by-role WAKES-ON routing table"), 150, 164, 172, 188, 234, 339,
487, 497 (9 sites): describes a structural routing table/check. Becomes
prose about the orchestrator reading `loop_state` and other board fields
directly — no named table.

**Group C — "wakes"/"wake" as the generic verb for "a role's loop is
triggered to act" (must reword, per item 1's "wake 잔재 제거").** Lines 11,
82, 84, 97-102, 104-107, 109-114, 200-224 (qa/verify cycle termination,
~10 sites), 310, 707-711 (~28 sites total): uses "wake(s)" as the event
name itself, inherited from the removed `spawn.py wake` vocabulary. Per
item 2 ("record semantics stay — 없어지는 것은 '무엇이 누굴 깨우나'
계층뿐"), the underlying fact — a role's loop enters/runs when the board
reaches a trigger condition — is NOT being removed, only its "wake"
naming and any implication of an encoded routing layer. Reword to
"enters"/"runs"/"acts on" throughout; keep every state name
(`scope-proposed`, `round-done`, etc.) and every human-consulted-not-
automated statement verbatim.

**Group D — pure record/loop_state semantics, no rewording needed.**
Section 2's `loop_state` column header and vocabulary lists, section 7's
"`loop_state` authority" title and body (the one non-`WAKES-ON` sentence
at line 234 aside, already counted in Group B), section 19's `loop_state:
scope-proposed`/`scope-approved` mechanics. These stay as-is — they define
record FORMAT and STATE values, not who gets triggered by them, which is
exactly the layer item 2 says survives.

## Unknowns

- Whether a future automated watcher (section 3's "or a future automated
  watcher, if one is built") should still be named as a future
  possibility, now that the wake-routing table it would have consulted no
  longer exists as a concept. Flagged as an open call for the proposal,
  not resolved here.
