---
kind: build-proposal
subject: issue-128
produced_by: implementation
loop_state: proposed
upstream:
  - path: docs/issue-128/reports/implementation/survey.md
    sha: same-commit
  - path: docs/issue-128/reports/implementation/scout-brief.md
    sha: same-commit
---

files: `core/contract/role-handoff-contract.md`, `core/hooks/record-fields-gate.sh`, `core/hooks/tests/run-role-gates-tests.sh`, `docs/handbooks/role-gates-tests.md`

## Request

Issue #128: `upstream[].sha` (contract §1's common header, cited by every
one of the nine roles' records and proposals) cannot be filled with a real
commit SHA when the cited `path` lands in the *same* commit as the citing
document — the sha does not exist yet at write time. This repo's phase-1
practice bundles survey + proposal into one commit, so this is not rare: it
has recurred three times as an unresolved `sha: <set at commit>` placeholder
(issue #98 Finding 4, issue #114 Finding 2, issue #118 Finding 2), and a
repo-wide sweep finds it still unresolved, today, in at least 16 merged
issue trees. Three things are asked:

1. Decide the canonical same-commit citation, comparing (a) a
   `same-commit` literal, (b) splitting phase 1 into two commits, (c)
   codifying and gate-enforcing a post-commit amend.
2. Codify the decision in the contract's own record-norm text (§1/§12
   family).
3. Judge whether to mechanically reject a leftover placeholder, and if so,
   design the check.

## Constraints

