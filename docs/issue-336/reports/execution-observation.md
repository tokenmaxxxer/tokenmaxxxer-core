---
issue: 336
role: execution-observation
author: execution-observation
loop_state: landed
upstream:
  - path: core/hooks/board-gate.sh
    sha: fc850d6970af9ef8598d27cbe8d3388e678509c5
  - path: core/hooks/test_board_gate.py
    sha: fc850d6970af9ef8598d27cbe8d3388e678509c5
  - path: docs/issue-336/reports/silent-failure-audit+secure-coding-input-validation-injection-defense-a7be2546.md
    sha: fc850d6970af9ef8598d27cbe8d3388e678509c5
code_under_review:
  - core/hooks/board-gate.sh
type: observation
breaking: "no caller-visible behavior change for any legitimate write, independently confirmed: the full 143/145 run-board-gate-tests.sh, 18/18 test_board_gate.py, 24/25 run-dispatcher-equivalence-tests.sh, 18/18 run-gate-shape-tests.sh, 83/83 run-role-gates-tests.sh, and 4/4 run-gate-prose-coverage-tests.sh suites were re-run live against the merged commit and match the counts the delivering session claimed exactly."
verdict: "pass — all three #336 acceptance bullets re-verified live against the merged fix (fc850d6, PR #337, already merged to main), independently of the delivering session's own record. The #335 non-reproduction claim was also independently re-run and confirmed: both named commands succeed (rc=0) and a genuine write to the same path is still denied (rc=2), identically on patched and unpatched HEAD."
subject: core/hooks/board-gate.sh own_hits extraction regex (issue-336 fix), PR #337
test: live board-gate.sh invocations + full existing test suites, re-executed independently in this record
result: passed
assertedBy: execution-observation
---

# issue-336 — execution-observation record

## What was done

