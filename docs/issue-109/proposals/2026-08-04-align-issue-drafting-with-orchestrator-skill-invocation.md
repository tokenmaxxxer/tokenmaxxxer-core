---
kind: build-proposal
subject: issue-109
produced_by: implementation
loop_state: proposed
upstream:
  - path: docs/issue-109/reports/implementation/survey.md
    sha: <set at commit>
---

files: `core/contract/role-handoff-contract.md`

## Request

Issue #109: on-the-record #258 / PR #259 amended `on-the-record/commands/run.md`
step 1 so the orchestrator, before drafting an issue, judges per-request
whether any of the user's available skills apply, invokes the applicable
ones through the real `Skill` mechanism (not by reading and paraphrasing
the skill file), and folds each invoked skill's procedural demands into
the issue draft's requirements/acceptance-criteria text — while the skill
call itself produces no artifact and role sessions stay skill-isolated
(no injection). This repo's role-handoff contract has its own
issue-drafting section (§9) and now reads differently from `run.md`.
Update §9 to state the same procedure, citing on-the-record #258/PR #259
as the source decision.

## Constraints

- Contract-only edit. Per the issue's own "out of scope": no change to
  `spawn.py`, no change to any rulebook, no change to which skills exist.
- The contract is repo-general prose describing the coordination model
  across all nine roles — it is not a command script, so the addition
  restates the procedure in the contract's own voice rather than
  reproducing `run.md`'s imperative Korean step text verbatim.
- Skill-isolation ("역할 세션에는 스킬이 주입되지 않는다") must appear
  explicitly — this is the property that keeps the skill-invocation step
  from leaking into role-session behavior, and the issue names it as a
  required part of the alignment, not an implicit consequence.

## Rationale

**Placed inside §9, not as a new top-level section.** §9 (`` `subject` is
the issue ``) is already the contract's only section describing how an
issue comes to exist, and §8 (`the human's seat`) cross-references it for
"filing the issue" (survey). The alternative — a new top-level section
(e.g. "§9a: orchestrator skill evaluation") — was considered and rejected:
it would split one coherent procedure (draft → skill-fold → file) across
two sections for a reader trying to understand "how does an issue get
made," with no offsetting benefit, since nothing else in the contract
needs to reference the new section independently of §9's existing
cross-references (survey's `grep` found zero other issue-drafting
mentions in the file).

**Restated in the contract's voice, not the source's imperative Korean
step text copied verbatim.** The rejected alternative is a literal
transplant of `run.md`'s "스킬 평가 — 이슈 등록 전" paragraph. Rejected
because `run.md` is a command script addressed to an orchestrator session
mid-loop ("이슈 초안을 보여주기 전에…"), while the contract is
third-person descriptive prose read by any of nine role rulebooks and by
humans auditing the coordination model — every other procedure in the
contract (e.g. §19's approval gate, §16's cite-and-skip) is described
this way, not quoted from its enforcing script. Matching the contract's
existing register keeps the new subsection consistent with its
neighbors; the four load-bearing points (per-request judgment, real
`Skill`-tool invocation, fold into requirements, skill-isolation) all
carry over unchanged in content.

## What will be done

Insert a new subsection into `core/contract/role-handoff-contract.md` §9,
after the existing paragraph ending "...V2's derive-and-search minting
rule... is deleted" (current lines 262-278) and before §10, stating:

- Before an issue is drafted, the orchestrator judges per-request whether
  any of the user's available skills apply to that request — a per-task
  judgment call, not a lookup against a fixed skill-to-request mapping.
- A skill judged applicable is invoked through the real `Skill` tool
  mechanism; reading the skill's file as text and paraphrasing it does
  not satisfy this.
- The invoked skill's procedural demands (required steps, evidence
  standards, stop conditions, output shape) are folded into the drafted
  issue's requirements/acceptance-criteria text. The skill invocation
  itself produces no artifact of its own — the issue text is the only
  output that carries forward.
- Role sessions that later work the resulting issue remain
  skill-isolated: no skill is injected into a role session; only the
  issue's own requirements/acceptance-criteria text (already carrying any
  folded-in skill demands) reaches the role.
- Cites on-the-record #258 / PR #259 as the source decision this
  subsection aligns with.

## Out of scope

- `spawn.py`, any of the nine role rulebooks, or which skills exist — per
  the issue's own out-of-scope list.
- Any change to §8 (the human's seat) or any other contract section —
  the new text lives entirely inside §9.
- Re-litigating on-the-record #258/PR #259's own design — this proposal
  restates an already-landed decision, it does not re-derive it.

## How you'll know it worked

- `core/contract/role-handoff-contract.md` §9 contains the four
  load-bearing points (per-request judgment, real `Skill`-tool
  invocation, fold-into-requirements, role-session skill-isolation) and
  cites on-the-record #258/PR #259 by number.
- `grep -c` for the phrase "skill" (case-insensitive) in
  `core/contract/role-handoff-contract.md` goes from 0 to a non-zero
  count confined to the new §9 subsection.
- `git diff` for this change touches only
  `core/contract/role-handoff-contract.md` (plus this proposal/survey
  pair) — no rulebook, no `spawn.py`, no skill file changes.
