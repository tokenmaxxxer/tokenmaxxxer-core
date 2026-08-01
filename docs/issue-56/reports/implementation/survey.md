---
subject: issue-56
role: implementation
loop_state: scope-proposed
---

# Current-state survey — issue #56

## 1. The stale sentence, located exactly

`core/contract/role-handoff-contract.md:755-763` (section 19, "What the gate
blocks, mechanically"), current text:

> A role session's writes to that surface are refused while its
> `issue-<n>/<role>` PR lacks one of the two Approve signals above —
> including while no PR exists at all, which is what makes "open the
> proposal PR first" enforced rather than customary.

`s19`'s companion bullet directly below, "Later entries are unaffected"
(`role-handoff-contract.md:764-769`), is unaffected by this issue: it already
scopes to "a later role-entry on a subject whose PR already carries the
Approve," a different question (re-clearing the gate) from the one this
issue raises (a PR existing at all).

**No separate Korean-language edition exists.** `find . -iname "*contract*"`
returns exactly one file (`core/contract/role-handoff-contract.md`); a
repo-wide search for `*.ko.md` / `*_ko.md` / `*-ko.md` returns nothing. The
contract is single-file, English-only; there is no second edition to check
for drift.

**A second, previously unflagged site carries the identical sentence.**
`core/hooks/approval-gate.sh:7-11` (the gate script's own header comment,
not its executable logic):

> \# Deny-only rule: a role session's write to the EXECUTION SURFACE is
> \# refused while the role's issue-<n>/<role> subject lacks an Approve
> \# signal authored by an account listed in docs/specs/approvers.md —
> \# including while no PR exists at all, which is what makes "open the
> \# proposal PR first" enforced rather than customary.

This is not named in issue #56's acceptance criteria (which cite only
`s19`), but it is a verbatim duplicate of the same false claim, in the one
file whose job is to describe what the code below it actually does. Recorded
here as a candidate second write-site; the proposal decides whether it is in
scope.

## 2. What #53/PR#54 actually changed, and an empirical trace of the single-account no-PR path

PR #54 (`issue-53/coding`, merged 2026-07-30T13:12:18Z, `Closes #53`) touched
`core/contract/role-handoff-contract.md` (s10, s19), `core/hooks/approval-gate.sh`,
`core/hooks/tests/run-approval-gate-tests.sh`, `docs/handbooks/approval-gate-tests.md`.
Its own PR body states, verbatim: **"Leaves s19's 'including while no PR
exists at all' clause untouched (issue #56's own territory)."** — #53's
author already earmarked this exact gap for this issue; it is not a surprise
side effect.

Code trace of `core/hooks/approval-gate.sh` at the current `HEAD`:

- `pr_approved` (lines 253-277): built from `gh pr view <branch> --json
  reviews`. If that call fails — no PR currently open — `pr_out.returncode
  != 0`, `pr_approved` stays `False`, and the comment at lines 278-279 says
  plainly this is "not a denial by itself."
- `comment_approved` (lines 281-292): scans `issue_comments` (fetched once,
  lines 213-215, via `gh issue view --json state,comments`) for an exact
  `APPROVE issue-<n>/<role>` string authored by a listed approver. **Nothing
  in this computation references PR existence.**
- `approved = pr_approved or comment_approved` (line 294).

Empirically: with zero PRs ever on the branch (`pr_approved` unconditionally
`False`) and a standing valid issue comment (`comment_approved` `True`),
`approved` evaluates `True` — an execution-surface write is allowed with no
PR in existence. This is not a hypothetical reading of the code; it is a
named, currently-passing test case: `core/hooks/tests/run-approval-gate-tests.sh:125`,
`run allow issue-comment-approved-no-pr issue-comment-no-pr src/app.py`,
using the `issue-comment-no-pr` stub (`run-approval-gate-tests.sh:47`) which
sets `pr_ok=0` (no PR) alongside a valid issue comment. PR #54's own body
confirms the full matrix (36/36) was passing at merge, including this case.

The header comment at `approval-gate.sh:7-11` (section 1 above) describes
the opposite of what lines 253-294 actually do.

## 3. What actually changes: ordering, and `spawn.py::ensure_pushed`'s role

`ensure_pushed` lives in a separate repository,
`/Users/jk/workspace/10_WORK/tokenmaxxxer/on-the-record/spawn.py:2284-2328`
(also present, same content, under
`/Users/jk/.claude/plugins/data/on-the-record-tokenmaxxxer/`). It is
host-side tooling that runs **after** a role's session ends, not part of
this repo or this contract's own machinery:

