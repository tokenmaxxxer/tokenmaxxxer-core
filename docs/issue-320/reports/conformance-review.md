---
issue: 320
role: conformance-review
author: conformance-review
loop_state: landed
upstream:
  - path: PR #319 (fix/issue-2286-board-gate-r5-author-identity-v2), commit 500fbce11d3b53dcec9c45e69b46e7d50eecb6df
    sha: 500fbce11d3b53dcec9c45e69b46e7d50eecb6df
subject: PR #319 (branch fix/issue-2286-board-gate-r5-author-identity-v2), commit 500fbce11d3b53dcec9c45e69b46e7d50eecb6df
test: python3 -m pytest core/hooks/test_board_gate.py -q (issue #320's own named Acceptance check)
result: passed
assertedBy: issue-320/conformance-review
---

# issue-320 — conformance-review record

## What was done

Builder-blind conformance review of PR #319 (`board-gate.sh` R5:
foreign-record ownership keyed off a record's own `author:` frontmatter
field instead of the writing session's role-vs-filename match). Reviewed
in a dedicated `git worktree` at PR #319's head
(`500fbce11d3b53dcec9c45e69b46e7d50eecb6df`, not this branch, not the
implementer's own claims): re-ran the named test file, then drove
`board-gate.sh` directly (not through `pytest`) against fresh, disposable
git fixtures — mirroring `test_board_gate.py`'s own `board()`/`run_gate()`
fixture shape — to produce independent live transcripts for each of the
four named R5 behaviors plus the legacy-record backward-compatibility
check, and read `board.py` in `tokenmaxxxer/on-the-record` (the sibling
repo issue #320 names) to cross-check `EXTRA_SUBTREE`'s corrected keys
against its equivalent ownership check. All four Acceptance checks
verdicted below; 7 requirements extracted, all 7 Present. No Absent or
Incorrect findings.

## Why

CORE_BUILD_NOW=1 was set by the spawning environment (build-now bypass,
contract v3 s19a) — the proposal/survey/scout round is skipped by that
bypass, not by this session's own choice; this record is delivered
directly per the bypass instruction. Separately, the scout-directive's
own mandatory skip condition also applies on its merits: issue #320's
Acceptance section is four fixed, already-fully-specified checks against
already-landed code (PR #319, a cherry-pick of a commit already reviewed
twice upstream in `on-the-record`) — there is no open design decision
for a scout pass to steer, only verification of claims already made. Full
enumeration (all 4 Acceptance checks, split into 7 checkable requirements
per rule 1) was used rather than a derived sample, because the population
is 4 fixed bullets, not a corpus large enough to need sampling.

`skill-verdict: conformance-review-requirement-extraction — applied: invoked; split issue #320's Acceptance check 2 ("the four R5 behaviors are each demonstrated") into R-2a/R-2b/R-2c/R-2d as separate line items per rule 1 (bundled "and"-joined obligations), each dimension-tagged per rule 6`
`skill-verdict: conformance-review-verification-method-selection — applied: invoked; Test (reuse of core/hooks/test_board_gate.py, rule 4) for R-1; Demonstration (live board-gate.sh invocations against fresh git fixtures, rule 3) for R-2a/R-2b/R-2c/R-2d and R-4; Inspection (structural file:line comparison) for R-3`
`skill-verdict: conformance-review-verdict-assignment — applied: invoked; confirmed Present rather than Surface for R-2b and R-3 by checking the deny/match actually fires on the exact named condition (author-mismatch text naming the right author; board.py's role strings matching board-gate.sh's dict keys verbatim), not merely that similarly-named code exists somewhere`
`skill-verdict: conformance-review-traceability-and-evidence — applied: invoked; every verdict below cites file:line plus the exact commit/blob sha actually read — core/hooks/board-gate.sh @ PR #319 head 500fbce1, tokenmaxxxer/on-the-record's board.py @ main a53a5cee73c40dfb88c13a3ccc96f6a42c78118c, docs/issue-100/reports/implementation.md @ this repo's origin/main 991e177c3b4772719332af3679955c97dcc92dea`
`skill-verdict: conformance-review-finding-record — applied: invoked; the 7 verdict blocks below use this skill's field list (requirement/spec_ref/verdict/evidence/rationale), written only to this role's own record file (docs/issue-320/reports/conformance-review.md)`
`other mounted skills: conformance-review-sampling-derivation and conformance-review-severity-classification — not triggered; full enumeration of the 4 fixed Acceptance checks was feasible (no sampling decision to derive) and no risk-weighting scope extension was requested (ordinary Present/Absent/Incorrect fidelity-checking only)`

## Open findings

None — all 7 extracted requirements verdicted Present; no Absent, Incorrect,
Surface, or Unverifiable findings.

## Next steps

None. loop_state is terminal (`landed`): all four Acceptance checks are
independently verified live against PR #319's head; nothing further is
pending from this review.

## Upstream basis

Reviewed artifact: PR #319, branch `fix/issue-2286-board-gate-r5-author-identity-v2`,
commit `500fbce11d3b53dcec9c45e69b46e7d50eecb6df` (`core/hooks/board-gate.sh`
+113/-1, `core/hooks/test_board_gate.py` +71/-0), diffed against this
repo's `main` (`991e177c3b4772719332af3679955c97dcc92dea`). Cross-checked
against `tokenmaxxxer/on-the-record`'s `board.py` at `main`
(`a53a5cee73c40dfb88c13a3ccc96f6a42c78118c`). No phase-1 survey/proposal
exists for this record — build-now bypass (see Why).

## Requirement verdicts

<!-- one block per conformance-review-finding-record's field list -->

---
requirement: `python3 -m pytest core/hooks/test_board_gate.py -q` run inside this repo against PR #319's head, command and full output pasted into the record — expected 13 passed (8 pre-existing + 5 new)
spec_ref: issue #320 Acceptance, bullet 1
verdict: Present
evidence: independently re-run from `/tmp/pr319-review` (git worktree of PR #319 head, `500fbce11d3b53dcec9c45e69b46e7d50eecb6df`):

  $ python3 -m pytest core/hooks/test_board_gate.py -q
  /home/jwjung/.local/lib/python3.10/site-packages/pytest_asyncio/plugin.py:208: PytestDeprecationWarning: The configuration option "asyncio_default_fixture_loop_scope" is unset.
  The event loop scope for asynchronous fixtures will default to the fixture caching scope. Future versions of pytest-asyncio will default the loop scope for asynchronous fixtures to function scope. Set the default fixture loop scope explicitly in order to avoid unexpected behavior in the future. Valid fixture loop scopes are: "function", "class", "module", "package", "session"

    warnings.warn(PytestDeprecationWarning(_DEFAULT_FIXTURE_LOOP_SCOPE_UNSET))
  .............                                                            [100%]
  13 passed in 0.99s
rationale: 13 passed, independently re-executed from this review's own worktree checkout rather than trusted from the PR description's self-report; matches the expected 8 pre-existing + 5 new
---

---
requirement: own-author write is allowed — a session whose CLAUDE_ROLE matches the record's `author:` field may truncate/rewrite it
spec_ref: issue #320 Acceptance, bullet 2 (behavior 1 of 4)
verdict: Present
evidence: live transcript, driving `core/hooks/board-gate.sh` directly (PR #319 head) against a fresh `git init` fixture (branch `issue-501/implementation`, `docs/specs/approvers.md` present) — record pre-seeded with `author: implementation` frontmatter, then a truncating `cat >` from `CLAUDE_ROLE=implementation`:

  ### Behavior 1: own-author truncating write ALLOWED
  CLAUDE_ROLE=implementation  command: cat > docs/issue-501/reports/implementation.md <<'EOF' ...
  exit=0

  code path: core/hooks/board-gate.sh:1003 (`if author is not None: if author == role: continue`)
rationale: exit 0 (allow) with no stderr — the gate's `author == role` short-circuit at board-gate.sh:1003-1004 passes the write through before reaching any deny branch
---

---
requirement: foreign-author truncating write is denied — a session whose CLAUDE_ROLE does not match the record's `author:` field may not alter its existing lines
spec_ref: issue #320 Acceptance, bullet 2 (behavior 2 of 4)
verdict: Present
evidence: live transcript, same fixture, record pre-seeded with `author: release-engineering`, then a truncating `cat >` from `CLAUDE_ROLE=implementation`:

  ### Behavior 2: foreign-author truncating write DENIED
  CLAUDE_ROLE=implementation  command: cat > docs/issue-501/reports/implementation.md <<'EOF' ...
  exit=2
  stderr: board-gate: docs/issue-501/reports/implementation.md is authored by 'release-engineering', not 'implementation'. A session may append new content to a foreign-authored record but never alter another author's existing lines. (contract v3 s11, issue-2241 stage 3)

  code path: core/hooks/board-gate.sh:1006-1008 (`_write_is_append_only` returns False for a truncating `cat >`, falls through to `deny(...)`)
rationale: exit 2 (deny), and the deny message names the actual author on record ('release-engineering') and the actual writing role ('implementation') — not a generic "foreign record" message, confirming this is the author-mismatch branch, not the older filename branch
---

---
requirement: foreign-author append is allowed — a session whose CLAUDE_ROLE does not match the record's `author:` field may still add new content without altering existing lines
spec_ref: issue #320 Acceptance, bullet 2 (behavior 3 of 4)
verdict: Present
evidence: live transcript, same fixture continued from behavior 2 (foreign-authored record still on disk), `cat >>` (provable append, per `_bash_append_only`) from `CLAUDE_ROLE=implementation`:

  ### Behavior 3: foreign-author append ALLOWED
  CLAUDE_ROLE=implementation  command: cat >> docs/issue-501/reports/implementation.md <<'EOF' ...
  exit=0

  code path: core/hooks/board-gate.sh:1006 (`_write_is_append_only(existing_text, ...)` True for a bare `>>` redirect → `continue`, never reaches `deny`)
rationale: exit 0 (allow) — same foreign-authored record as behavior 2, only the redirect operator changed (`>>` vs `>`), isolating that `_bash_append_only`'s `>>`-only proof (board-gate.sh:952-970) is what flips the verdict
---

---
requirement: an `author:`-less legacy record falls back to the original role-filename rule, unchanged
spec_ref: issue #320 Acceptance, bullet 2 (behavior 4 of 4) and bullet 4 ("no legacy record becomes unwritable")
verdict: Present
evidence: live transcript using a real pre-`author:` record pulled from this repo's own history — `docs/issue-100/reports/implementation.md` at `origin/main` (`991e177c3b4772719332af3679955c97dcc92dea`), which carries `kind:`/`subject:`/`produced_by:`/`loop_state:`/`upstream:` frontmatter and no `author:` field (predates issue-2241 stage 3). Placed at `docs/issue-501/reports/implementation.md` in a fresh fixture, then two attempts:

  4a — owning role (filename `implementation.md` matches `CLAUDE_ROLE=implementation`), branch `issue-501/implementation`:
  ### Behavior 4a: author:-less legacy record, OWNING role (filename match) still writable
  CLAUDE_ROLE=implementation  command: cat >> docs/issue-501/reports/implementation.md <<'EOF' ...
  exit=0

  4b — foreign role (`CLAUDE_ROLE=release-engineering`, on its OWN branch `issue-501/release-engineering` so R4's branch check does not confound the result):
  ### Behavior 4b (isolated on its own role branch issue-501/release-engineering, no R4 confound)
  CLAUDE_ROLE=release-engineering  branch=issue-501/release-engineering  command: cat >> docs/issue-501/reports/implementation.md <<'EOF' ...
  exit=2
  stderr: board-gate: docs/issue-501/reports/implementation.md belongs to another role. release-engineering writes only release-engineering.md, release-engineering/** and postmortems/** — never a foreign record. (contract v3 s11)

  code path: core/hooks/board-gate.sh:1002-1003 (`author = _record_author(existing_text)` is `None` for this record → the `if author is not None:` block at :1003 is skipped entirely) then :1013-1015 (`tail[0] == owner_file` / `tail[0] == role` / `tail[0] == extra`, the pre-issue-2241 filename rule, unchanged)
rationale: 4a shows the record's real owning role can still write it after the change (nothing became unwritable); 4b shows a non-owning role is still denied by the same pre-existing filename rule the record has always been governed by — together this is the fallback firing, not a coincidental allow/deny
---

---
requirement: `EXTRA_SUBTREE`'s corrected keys (`technical-feasibility`/`release-engineering`) match `board.py`'s equivalent ownership check
spec_ref: issue #320 Acceptance, bullet 3
verdict: Present
evidence: `core/hooks/board-gate.sh:93` (PR #319 head, `500fbce11d3b53dcec9c45e69b46e7d50eecb6df`) — `EXTRA_SUBTREE = {"technical-feasibility": "spikes", "release-engineering": "postmortems"}`; `tokenmaxxxer/on-the-record`'s `board.py:768-770` (`main`, `a53a5cee73c40dfb88c13a3ccc96f6a42c78118c`), function `ownership_report`:

  if role == "technical-feasibility" and rest.startswith("spikes/"):
      continue
  if role == "release-engineering" and rest.startswith("postmortems/"):
      continue

  Also independently observed live: behavior 4b's deny text above names
  the role `release-engineering` and its subtree exception
  (`release-engineering/** and postmortems/**`) verbatim from
  `EXTRA_SUBTREE`, confirming the dict is actually read by the deny path,
  not merely present as dead text.
rationale: both files map the same two role names to the same two subtree names (`technical-feasibility`→`spikes`, `release-engineering`→`postmortems`); the pre-fix `feasibility`/`ops` keys named in the issue do not appear in either file at this state
---

---
requirement: no legacy record becomes unwritable by the change
spec_ref: issue #320 Acceptance, bullet 4
verdict: Present
evidence: see R-2d / behavior 4a above — the real `docs/issue-100/reports/implementation.md` legacy record (`origin/main`, `991e177c3b4772719332af3679955c97dcc92dea`, no `author:` field) remained writable (`exit=0`) by its owning role after being placed under the PR #319 head gate
rationale: same evidence as behavior 4a; recorded as its own requirement per issue #320's Acceptance listing it as a separate bullet from the four-behaviors bullet, per rule 5 (conditional/distinct requirement kept as its own line item even though it shares evidence)
---
