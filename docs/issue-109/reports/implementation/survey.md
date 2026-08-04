---
kind: current-state-survey
subject: issue-109
produced_by: implementation
---

# Current-state survey — issue-109

## Source decision (on-the-record #258 / PR #259)

`on-the-record/commands/run.md` step 1 (`/home/jwjung/.tokenmaxxxer/work/on-the-record-issue-258-implementation/on-the-record/commands/run.md:15-29`)
now reads, between "요구사항 → 이슈" and "이슈를 등록하기 전에 분류한다":

> **스킬 평가 — 이슈 등록 전.** 이슈 초안을 보여주기 전에, 그 요청에
> 적용될 사용자 스킬이 있는지 판단한다. 판단은 매 이슈마다 하는 것이지,
> 정해진 매핑표를 찾는 것이 아니다 — 어떤 스킬이 적용되는지는
> 오케스트레이터의 그때그때 판단이다. 적용된다고 판단한 스킬은 반드시
> `Skill` 도구로 **실제로 호출**한다 — 스킬 파일을 텍스트로 읽고
> 패러프레이즈하는 것은 이 절차를 만족하지 않는다. 호출한 스킬이
> 요구하는 절차적 조건(필수 단계, 근거 기준, 중단 조건, 산출물 형식)을
> 이슈 초안의 요구사항/수용 기준 문장으로 접어 넣는다. **스킬 호출이
> 산출물을 만들지는 않는다** — 이슈에 요구사항으로만 반영되고, 실제
> 산출물은 여전히 역할 세션의 몫이다 (역할 세션에는 스킬이 주입되지
> 않는다 — 격리는 그대로 유지된다). 적용될 스킬이 없다고 판단했으면 그
> 판단도 대화에서 한 줄로 말한다 — 침묵 통과는 허용되지 않는다.

Four load-bearing points: (1) per-request orchestrator judgment, not a
fixed skill→request mapping table; (2) invocation is a real `Skill` tool
call — reading and paraphrasing the skill file does not count; (3) the
skill's procedural demands fold into the issue's requirements/acceptance
criteria, not into a separate artifact — the skill call itself produces
nothing; (4) role sessions stay skill-isolated (no skill injection into
the role session).

## This repo's contract text today (issue-drafting section)

`core/contract/role-handoff-contract.md:262-278` (§9, `` `subject` is the
issue ``) is the section that currently describes issue authorship: "the
user files an issue on the target repository — issues are the user's
requirement backlog, and only the user authors them; no role ever files
an issue". `grep -i skill core/contract/role-handoff-contract.md` returns
zero matches — the contract says nothing today about an orchestrator
mediating step, skill evaluation, or skill-isolation between issue
drafting and role sessions. §9 is the only section in the contract that
discusses how an issue comes to exist; there is no separate "orchestrator
loop" section to place this in instead.

§8 (`the human's seat`, lines 238-260) lists "Opening or retiring a
`subject` — filing the issue" as one of the human's reserved judgment
points, cross-referencing §9 — confirms §9, not §8, is the section that
should carry the mechanics of what precedes that filing act.

## Write set this survey projects

- `core/contract/role-handoff-contract.md` — one new subsection inside §9
  describing the skill-evaluation-before-filing procedure, sourced from
  the on-the-record #258/PR #259 text above, phrased in this contract's
  own voice (role-handoff-contract.md is repo-general prose describing
  the coordination model, not a command script with imperative Korean
  step numbers — the wording is adapted, not copy-pasted).

No other file in this repo references issue-drafting mechanics (`grep -rn
"issue.*draft\|gh issue create" core/contract/role-handoff-contract.md`
returns nothing besides §9's own prose), so no second file needs a
matching edit.

## Skip-condition check

Scouting (external best-in-class sweep) does not apply: the issue names
its own source of truth verbatim (on-the-record #258/PR #259's already-
landed text) and the only open decision is where inside this repo's
contract to place the restatement and how closely to mirror the source
wording — a small in-repo drafting choice, not a field with external
exemplars to sweep. Recorded here per the scout directive's mandatory
skip-record requirement.
