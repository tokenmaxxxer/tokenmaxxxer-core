---
subject: issue-56
role: implementation
loop_state: scope-proposed
---

# Scout brief — issue #56

**Scope note.** This deliverable is not product-shaped: it is a
consistency fix inside this project's own governance contract. Per the
role directive ("non-product roles scout the best of their own
deliverable's kind"), the field scouted is this project's own prior art —
the codebase, its immediate ecosystem (`on-the-record`), and precedent set
by the most recent issue touching the same contract section (#53/PR#54) —
not external products; there is no market segment for a role-handoff
contract's approval gate. No web search was run.

**Mode.** Single inline pass, not a parallel fan-out. Each lookup (locate
the sentence, read the gate's approval logic, read `ensure_pushed`, check
`docs/decisions/`) resolved in 1-2 direct reads/greps — under the sweep's
own scale gate for "angles needing sustained digging." 1 stage used of the
5-stage budget; wall-clock well under the 3-minute cap.

## Must-bes, from #53/PR#54's own precedent

- A phase-1 proposal for a contract-text change states the exact replacing
  prose inline (not "will update s19" — #53's proposal quoted full
  replacement paragraphs verbatim).
- A decision genuinely gated by section 21 ("hard-to-reverse choice, named
  alternative") gets its `docs/decisions/` entry in **phase 2**, alongside
  the code/prose change — not authored down to the exact path during
  phase 1 (#53's proposal explicitly deferred this).
- Any acceptance criterion expressible as a mechanical check (`rg -n
  "..." path` returning an exact count) is stated as that check, not as
  prose describing the intent.

## Performance axes this kind of fix is judged on

1. **Guarantee strength preserved vs. simplicity/regression risk.** #53
   itself chose simplicity (move the signal, accept the two-PR gap) over a
   more defensive design in one place: it added the issue-state
   precondition only after a warrant-hunt pass caught a gap in the
   originally-drafted design (see `docs/reports/2026-07-30-hunt-issue-comment-approval-scope.md`),
   i.e. the precedent is "close a gap when a hunt finds it forces a real
   guarantee to break," not "add every possible precondition preemptively."
2. **Consistency across duplicate sites.** The survey found the same false
   sentence in two places (`role-handoff-contract.md` and
   `approval-gate.sh`'s header). #53's own precedent (moving "never the
   issue" language) touched the contract text only where it appeared,
   checked with `rg -n "never the issue" core/contract/` — the acceptance
   criterion was phrased to guarantee zero remaining hits, not "the one
   place named in the issue."

## Adopt

Mirror #53's own resolution shape for an identical situation: state the
trade-off in prose (what enforcement is retired, why, what replaces it),
verified by a `rg` acceptance check that the retired claim leaves zero
occurrences — rather than re-opening gate logic that #54 shipped and
tested two days prior for a severity the issue itself rates "moderate, not
a hole."

## Skip

Do not add a new mechanical precondition (Option 1's "branch has ever had
a PR") as the default move just because it is more defensive. The survey
found it requires a third `gh` call, a new stub dimension, and an edit to
an already-passing, two-day-old test (`issue-comment-approved-no-pr`) —
disproportionate to a severity the issue itself has already downgraded,
and it re-litigates a design #53 just closed rather than documenting the
trade-off #53 already made deliberately.

## Gap line

What the current state already meets: the *behavior* the issue describes
(work-then-PR ordering, unconditional merge gate) is real and already
shipped by #54 — nothing here is broken code. What is missing: the
contract's own prose (`s19`) and its mirror in `approval-gate.sh`'s header
comment still assert an enforcement that code no longer performs. The gap
is entirely textual, not behavioral — which is what points the proposal
toward Option 2 rather than a code change.

## One pattern to adopt, one to skip, restated as a rule

- Adopt: when a contract clause is proven false by working, tested code,
  fix the clause to describe the code — don't add code to make the old
  clause true again, unless the old guarantee was load-bearing for
  something the new code actually needs. It isn't here (section 2 above:
  nothing currently depends on "no PR has ever existed" being denied).
- Skip: don't let "state the trade-off" quietly become "restore the old
  behavior" — the issue title says trade-off, and #53's own PR body
  already named this exact clause as deliberately left for later, not as
  an oversight to reverse.

Sources: `core/contract/role-handoff-contract.md:755-763`,
`core/hooks/approval-gate.sh:7-11,253-294`,
`core/hooks/tests/run-approval-gate-tests.sh:46-47,125`, PR #54 body
(`gh pr view 54 --json body`), `docs/issue-53/proposals/issue-comment-approval-scope.md`,
`docs/issue-53/reports/coding/survey.md`, `on-the-record/spawn.py:2284-2328`
(`/Users/jk/workspace/10_WORK/tokenmaxxxer/on-the-record/spawn.py`).