Independently re-verified the already-landed and merged fix for issue-336 (PR #337, merged as commit `fc850d6` on `main`, closing the issue). This session did not modify `core/hooks/board-gate.sh`; it re-ran the acceptance checks from scratch, outside the delivering session's own test harness, to confirm the merged state actually behaves as claimed.

Checked out the merged commit `fc850d6` in an isolated worktree (`git worktree add /tmp/verify-336 fc850d6`) and:

1. Ran `python3 -m pytest core/hooks/test_board_gate.py -q` → `18 passed`, matching the PR's claimed count.
2. Built a fresh git board fixture (`/tmp/verify-336-board`) on branch `issue-336/silent-failure-audit+secure-coding-input-validation-injection-defense-a7be2546` and invoked `core/hooks/board-gate.sh` directly (not through pytest) with the issue's exact three commands:
   - `mkdir -p "docs/issue-336/reports/<role>"` → `rc=0`
   - `git add "docs/issue-336/reports/<role>/x.md"` → `rc=0`
   - `git add docs/issue-336/reports/<role>/` → `rc=0`
3. Re-ran the same `mkdir -p` command against the **unpatched** HEAD of this branch (`71234db`, the commit this execution-observation branch was cut from, before `fc850d6` landed) and confirmed it reproduces the exact reported failure: `rc=2`, `docs/issue-336/reports/silent-failure-audit belongs to another role` — the slug truncated at the first `+`.
4. Confirmed a genuinely foreign record (`docs/issue-336/reports/a-different-skill-combo+another-skill-bbbbbbbb/`) is still denied from the same multi-skill workspace: `rc=2`, `belongs to another role`.
5. Confirmed the path shape outside the pre-existing fixture set (a plain redirect writing the slug's own `.md` file directly, not a directory member) succeeds: `echo 'loop_state: landed' > docs/issue-336/reports/<role>.md` → `rc=0`.
6. Re-ran the full regression suite set live against `fc850d6` and cross-checked failure counts against the unpatched branch tip:
   - `run-board-gate-tests.sh`: `143 passed, 2 failed` on both patched and unpatched HEAD — same two named failures (`feasibility-spikes`, `ops-postmortems`) in both, confirming they are pre-existing and unrelated to this fix.
   - `run-dispatcher-equivalence-tests.sh`: `24 passed, 1 failed` (matches claim).
   - `run-gate-shape-tests.sh`: `18 passed, 0 failed`.
   - `run-role-gates-tests.sh`: `83 passed, 0 failed`.
   - `run-gate-prose-coverage-tests.sh`: `4 passed, 0 failed`.
7. Independently re-ran the #335 investigation the delivering session reported (no code change, non-goal unless shared root): built a second board fixture on branch `issue-2593/architecture-module-boundary-definition+architecture-decomposition-strategy` with a role matching #335's quoted fragment, and ran #335's exact two named commands (`ls docs/issue-100/reports/`, `git log --oneline -1 -- docs/issue-100/reports/coding.md`, individually and joined with `;`) against both the patched (`fc850d6`) and unpatched (`71234db`) `board-gate.sh`. Both returned `rc=0` on both commits — confirming the delivering session's claim that #335's named repro does not reproduce, and that this is unrelated to the #336 fix (identical behavior before and after). A genuine write to the same path from the same unrelated branch was still denied (`rc=2`) on both commits, confirming the fix did not loosen ownership enforcement as a side effect.

One discrepancy noted, not a defect: PR #337's description states "6 new" `test_board_gate.py` cases ("12 pre-existing + 6 new"); counting `def test_` lines in the merged file shows 13 pre-existing + 5 new = 18. The total (18, matching the pytest run) is correct; only the pre-existing/new split in the prose is off by one in each direction.

## Why

Execution-observation's job is to confirm a landed change actually does what its record and PR description claim, independent of the delivering session's own test run — a claim of "143 passed" in a PR body is not itself evidence until someone outside that session's context re-executes it. All three acceptance bullets and the #335 disposition were re-derived from a cold worktree checkout rather than trusted from the record, using a separate probe harness (`/tmp/verify_gate.py`, plain Python driving `board-gate.sh` directly) rather than reusing the delivering session's `test_board_gate.py` fixtures, so the confirmation is not just "the same tests still pass" but "the same live commands, run fresh, behave as claimed."

The regex change itself (`[\w./-]*` → `[\w.+/-]*`) was re-read at `core/hooks/board-gate.sh:638` and confirmed to be a pure character-class superset — no other line in the extraction or the unchanged `tail[0] == role` comparison (verified still present, untouched) was altered.

## What did not work

None — every re-verification matched the delivering session's claims on the first run; the only finding was the cosmetic pre-existing/new test-count discrepancy noted above, not a functional deviation.

## Upstream basis

- `core/hooks/board-gate.sh` @ `fc850d6970af9ef8598d27cbe8d3388e678509c5` — the merged fix.
- `core/hooks/test_board_gate.py` @ `fc850d6970af9ef8598d27cbe8d3388e678509c5` — the 5 new multi-skill regression tests.
- `docs/issue-336/reports/silent-failure-audit+secure-coding-input-validation-injection-defense-a7be2546.md` @ `fc850d6970af9ef8598d27cbe8d3388e678509c5` — the delivering session's own record, cited above for its claims and independently re-checked rather than taken on trust.
- PR #337 (merged, `gh pr list --search 336`).
- tokenmaxxxer-core#335 (open, read for the joint-root question the delivering session was asked to check).

## Open findings

1. The delivering session's PR description miscounts the pre-existing/new split of `test_board_gate.py` test functions (claims 12+6, actual is 13+5) — cosmetic only, total (18) and pytest outcome both correct. No action needed.
2. Carried over from the delivering session's own record, re-confirmed here as still open and out of this record's scope: `board-gate.sh:830`'s `_cross_bm` regex (`^issue-([0-9]+)/([\w-]+)$`) has the same `+`-exclusion gap but silently no-ops (via `re.match` returning `None`) instead of misfiring, so the R4 sidecar/branch cross-check does not run for any multi-skill session. Not reproduced or touched by this observation session; flagged for whoever picks it up next.
3. tokenmaxxxer-core#335 remains open with its root cause unidentified — re-confirmed here (not just re-asserted) that its exact named repro does not reproduce against current `main`. Resolution is out of this issue's scope.

## Next steps

None — `loop_state: landed`. Issue #336 is closed and its fix is merged to `main`; this record's independent re-verification found no discrepancy that would reopen it.

other mounted skills: not triggered — freelunch (no repo/env tool call warranting delegation at this fleet width; this was a single-session verification pass), dataviz, terse (style-only, not a verdict-bearing skill), update-config, keybindings-help, code-review, simplify, fewer-permission-prompts, loop, schedule, claude-api, run, init, security-review: none applicable to a read-only re-verification of an already-merged fix.
skill-verdict: work-in-english — applied: invoked; this record, all git/gh commands, and repo-bound text are in English per the skill despite the spawning directives being in Korean; only the final user-facing chat summary is in Korean.