- No-op if the role's own session already pushed its commits and the branch
  already has an open PR (`spawn.py:2290`, docstring: "역할이 스스로
  push/PR 에 성공했으면 전부 no-op").
- Otherwise: force-pushes the branch (`spawn.py:2300-2305`), then checks
  `gh pr list --head <branch> --state open --json number --jq length`
  (`spawn.py:2309-2312`); if none is open, runs `gh pr create` with body
  `"Part of #<issue>."` — explicitly **not** `Closes #<issue>`, per the
  comment at `spawn.py:2313-2316` citing a measured incident ("이슈 닫기는
  라운드가 끝났을 때 사람의 행위다").
- The PR this opens still requires a full human merge review; nothing about
  `ensure_pushed` changes the "merge is acceptance" rule in `s19`'s "Phase 2
  — execute" bullet.

`ensure_pushed` is genuinely relevant context (it is why the issue calls
this "moderate, not a hole": a PR eventually exists, and the merge gate is
unconditional either way), but it is **not part of the contract's own
guarantee**. Section 21's closing paragraph states the contract is
deliberately "not dependent on host tooling the spawned agents do not
carry" — `on-the-record` is exactly such host tooling (a separate repo, not
reachable from a role's own branch, per the same boundary #53's survey
already recorded). The contract's own text should not lean on
`ensure_pushed` as the thing that bounds phase-2 work; if it did, the
guarantee would depend on tooling the contract elsewhere disclaims
depending on.

**The concrete behavior change, confirmed:** for a role's later entry (2nd+)
on an already-approved branch, "a PR must exist before the first write"
flips to "the write happens; if the role didn't open its own PR, one
appears after the session ends." This is the case the issue's severity
section already reasons about. There is a second, more consequential case
the issue's "moderate, not a hole" framing does not fully separate out: for
a role's **very first** entry on a subject, nothing in the mechanical gate
requires a PR to have ever existed before an approver posts `APPROVE
issue-<n>/<role>` on the issue — a human could post that comment the moment
the issue is filed, before any research, survey, or proposal PR exists, and
the single-account path alone (section 2 above) would allow phase-2 writes
immediately. The only things stopping that today are human discipline (the
approver choosing to wait for a phase-1 PR before approving) and
`ensure_pushed`'s after-the-fact relay — not a gate precondition.

## 4. `docs/decisions/` precedent for this issue's own requirement #3

`find . -path "*/decisions/*.md"` returns nothing anywhere in this repo:
neither `docs/decisions/` nor any `docs/issue-<n>/decisions/` currently has
an entry. There is no existing file to update in place; whichever bucket is
used, this would be the first.

`docs/issue-53/reports/coding/survey.md`'s own "Unknowns" section already
flagged the same ambiguity this issue's requirement #3 raises: `s21`'s
literal text names the repo-standing bucket, `docs/decisions/<date>-<slug>.md`;
this session's own role-directive prose (system prompt, "Document placement
(doctrine ladder)") instead says `docs/issue-<n>/decisions/`. #53 left the
choice "a phase-2 write-time judgment, not a phase-1 blocker." Issue #56's
own body is explicit: "Record the choice under `docs/decisions/` per `s21`"
— the repo-standing bucket, matching `s21`'s literal text. This survey
follows the issue's own instruction rather than re-opening the ambiguity;
the discrepancy between `s21` and the role-directive prose is itself an
unresolved drift, same shape as this issue, but is a different issue's
territory, not this one's.

## 5. Alternatives' technical feasibility, checked against current code

- **Option 1 (issue's own framing): restore an equivalent precondition —
  require the branch has *ever* had a PR (`gh pr list --head <branch>
  --state all` non-empty).** This is not a drop-in flag flip on existing
  code. `approval-gate.sh` would need a third `gh` call (today it makes two:
  `gh issue view ... --json state,comments` and `gh pr view <branch>
  --json reviews`); `run-approval-gate-tests.sh`'s `stub_gh` (`nopr` /
  `issue-comment-no-pr` stubs, lines 46-47) currently expresses only one
  open/closed dimension (`pr_ok`) and cannot distinguish "no PR has ever
  existed" from "a PR existed and is now merged/closed" — the exact
  distinction Option 1 needs. Implementing it would also change the
  expected result of the *currently passing* `issue-comment-approved-no-pr`
  test (line 125): today it asserts ALLOW for "no PR open, valid comment";
  Option 1 would need to split that single scenario into two ("never
  existed" → deny; "existed, now closed" → allow), which is a real edit to
  a test #54 shipped 2 days ago, not just an addition.
- **Option 2 (issue's own framing): amend the `s19` sentence to retire the
  claim, state why, and name what bounds phase-2 work instead.** Touches
  prose only — `core/contract/role-handoff-contract.md` and, per section 1
  above, `core/hooks/approval-gate.sh`'s header comment. No `approval-gate.sh`
  logic change, no `run-approval-gate-tests.sh` change, no regression risk
  against #54's just-shipped, tested behavior.

## Unknowns, stated plainly

- Whether `on-the-record`'s own docs (`run.md`, `README.md`, `protocol.md` —
  already flagged as out-of-repo by #53's survey) also carry text implying
  a PR must exist before work starts. Not observed from this repo; a
  separate repo's own issue if it does.
- Whether `approval-gate.sh:7-11`'s header comment is this issue's territory
  or a separate one's — treated in this survey as in-scope, since it is the
  identical sentence surfaced by this same research, not a new finding
  requiring its own issue.
