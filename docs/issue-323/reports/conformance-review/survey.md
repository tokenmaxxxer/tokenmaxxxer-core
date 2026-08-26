---
issue: 323
role: conformance-review
kind: survey
---

# issue-323 — conformance-review current-state survey

## Scout skip

Scouting (best-in-class exemplar sweep) is skipped: this task reviews a
landed fix against issue #323's already-fixed, verbatim acceptance criteria
— there is no open product/design decision to aim external research at, only
a fixed checklist to verify. This is the scout-directive's second mandatory
skip condition ("the spec leaves no design decision open").

## What is under review

- Issue #323 (verbatim acceptance, 4 checks — see below), opened by
  JiwonJung94, one validity-consult comment confirming it.
- PR #324, `issue-323/implementation` -> `main`, head
  `8fb4857a64e84b9d746a61a4b15dd29ab90924c8`, body claims `Closes #323`.
  Delivered record: `docs/issue-323/reports/implementation.md`
  (`loop_state: landed`, `verdict: pass`, `type: fix`).
- The fix: `warrant/hooks/scope-gate.sh`'s PreToolUse payload — previously a
  `WARRANT_PAYLOAD="$payload" python3 <<'PY' ... PY` heredoc — is extracted
  verbatim into a new sibling file `warrant/hooks/lib/scope-gate.py`, loaded
  via `python3 "$SCOPE_GATE_DIR/lib/scope-gate.py"`. Plus an audit of 21
  (25 by the implementation's own wider grep) other heredoc-using hook
  scripts, disposition recorded in the same implementation.md, none fixed
  in this pass.

## Extracted requirements (conformance-review-requirement-extraction)

Issue #323's acceptance section is 4 checks, none bundling independent
"and"-joined obligations that need splitting, none a redundant summary line.
Dimension-tagged, with the verification method selected
(conformance-review-verification-method-selection) and this session's
phase-1 prep work already done against each:

1. **[edge-case]** Reproduce the ENOSPC-during-heredoc condition live
   (constrained TMPDIR, 0 free space/inodes) against `scope-gate.sh`,
   confirm the current confusing failure mode.
   Method: **Demonstration/Analysis** — needs a live, environment-mutating
   reproduction (namespace with an exhausted tmpfs). Not attempted yet in
   this phase-1 turn (see Rationale in the proposal) — phase 2 work.

2. **[edge-case + error-handling]** After the fix, same constrained-TMPDIR
   condition either (a) succeeds with no heredoc temp file, or (b) still
   fails closed but the error names ENOSPC/tempdir distinctly — demonstrate
   live, before/after. **must not**: allow a write through under the
   exhausted condition that the gate would normally refuse.
   Method: **Inspection** for the structural half (does a heredoc still
   exist to depend on a temp file at all?) — done this turn, see below.
   **Demonstration/Analysis** for the live transcript half — phase 2 work,
   same as #1.

3. **[functional-behavior]** Normal-condition (non-exhausted TMPDIR)
   behavior is unchanged — regression check via the existing hook test
   suite.
   Method: **Test** (existing suite, rerun and reused rather than
   re-derived). Done this turn, see below.

4. **[scope-boundary]** State explicitly, for each of the other 21
   heredoc-using hook scripts identified this session, whether it shares
   the same exposure and whether it's fixed in this pass or deferred.
   Method: **Inspection** of the implementation record's disclosure, plus a
   spot-check sample (not a full independent re-audit — see proposal
   Rationale for why full re-measurement of all 25 is out of proportion for
   a docs-only disclosure requirement). Partially done this turn, see below.

## Independent checks already run this phase-1 turn (read-only / non-destructive)

All against `FETCH_HEAD` = `8fb4857a64e84b9d746a61a4b15dd29ab90924c8`
(`origin/issue-323/implementation`), in a scratch `git worktree` removed
afterward — nothing landed on this branch by these checks.

- `git show FETCH_HEAD:warrant/hooks/scope-gate.sh | grep -n '<<'` → only one
  hit, a comment (`# issue-323: the payload logic used to be a
  \`python3 <<'PY' ... PY\` heredoc.`) — the heredoc itself is genuinely gone
  from the script, not just relabeled.
- `git show FETCH_HEAD:warrant/hooks/lib/scope-gate.py | wc -lc` → 501 lines,
  22,941 bytes — matches the implementation record's claimed pre-fix heredoc
  body size (22,941 bytes) exactly, consistent with the "byte-for-byte
  unchanged, only a header comment added" claim.
- Reran, in the scratch worktree at the PR head:
  `bash core/hooks/tests/run-scope-gate-tests.sh` → `46 passed, 0 failed`
  `bash core/hooks/tests/run-role-gates-tests.sh` → `role-gates: 83 passed,
  0 failed`
  Both match the implementation record's claimed counts exactly —
  independent confirmation of acceptance check 3, not a re-quote of the
  record's own transcript.
- Spot-checked one of the 21/25 audited scripts:
  `core/hooks/facet-keyword-gate.sh`'s claimed heredoc size (11,860 bytes) —
  an independent rough `awk` slice from `<<'PY'` to the closing `PY` line
  measured ~11,924 bytes (close enough, given the rough slice includes the
  delimiter lines the record's likely `wc -c`-on-body measurement would
  not) — same order of magnitude, no sign of a fabricated figure.

## Not yet independently verified (flagged for phase 2)

- The live before/after ENOSPC-under-exhausted-TMPDIR transcripts
  (acceptance checks 1 and 2's demonstration half) — the implementation
  record's transcript is plausible (consistent with bash 5.1's documented
  pipe-if-small/tempfile-if-large heredoc behavior, and with what this
  session's own Inspection above already confirmed structurally), but not
  yet reproduced by this role. Reproducing it needs a privileged/unshare
  mount namespace with an exhausted tmpfs — see the proposal's Rationale
  for why that is phase-2 work, not phase-1 survey.
- Full independent byte-measurement of all 21/25 other audited scripts —
  only one was spot-checked; the review will state this as a sampling
  scope, not silently claim full coverage.

skill-verdict: conformance-review-requirement-extraction — applied: invoked;
used to decompose issue #323's 4 acceptance checks into the dimension-tagged
list above.
skill-verdict: conformance-review-verification-method-selection — applied:
invoked; used to pick Inspection/Test/Demonstration-Analysis per requirement
above, and to justify reusing the existing hook test suites (rule 4) rather
than hand-deriving a parallel check.
skill-verdict: conformance-review-sampling-derivation — not-applicable: only
4 top-level requirements and one already-enumerated 21/25-script disclosure
list exist; full enumeration of the 4 acceptance checks is feasible outright,
and the one-script spot-check on the 25-script disclosure is a phase-1
credibility check, not a review-scope sampling derivation.
skill-verdict: conformance-review-verdict-assignment — not-applicable this
turn: rendering a Present/Surface/Absent/Incorrect/Unverifiable verdict is
phase-2 record-writing work, gated by human Approve per the role contract;
phase 1 is survey and proposal only.
skill-verdict: conformance-review-finding-record — not-applicable this turn:
writing docs/issue-323/reports/conformance-review.md is phase-2 output.
skill-verdict: conformance-review-severity-classification — not-applicable:
the review scope was never extended into risk-weighting; issue #323's
acceptance checks are pass/fail, not severity-banded.
skill-verdict: requirements-quality — not-applicable: this reviews an
implementation against an issue's existing acceptance criteria, not the
requirements text itself for EARS/QUS conformance.
skill-verdict: implementation-audit — not-applicable: that skill's two-session
builder/evaluator split is a different protocol from this repo's own
role-handoff contract (conformance-review role), which this session already
follows.
