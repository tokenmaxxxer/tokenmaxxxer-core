---
kind: coding-record
subject: issue-49
produced_by: coding
loop_state: done
upstream:
  - path: docs/issue-49/reports/coding/survey.md
    sha: <set at commit>
  - path: docs/issue-49/proposals/strip-wake-vocabulary-readme.md
    sha: <set at commit>
code_under_review: <set at commit>
closed_checks:
  - name: grep-zero-wake-hits-readme
    code_sha: <set at commit>
---

# Coding record — issue-49, phase 2

Approved via issue-level comment `APPROVE issue-49/coding` (single-account
mode), posted 2026-07-30T07:39:32Z on issue #49.

## Why

Issue #46's hunt flagged `README.md:26` ("A role wakes on an issue") as
the last leftover "wakes" occurrence; #46's approved proposal explicitly
scoped README out of that delivery, and #46's own coding record carried
this line forward as a future-proposal candidate. Issue #49's approved
proposal (`docs/issue-49/proposals/strip-wake-vocabulary-readme.md`)
authorizes fixing that one line to match the orchestrator-judgment idiom
already landed in `core/contract/role-handoff-contract.md` (#46, commit
0800649).

## Scope

`README.md` only, per the approved proposal. Wording-only change to line
26; no structural or behavioral change.

## What was done

Reworded `README.md:26` from "A role wakes on an issue, works on branch
`issue-<n>/<role>` ..." to "A role is opened for an issue, works on
branch `issue-<n>/<role>` ...".

Verification: `grep -rni wake README.md` returns zero hits (ran directly,
confirmed after the edit).

## What did not work

(none — single-line wording change, matched proposal exactly)

## Open findings

None. Open-finding resolution path: not applicable — no `finding` block
is open against this record; should verify or review post one later, it
routes `addressed_to: coding` per section 5 and is closed via this
record's next revision.

## Next steps

None on this subject.

## Hunt (warrant-hunter, end of phase 2)

Stance: none dispatched. Change is a single-line, single-file docs
wording edit with a mechanical verification already run successfully; no
code path, no behavior, no composition surface for a warrant-hunter to
probe. Recorded per hunt-cadence requirement even though nothing was
dispatched.

closed_checks:
- name: grep-zero-wake-hits-readme
  code_sha: <set at commit>
