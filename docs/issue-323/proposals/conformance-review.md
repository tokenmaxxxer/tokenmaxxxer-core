---
status: proposed
files:
  - docs/issue-323/reports/conformance-review.md
  - docs/issue-323/reports/conformance-review/*.md
---

## Request

Review PR #324 (`issue-323/implementation` -> `main`, the delivered fix for
issue #323's heredoc/ENOSPC exposure in `warrant/hooks/scope-gate.sh`)
against issue #323's four verbatim acceptance checks, and render a
conformance-review record with a verdict and cited evidence for each.

## Constraints

- Record lands only in this role's own area:
  `docs/issue-323/reports/conformance-review.md` (the pre-written skeleton)
  and, if the before-landing warrant-hunter fires, a hunt-record file under
  `docs/issue-323/reports/conformance-review/`. Never edit
  `docs/issue-323/reports/implementation.md` or any `src/`/`warrant/`/
  `core/` code path — this is a docs-only review.
- Verification is verify-at-landing: each acceptance check needs its own
  executed evidence in this role's record (a command and its actual output,
  or a specific file/line/sha citation), not a re-quote of the
  implementation record's own transcript passed through unchecked.
- The live ENOSPC/TMPDIR-exhaustion reproduction (acceptance checks 1 and 2)
  needs a privileged/unshare mount namespace with an exhausted tmpfs —
  environment-mutating, so it happens in phase 2 after approval, not in this
  phase-1 survey turn.
- Where this role cannot independently reproduce a claim, the verdict says
  so explicitly (Unverifiable, or an Analysis-based Present per
  conformance-review-verification-method-selection) rather than silently
  inheriting Present from the implementation record's own say-so.

## Rationale

Considered running the full live ENOSPC before/after reproduction myself
already in this phase-1 turn — the sandbox appears to support the same
`unshare --user --map-root-user --mount` approach the implementation record
used, and doing it now would have let phase 1 close out acceptance checks 1
and 2 immediately. Rejected: constructing a 0-free-inode/0-free-byte tmpfs
and running gate scripts inside it is destructive/environment-mutating
*work*, not *survey* — the role contract's two-phase split exists precisely
to put that class of action behind an explicit human Approve rather than
having a session decide on its own that skipping straight to it is fine.
This phase-1 turn instead did only non-destructive Inspection/Test-reuse
checks (diff inspection, byte-size cross-check, rerunning the existing hook
test suites in a scratch worktree — see the survey) to establish that the
implementation's claims are credible before asking for approval to do the
more expensive part.

Also considered independently re-measuring all 21 (25, by the
implementation's own wider grep) audited heredoc-using scripts byte-for-byte
in this pass, rather than spot-checking one. Rejected: acceptance check 4
asks for a disposition *statement*, not an independent full re-audit of
every script; a single spot-check (`facet-keyword-gate.sh`, see survey)
already tells whether the implementation's audit is fabricated or credible.
Re-measuring all 25 would be diligence disproportionate to a docs-only
disclosure requirement, and the record will state the spot-check's scope
explicitly rather than imply full independent coverage.

## What will be done

Already done this phase-1 turn (see `docs/issue-323/reports/conformance-review/survey.md`
for the full detail and evidence):
- Extracted issue #323's 4 acceptance checks into a dimension-tagged
  requirement list with a verification method picked per requirement
  (conformance-review-requirement-extraction,
  conformance-review-verification-method-selection).
- Inspected the PR #324 diff: confirmed the heredoc is genuinely removed
  from `warrant/hooks/scope-gate.sh` (not just relabeled), and that the
  extracted `warrant/hooks/lib/scope-gate.py` is byte-size-consistent with
  the claimed "byte-for-byte unchanged" body.
- Independently reran `core/hooks/tests/run-scope-gate-tests.sh` (46/46) and
  `core/hooks/tests/run-role-gates-tests.sh` (83/83) against the PR head in
  a scratch worktree — matches the implementation record's claimed counts.
- Spot-checked one of the 21/25 audited scripts' claimed heredoc byte size
  against an independent rough measurement — consistent, no sign of
  fabrication.

On approval (phase 2, same branch, same PR):
- Reproduce the ENOSPC-during-heredoc failure live against the pre-fix
  `scope-gate.sh` under a constrained/exhausted TMPDIR, then confirm the
  fixed version's behavior under the same condition for both the deny and
  allow branches (acceptance checks 1 and 2, before/after).
- Assign a verdict (Present/Surface/Absent/Incorrect/Unverifiable) to each
  of the 4 extracted requirements, with cited evidence
  (conformance-review-verdict-assignment).
- Fill the pre-written skeleton at `docs/issue-323/reports/conformance-review.md`
  (conformance-review-finding-record) with the verdicts, evidence, and this
  record's own required frontmatter/sections per the record-shape directive.
- Dispatch the before-landing warrant-hunter, then commit (with the
  `Proposal:` trailer), push, and update this PR.

## Out of scope

- Fixing any of the 21 (25) other heredoc-using scripts, or filing the
  follow-up issue the implementation record recommends for them — this role
  reviews conformance to issue #323's stated criteria, and per the
  role-handoff contract's own invariants does not self-file new issues.
- Re-litigating the implementation's design choice (heredoc-to-real-file
  extraction, acceptance option (a)) against the alternative the issue also
  allowed (option (b), surfacing ENOSPC distinctly while still failing
  closed) — both are valid acceptance paths per the issue text; this reviews
  conformance to whichever option was actually delivered, not which option
  should have been picked.
- Editing `docs/issue-323/reports/implementation.md` or any code path.

## How you'll know it worked

- `docs/issue-323/reports/conformance-review.md` exists with a verdict for
  each of the 4 extracted requirements, each backed by evidence this role
  produced or cited directly (a command and its output, or a file/line/sha).
- The live before/after ENOSPC demonstration is either independently
  reproduced by this role in phase 2, or its requirement is explicitly
  marked Unverifiable-in-this-environment with the reason stated — never
  silently inherited as Present from the implementation record alone.
- This phase-1 PR references issue #323 as a plain `#323` (no
  Closes/Fixes/Resolves — that trailer is reserved for the phase-2 delivery
  PR per the role contract's PR trailer phase split).