- No retroactive fix to any of the 16+ issues already carrying the
  placeholder (#100 decision's no-retroactive-fix precedent, restated as
  this issue's own constraint).
- `record-fields-gate.sh`'s five existing §20 checks
  (what-was-done/why/upstream-basis/loop_state/open-findings) and the
  existing `coding`/`implementation` `code_under_review` bare-sha check
  (issue #100) are unchanged — only an additive check may be introduced.
- `closed_checks[].code_sha` (§16) and `code_under_review` are a different
  field, already settled by issue #100; this proposal does not reopen them.

## Rationale

**Candidate (a), `sha: same-commit`, chosen.** It is write-time-knowable
(no second actor, no later step), it is exactly the shape issue #100's
Decision 1 already adopted in this repo for the structurally identical
problem — `code_under_review` replaced an unresolvable self-referencing sha
with a value knowable at write time — and the scout brief's reused ADR/CI
precedent independently corroborates "cite by stable symbolic identity, not
a self-referential hash" as the field's own must-be. Unlike
`code_under_review`, `upstream[].sha` is consumed by §12's staleness
comparison (`git log -1` against the recorded sha), which a file list
cannot serve; a literal marker can, because §12 already has a working
precedent for a special-cased sha value — the chain-root exemption
(`upstream: []`, contract lines 466-469) already carves out "nothing to
compare, trivially satisfied," and `same-commit` is the same shape of
exemption for "something to compare, but not yet, because it lands in this
very commit." No mechanical staleness check exists today
(repo-wide `grep -rln staleness --include="*.sh" .` finds none), so nothing
currently depends on `sha:` being a real hash; a future automated
staleness-gate would need to special-case the literal `same-commit` the
same way it would special-case an empty `upstream: []`, which is a bounded,
one-line addition to write once such a gate is ever built, not a live
compatibility break today.

**Candidate (b), rejected: split phase 1 into two commits.** A survey
commit followed by a proposal commit would always have a real sha to cite,
but it requires a session to remember an extra manual step every single
phase-1, forever — the survey found every sampled phase-1 commit in this
repo's history (10 issues checked) bundles survey + proposal into one
commit; adopting (b) would be a first, not a return to prior practice, and
the scouted git literature treats commit-splitting as an occasional
history-cleanup technique, not a standing per-transaction discipline. This
is the same failure-mode class already responsible for 3 recurrences under
(c)'s informal form: a step nothing enforces, that a session must
separately remember.

**Candidate (c), rejected: codify + gate-enforce a post-commit amend.** The
issue's own text already names this "세션 부담 최대" (max session burden),
and the survey's direct evidence agrees: the repo-wide sweep found every
one of 16+ placeholder instances *still* unresolved in the current working
tree, months after landing — the informal version of exactly this
convention has a 0-for-16+ track record. #100's Decision 1 rejected the
structurally identical "resolve at merge time" alternative for the same
reason: this repo grants no role the ability to edit another role's
already-merged record (contract §11), and there is no bot/CI step here that
would perform a backfill — adopting (c) means either inventing that
machinery or relying on session memory, which is the exact mechanism that
already failed three times.

**Mechanize requirement 3: yes, additively, on `record-fields-gate.sh`.**
The issue's own text states the prose→breach(3×)→mechanize bar is already
met. #100's Decision 3 used the same reasoning to reject a handbook-only
note after finding it had already been tried once and not carried forward
(`docs/issue-90/…:379-386` → `docs/issue-94/…:347-353`, "recurrence"); the
survey here finds the identical shape (`docs/issue-118`'s Finding 2 already
naming this as the third recurrence). The rejected alternative — a new,
separate gate script — is passed over for the same one-file, no-copies
reasoning #100 gave; unlike #100, though, the new check cannot simply widen
the existing `RECORDS_RE` path match, because `docs/issue-<n>/proposals/*.md`
carries a different artifact kind (`hypothesis`/`build-proposal`) with
different required fields (contract §2) than a role's own record — folding
proposal writes through the existing what-was-done/why/loop_state checks
would false-positive on every legitimate proposal. The check is therefore a
second, independent, narrowly-scoped function: it matches `sha:` lines
under both `docs/issue-<n>/proposals/*.md` and the existing
`reports/<role>.md` path, and denies only the literal bracket-placeholder
shape (`^<.*>$`) — it does not attempt to allow-list every legal value,
keeping it a one-line-regex addition in the shape #100's Decision 3 used.

**Failure signal.** If `same-commit` turns out to be the wrong choice, the
signal is a future role session either (i) prompting the user with §12's
staleness question against a `same-commit` marker because a
newly-built automated staleness check didn't special-case it, producing
spurious confirmation requests, or (ii) a reader unable to tell, from the
literal `same-commit` alone, which exact version of `path` was read,
because the two files actually landed in *different* commits due to a
session mistake the gate check (requirement 3) failed to catch.

## What will be done

1. `core/contract/role-handoff-contract.md` §1: the `sha:` field
   description gains one sentence — when `path` lands in the same commit as
   the record/proposal citing it, `sha:` is written as the literal
   `same-commit`, never a bracketed placeholder; a later citation of the
   same `path`, once that commit exists in history, uses the real resolved
   sha.
2. `core/contract/role-handoff-contract.md` §12: a new paragraph after the
   existing "Chain-root exemption" paragraph — a **same-commit exemption**:
   an `upstream` entry with `sha: same-commit` is exempt from the git-log
   staleness comparison, the same way a chain-root's `upstream: []` is.
3. `core/hooks/record-fields-gate.sh`: one additive, independently-scoped
   check — a second path match for `docs/issue-[0-9]+/proposals/.*\.md`
   (alongside the existing `reports/<role>.md` match), running a narrow
   check (not the existing five §20 checks) that denies the write if any
   `sha:` line's value matches `^<.*>$`. Existing checks and their path
   scope are unchanged.
4. `core/hooks/tests/run-role-gates-tests.sh`: new case(s) driving
   `record-fields-gate.sh` as a subprocess against both a synthetic
   proposal path and a synthetic record path, asserting refusal on
   `sha: <set at commit>` and pass on `sha: same-commit` and on a real
   7-40-hex-char sha.
5. `docs/handbooks/role-gates-tests.md`: one entry documenting the new
   check, same turn as the gate change.

## Out of scope

- Retroactive fixes to any of the 16+ issues already carrying the
  placeholder — explicit issue constraint.
- `code_under_review` / `closed_checks[].code_sha` — already settled by
  issue #100, untouched here.
- Any merge-time or CI backfill mechanism (the rejected alternative under
  both #100 and this proposal).
- A standing `docs/decisions/` entry — this repo's own precedent
  (issue-106, issue-118) lands a contract-wide record-norm change directly
  in the contract text with the rationale carried in the phase-1 proposal;
  no separate decision document is added.
- Any change to `acknowledged_sha` semantics beyond the new exemption.

## How you'll know it worked

- `bash core/hooks/tests/run-role-gates-tests.sh` passes in full, including
  the new cases, with pre-existing cases unaffected.
- A synthetic write to a `docs/issue-<n>/proposals/*.md` path with
  `sha: <set at commit>` is denied by `record-fields-gate.sh`; the same
  write with `sha: same-commit` or a real hex sha is not.
- `core/contract/role-handoff-contract.md` §1 and §12 state the convention
  and its staleness-rule exemption, each readable without cross-referencing
  this proposal.
- This proposal's own frontmatter (above) already demonstrates the
  convention live: its `upstream[].sha` entries for `survey.md` and
  `scout-brief.md`, which land in this same commit, read `same-commit`, not
  a placeholder.
